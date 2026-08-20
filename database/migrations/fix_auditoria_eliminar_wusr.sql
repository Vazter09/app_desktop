-- ===================================================================
-- Migración: fix_auditoria_eliminar_wusr
-- Descripción: Elimina el parámetro wusr de todas las funciones
--              PL/pgSQL cuyas columnas de auditoría ya son manejadas
--              por el trigger fun_act_tabla() + app.usuario.
--              Orden: leaf functions primero, wrappers al final.
-- ===================================================================

-- -------------------------------------------------------
-- 1. fun_upsert_persona_visitante (6 → 5 params)
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fun_upsert_persona_visitante(
    numeric, character varying, numeric, character varying, character varying, character varying
);
CREATE OR REPLACE FUNCTION fun_upsert_persona_visitante(
    wid_persona        tab_personas.id_persona%TYPE,
    wid_tipo_docum     tab_personas.id_tipo_docum%TYPE,
    wid_tipo_persona   tab_personas.id_tipo_persona%TYPE,
    wnom_persona       tab_personas.nom_persona%TYPE,
    wape_persona       tab_personas.ape_persona%TYPE
) RETURNS VOID AS $$
DECLARE
    w_exc_state    TEXT;
    w_exc_msg      TEXT;
    w_exc_detail   TEXT;
    w_exc_hint     TEXT;
BEGIN
    IF wid_persona IS NULL OR wid_persona < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El número de documento no es válido.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wid_tipo_docum IS NULL OR TRIM(wid_tipo_docum) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de documento.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_docum WHERE id_tipo_docum = wid_tipo_docum
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de documento no está registrado en el sistema.',
            'id_tipo_docum=' || wid_tipo_docum
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_persona
        WHERE id_tipo_persona = wid_tipo_persona AND id_tipo_persona <> 99
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de persona no es válido.',
            'id_tipo_persona=' || COALESCE(wid_tipo_persona::TEXT, 'NULL'),
            'Seleccione aprendiz, instructor, visitante u otro tipo habilitado.'
        );
    END IF;

    IF LENGTH(TRIM(wnom_persona)) < 2 OR LENGTH(TRIM(wape_persona)) < 2 THEN
        PERFORM smartcset_raise_validacion(
            'Nombres y apellidos son obligatorios (mínimo 2 caracteres).'
        );
    END IF;

    IF EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        UPDATE tab_personas
        SET id_tipo_docum   = wid_tipo_docum,
            id_tipo_persona = wid_tipo_persona,
            nom_persona     = TRIM(wnom_persona),
            ape_persona     = TRIM(wape_persona)
        WHERE id_persona = wid_persona;
    ELSE
        INSERT INTO tab_personas (
            id_persona, id_tipo_docum, id_tipo_persona,
            nom_persona, ape_persona
        ) VALUES (
            wid_persona, wid_tipo_docum, wid_tipo_persona,
            TRIM(wnom_persona), TRIM(wape_persona)
        );
    END IF;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------
-- 2. fun_insert_log_ingreso (6 → 5 params)
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fun_insert_log_ingreso(
    numeric, numeric, numeric, jsonb, text, character varying
);
CREATE OR REPLACE FUNCTION fun_insert_log_ingreso(
    wid_visitante       tab_log_ingresos.id_visitante%TYPE,
    wid_metodo_aut      tab_log_ingresos.id_metodo_aut%TYPE,
    wid_entrada_centro  tab_log_ingresos.id_entrada_centro%TYPE,
    wval_datos_origen   tab_log_ingresos.val_datos_origen%TYPE,
    wval_observaciones  tab_log_ingresos.val_observaciones%TYPE
) RETURNS INTEGER AS $$
DECLARE
    wid_ingreso    INTEGER;
    wts_ingreso    TIMESTAMP WITHOUT TIME ZONE;
    wid_existente  INTEGER;
    w_exc_state    TEXT;
    w_exc_msg      TEXT;
    w_exc_detail   TEXT;
    w_exc_hint     TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_visitante) THEN
        PERFORM smartcset_raise_no_encontrado(
            'El visitante no está registrado.',
            'id_persona=' || wid_visitante::TEXT
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_metodos_aut WHERE id_metodo_aut = wid_metodo_aut) THEN
        PERFORM smartcset_raise_validacion(
            'El método de autenticación no es válido.',
            'id_metodo_aut=' || wid_metodo_aut::TEXT
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La puerta de ingreso no existe en el catálogo.',
            'id_entrada_centro=' || wid_entrada_centro::TEXT
        );
    END IF;

    wid_existente := fun_buscar_ingreso_abierto(wid_visitante);

    IF wid_existente IS NOT NULL THEN
        PERFORM smartcset_raise_negocio(
            format(
                'Esta persona ya tiene un ingreso activo (ingreso #%s). Registre la salida antes de un nuevo ingreso.',
                wid_existente
            ),
            'id_visitante=' || wid_visitante::TEXT,
            'Use el módulo Registro salida.'
        );
    END IF;

    wts_ingreso := CURRENT_TIMESTAMP;
    wid_ingreso := nextval('seq_log_ingresos');

    INSERT INTO tab_log_ingresos (
        id_ingreso, id_visitante, fec_ingreso, fec_salida,
        id_metodo_aut, id_entrada_centro, val_datos_origen, val_observaciones
    ) VALUES (
        wid_ingreso, wid_visitante, wts_ingreso, wts_ingreso,
        wid_metodo_aut, wid_entrada_centro, wval_datos_origen, wval_observaciones
    );

    RETURN wid_ingreso;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN unique_violation THEN
        PERFORM smartcset_raise_negocio(
            'Esta persona ya tiene un ingreso activo. Registre la salida antes de un nuevo ingreso.',
            NULL,
            'Use el módulo Registro salida.'
        );
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------
-- 3. fun_update_persona_tras_ingreso (2 → 1 param)
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fun_update_persona_tras_ingreso(numeric, character varying);
CREATE OR REPLACE FUNCTION fun_update_persona_tras_ingreso(
    wid_persona tab_personas.id_persona%TYPE
) RETURNS VOID AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    UPDATE tab_personas
    SET fec_ultima_entrada = CURRENT_TIMESTAMP,
        num_visitas        = num_visitas + 1
    WHERE id_persona = wid_persona;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'No se encontró el visitante para actualizar el ingreso.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------
-- 4. fun_update_persona_tras_salida (2 → 1 param)
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fun_update_persona_tras_salida(numeric, character varying);
CREATE OR REPLACE FUNCTION fun_update_persona_tras_salida(
    wid_persona tab_personas.id_persona%TYPE
) RETURNS VOID AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    UPDATE tab_personas
    SET fec_ultima_salida = CURRENT_TIMESTAMP
    WHERE id_persona = wid_persona;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'No se encontró el visitante para actualizar la salida.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------
-- 5. fun_update_log_salida (3 → 2 params)
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fun_update_log_salida(integer, text, character varying);
CREATE OR REPLACE FUNCTION fun_update_log_salida(
    wid_ingreso         tab_log_ingresos.id_ingreso%TYPE,
    wval_observaciones  tab_log_ingresos.val_observaciones%TYPE
) RETURNS INTEGER AS $$
DECLARE
    wts_salida   TIMESTAMP WITHOUT TIME ZONE;
    wts_ingreso  TIMESTAMP WITHOUT TIME ZONE;
    wrows        INTEGER;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    SELECT fec_ingreso
      INTO wts_ingreso
      FROM tab_log_ingresos
     WHERE id_ingreso = wid_ingreso;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'No existe el registro de ingreso indicado.',
            'id_ingreso=' || wid_ingreso::TEXT
        );
    END IF;

    wts_salida := CURRENT_TIMESTAMP;
    IF wts_salida <= wts_ingreso THEN
        wts_salida := wts_ingreso + interval '1 microsecond';
    END IF;

    UPDATE tab_log_ingresos
    SET fec_salida = wts_salida,
        val_observaciones = CASE
            WHEN wval_observaciones IS NOT NULL AND TRIM(wval_observaciones) <> '' THEN
                CASE
                    WHEN val_observaciones IS NULL OR TRIM(val_observaciones) = '' THEN TRIM(wval_observaciones)
                    ELSE TRIM(val_observaciones) || ' | Salida: ' || TRIM(wval_observaciones)
                END
            ELSE val_observaciones
        END
    WHERE id_ingreso = wid_ingreso
      AND fec_salida = fec_ingreso;

    GET DIAGNOSTICS wrows = ROW_COUNT;

    IF wrows = 0 THEN
        IF EXISTS (SELECT 1 FROM tab_log_ingresos WHERE id_ingreso = wid_ingreso) THEN
            PERFORM smartcset_raise_negocio(
                format('La salida del ingreso #%s ya fue registrada.', wid_ingreso),
                NULL,
                'Verifique el listado de salidas del día.'
            );
        ELSE
            PERFORM smartcset_raise_no_encontrado(
                'No existe el registro de ingreso indicado.',
                'id_ingreso=' || wid_ingreso::TEXT
            );
        END IF;
    END IF;

    RETURN wid_ingreso;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------
-- 6. fun_verify_retardo_aprendiz (3 → 2 params)
-- Debe coincidir con functions/porteria/retrasos_comite/
-- fun_verify_retardo_aprendiz.sql (incluye llamado id_motivo=4).
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fun_verify_retardo_aprendiz(NUMERIC, TIME);
DROP FUNCTION IF EXISTS fun_verify_retardo_aprendiz(NUMERIC, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS fun_verify_retardo_aprendiz(
    NUMERIC, TIMESTAMPTZ, VARCHAR
);
DROP FUNCTION IF EXISTS fun_verify_retardo_aprendiz(
    DECIMAL, TIMESTAMPTZ, VARCHAR, DECIMAL, DECIMAL, TEXT
);

CREATE OR REPLACE FUNCTION fun_verify_retardo_aprendiz(
    wid_aprendiz   tab_aprendices.id_aprendiz%TYPE,
    whora_llegada  TIMESTAMPTZ
) RETURNS BOOLEAN AS $$
DECLARE
    wusr                 TEXT;
    wtiempo_gracia       tab_pmtros_grales.val_tiempo_gracia_aprendiz%TYPE;
    wid_ficha            tab_aprendices.id_ficha%TYPE;
    wid_jornada          tab_fichas.id_jornada%TYPE;
    wid_centro           tab_fichas.id_centro%TYPE;
    whora_entrada        TIME;
    whora_salida         TIME;
    whora_limite_gracia  TIME;
    whora_llegada_time   TIME;
    wfecha_asistencia     DATE;
    wminutos_retardo     INT := 0;
    westado              VARCHAR(20);
    wtiene_permiso       BOOLEAN := FALSE;
    wya_llamado_hoy      BOOLEAN := FALSE;
    w_exc_state          TEXT;
    w_exc_msg            TEXT;
    w_exc_detail         TEXT;
    w_exc_hint           TEXT;
    CMOTIVO_RETARDO      CONSTANT SMALLINT := 4;
BEGIN
    wusr := NULLIF(TRIM(current_setting('app.usuario', true)), '');
    IF wusr IS NULL THEN
        RETURN FALSE;
    END IF;

    IF whora_llegada IS NULL THEN
        RETURN FALSE;
    END IF;

    whora_llegada_time := whora_llegada::TIME;
    wfecha_asistencia := (whora_llegada AT TIME ZONE COALESCE(
        NULLIF(current_setting('TIMEZONE', true), ''),
        'America/Bogota'
    ))::DATE;

    SELECT a.id_ficha, f.id_jornada, f.id_centro
      INTO wid_ficha, wid_jornada, wid_centro
      FROM tab_aprendices a
      JOIN tab_fichas f ON f.id_ficha = a.id_ficha
     WHERE a.id_aprendiz = wid_aprendiz
       AND a.ind_etdo_formacion = 1
       AND f.ind_estado = 3;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    SELECT p.val_tiempo_gracia_aprendiz
      INTO wtiempo_gracia
      FROM tab_pmtros_grales p
     WHERE p.id_centro = wid_centro;

    IF wtiempo_gracia IS NULL THEN
        SELECT p.val_tiempo_gracia_aprendiz
          INTO wtiempo_gracia
          FROM tab_pmtros_grales p
         LIMIT 1;
    END IF;

    IF wtiempo_gracia IS NULL THEN
        RETURN FALSE;
    END IF;

    SELECT j.hora_entrada, j.hora_salida
      INTO whora_entrada, whora_salida
      FROM tab_jornadas j
     WHERE j.id_jornada = wid_jornada;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF whora_llegada_time > whora_salida THEN
        RETURN FALSE;
    END IF;

    whora_limite_gracia := whora_entrada
        + (wtiempo_gracia::TEXT || ' minutes')::INTERVAL;

    SELECT EXISTS (
        SELECT 1
          FROM tab_permisos_aprendiz pe
         WHERE pe.id_aprendiz = wid_aprendiz
           AND wfecha_asistencia BETWEEN pe.fec_inicio_permiso AND pe.fec_final_permiso
    ) INTO wtiene_permiso;

    IF whora_llegada_time <= whora_limite_gracia THEN
        westado := 'Presente';
        wminutos_retardo := 0;
    ELSIF wtiene_permiso THEN
        westado := 'Presente';
        wminutos_retardo := 0;
    ELSE
        westado := 'Tarde';
        wminutos_retardo := GREATEST(
            0,
            FLOOR(EXTRACT(EPOCH FROM (whora_llegada_time - whora_limite_gracia)) / 60)::INT
        );
    END IF;

    INSERT INTO tab_asistencia_aprendiz (
        id_aprendiz,
        fec_asistencia,
        hora_asistencia,
        minutos_retraso,
        ind_estado,
        usr_insert,
        fec_insert
    ) VALUES (
        wid_aprendiz,
        wfecha_asistencia,
        whora_llegada_time,
        wminutos_retardo,
        westado,
        wusr,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (id_aprendiz, fec_asistencia) DO UPDATE
    SET hora_asistencia  = EXCLUDED.hora_asistencia,
        minutos_retraso  = EXCLUDED.minutos_retraso,
        ind_estado       = EXCLUDED.ind_estado,
        usr_update       = wusr,
        fec_update       = CURRENT_TIMESTAMP;

    IF westado = 'Tarde' AND wminutos_retardo > 0 THEN
        SELECT EXISTS (
            SELECT 1
              FROM tab_llamados_atencion la
             WHERE la.id_tercero = wid_aprendiz
               AND la.ind_tipo_tercero = TRUE
               AND la.id_motivo = CMOTIVO_RETARDO
               AND la.fec_llamado = wfecha_asistencia
        ) INTO wya_llamado_hoy;

        IF NOT wya_llamado_hoy THEN
            INSERT INTO tab_llamados_atencion (
                ind_tipo,
                fec_llamado,
                id_tercero,
                ind_tipo_tercero,
                id_motivo,
                usr_insert,
                fec_insert
            ) VALUES (
                FALSE,
                wfecha_asistencia,
                wid_aprendiz,
                TRUE,
                CMOTIVO_RETARDO,
                wusr,
                CURRENT_TIMESTAMP
            );
        END IF;
    END IF;

    RETURN TRUE;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------
-- 7. fun_upsert_tab_entradas_centro (5 → 4 params)
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fun_upsert_tab_entradas_centro(
    numeric, character varying, numeric, numeric, character varying
);
CREATE OR REPLACE FUNCTION fun_upsert_tab_entradas_centro(
    wid_entrada_centro  tab_entradas_centro.id_entrada_centro%TYPE,
    wnom_entrada_centro tab_entradas_centro.nom_entrada_centro%TYPE,
    wid_centro          tab_entradas_centro.id_centro%TYPE,
    wid_sede            tab_entradas_centro.id_sede%TYPE
) RETURNS TEXT AS $$
DECLARE
    v_nom        VARCHAR(50);
    v_len        INTEGER;
    v_id         tab_entradas_centro.id_entrada_centro%TYPE;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    v_nom := UPPER(TRIM(wnom_entrada_centro));
    v_len := LENGTH(v_nom);
    IF v_len < 5 OR v_len > 50 THEN
        PERFORM smartcset_raise_validacion(
            format('El nombre de la entrada debe tener entre 5 y 50 caracteres (actual: %s).', v_len)
        );
    END IF;

    IF wid_centro IS NULL OR wid_sede IS NULL THEN
        PERFORM smartcset_raise_validacion('Seleccione la sede donde queda la entrada.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_sedes
        WHERE id_centro = wid_centro AND id_sede = wid_sede
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La sede seleccionada no existe en el sistema.',
            format('id_centro=%s id_sede=%s', wid_centro, wid_sede)
        );
    END IF;

    IF wid_entrada_centro IS NOT NULL
       AND EXISTS (
           SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro
       )
    THEN
        IF wid_entrada_centro < 1 OR wid_entrada_centro > 9 THEN
            PERFORM smartcset_raise_validacion('El código de entrada no es válido.');
        END IF;

        v_id := wid_entrada_centro;

        UPDATE tab_entradas_centro
        SET nom_entrada_centro = v_nom,
            id_centro          = wid_centro,
            id_sede            = wid_sede
        WHERE id_entrada_centro = v_id;
    ELSE
        IF wid_entrada_centro IS NOT NULL THEN
            IF wid_entrada_centro < 1 OR wid_entrada_centro > 9 THEN
                PERFORM smartcset_raise_validacion('El código de entrada debe ser un número entre 1 y 9.');
            END IF;
            IF EXISTS (
                SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro
            ) THEN
                PERFORM smartcset_raise_negocio(
                    format('El código de entrada %s ya está en uso.', wid_entrada_centro),
                    NULL,
                    'Edite la entrada existente o deje que el sistema asigne el código.'
                );
            END IF;
            v_id := wid_entrada_centro;
        ELSE
            SELECT MIN(s.codigo)::DECIMAL(1, 0)
              INTO v_id
              FROM generate_series(1, 9) AS s(codigo)
             WHERE NOT EXISTS (
                 SELECT 1
                   FROM tab_entradas_centro e
                  WHERE e.id_entrada_centro = s.codigo
             );

            IF v_id IS NULL THEN
                PERFORM smartcset_raise_negocio(
                    'Ya están registradas las 9 entradas permitidas en el sistema.',
                    NULL,
                    'Elimine una entrada existente para poder crear otra.'
                );
            END IF;
        END IF;

        INSERT INTO tab_entradas_centro (
            id_entrada_centro, nom_entrada_centro, id_centro, id_sede
        ) VALUES (
            v_id, v_nom, wid_centro, wid_sede
        );
    END IF;

    RETURN v_id::TEXT;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------
-- 8. fun_update_tab_config_sistema (29 → 28 params)
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fun_update_tab_config_sistema(
    boolean, boolean,
    character varying, character varying, character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, character varying, character varying, character varying,
    character varying, character varying, character varying
);
CREATE OR REPLACE FUNCTION fun_update_tab_config_sistema(
    wind_modulo_registro           BOOLEAN,
    wind_login_registro_standalone BOOLEAN,
    wnom_sistema                   VARCHAR,
    wpath_logo                     VARCHAR,
    wcolor_primario                VARCHAR,
    wcolor_secundario              VARCHAR,
    wtheme_bg_deep                 VARCHAR,
    wtheme_bg_card                 VARCHAR,
    wtheme_bg_panel                VARCHAR,
    wtheme_accent                  VARCHAR,
    wtheme_accent_dim              VARCHAR,
    wtheme_blue                    VARCHAR,
    wtheme_purple                  VARCHAR,
    wtheme_orange                  VARCHAR,
    wtheme_text_primary            VARCHAR,
    wtheme_text_muted              VARCHAR,
    wtheme_border                  VARCHAR,
    wtheme_error                   VARCHAR,
    wtheme_success                 VARCHAR,
    wtheme_font_display            VARCHAR,
    wtheme_font_body               VARCHAR,
    wtheme_light_bg_deep           VARCHAR,
    wtheme_light_bg_card           VARCHAR,
    wtheme_light_accent            VARCHAR,
    wtheme_light_text_primary      VARCHAR,
    wtheme_light_text_muted        VARCHAR,
    wusr_registro                  VARCHAR,
    wpass_registro_hash            VARCHAR
) RETURNS TEXT AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wcolor_primario !~ '^#[0-9A-Fa-f]{6}$' OR wcolor_secundario !~ '^#[0-9A-Fa-f]{6}$' THEN
        PERFORM smartcset_raise_validacion('Los colores primario y secundario deben ser hex de 6 dígitos (#RRGGBB).');
    END IF;

    IF LENGTH(TRIM(wnom_sistema)) < 2 THEN
        PERFORM smartcset_raise_validacion('El nombre del sistema es obligatorio.');
    END IF;

    UPDATE tab_config_sistema
    SET ind_modulo_registro           = wind_modulo_registro,
        ind_login_registro_standalone = wind_login_registro_standalone,
        nom_sistema                   = TRIM(wnom_sistema),
        path_logo                     = TRIM(wpath_logo),
        color_primario                = wcolor_primario,
        color_secundario              = wcolor_secundario,
        theme_bg_deep                 = wtheme_bg_deep,
        theme_bg_card                 = wtheme_bg_card,
        theme_bg_panel                = wtheme_bg_panel,
        theme_accent                  = wtheme_accent,
        theme_accent_dim              = wtheme_accent_dim,
        theme_blue                    = wtheme_blue,
        theme_purple                  = wtheme_purple,
        theme_orange                  = wtheme_orange,
        theme_text_primary            = wtheme_text_primary,
        theme_text_muted              = wtheme_text_muted,
        theme_border                  = wtheme_border,
        theme_error                   = wtheme_error,
        theme_success                 = wtheme_success,
        theme_font_display            = TRIM(wtheme_font_display),
        theme_font_body               = TRIM(wtheme_font_body),
        theme_light_bg_deep           = wtheme_light_bg_deep,
        theme_light_bg_card           = wtheme_light_bg_card,
        theme_light_accent            = wtheme_light_accent,
        theme_light_text_primary      = wtheme_light_text_primary,
        theme_light_text_muted        = wtheme_light_text_muted,
        usr_registro                  = NULLIF(TRIM(wusr_registro), ''),
        pass_registro_hash            = CASE
            WHEN wpass_registro_hash IS NULL OR TRIM(wpass_registro_hash) = '' THEN pass_registro_hash
            ELSE wpass_registro_hash
        END
    WHERE id_config = 1;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado('No existe configuración del sistema (id_config=1).');
    END IF;

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------
-- 9. fun_registrar_ingreso_manual (10 → 9 params)
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fun_registrar_ingreso_manual(
    numeric, character varying, numeric, character varying, character varying,
    numeric, text, character varying, numeric, boolean
);
CREATE OR REPLACE FUNCTION fun_registrar_ingreso_manual(
    wid_persona        tab_personas.id_persona%TYPE,
    wid_tipo_docum     tab_personas.id_tipo_docum%TYPE,
    wid_tipo_persona   tab_personas.id_tipo_persona%TYPE,
    wnom_persona       tab_personas.nom_persona%TYPE,
    wape_persona       tab_personas.ape_persona%TYPE,
    wid_entrada_centro tab_log_ingresos.id_entrada_centro%TYPE,
    wval_observaciones tab_log_ingresos.val_observaciones%TYPE,
    wid_metodo_aut     tab_log_ingresos.id_metodo_aut%TYPE DEFAULT 1,
    wcaptura_pdf417    BOOLEAN DEFAULT FALSE
) RETURNS INTEGER AS $$
DECLARE
    wid_ingreso    INTEGER;
    wjson_origen   JSONB;
    worigen_txt    TEXT;
    w_exc_state    TEXT;
    w_exc_msg      TEXT;
    w_exc_detail   TEXT;
    w_exc_hint     TEXT;
BEGIN
    IF wid_metodo_aut IS NULL OR wid_metodo_aut < 1 THEN
        wid_metodo_aut := 1;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_metodos_aut WHERE id_metodo_aut = wid_metodo_aut) THEN
        PERFORM smartcset_raise_validacion(
            'El método de autenticación no es válido.',
            'id_metodo_aut=' || wid_metodo_aut::TEXT
        );
    END IF;

    worigen_txt := CASE
        WHEN wid_metodo_aut = 3 THEN 'codigo_barras'
        WHEN wid_metodo_aut = 2 THEN 'codigo_qr'
        ELSE 'registro_manual'
    END;

    IF wid_entrada_centro IS NULL OR wid_entrada_centro < 1 OR wid_entrada_centro > 9 THEN
        PERFORM smartcset_raise_validacion(
            'La puerta de ingreso debe estar entre 1 y 9.',
            'id_entrada_centro=' || COALESCE(wid_entrada_centro::TEXT, 'NULL')
        );
    END IF;

    PERFORM fun_upsert_persona_visitante(
        wid_persona, wid_tipo_docum, wid_tipo_persona, wnom_persona, wape_persona
    );

    wjson_origen := jsonb_build_object(
        'origen', worigen_txt,
        'documento', wid_persona::TEXT,
        'tipo_doc', wid_tipo_docum,
        'tipo_persona', wid_tipo_persona
    );

    IF COALESCE(wcaptura_pdf417, FALSE) THEN
        wjson_origen := wjson_origen || jsonb_build_object('captura_pdf417', TRUE);
    END IF;

    wid_ingreso := fun_insert_log_ingreso(
        wid_persona,
        wid_metodo_aut,
        wid_entrada_centro,
        wjson_origen,
        NULLIF(TRIM(wval_observaciones), '')
    );

    PERFORM fun_update_persona_tras_ingreso(wid_persona);

    IF wid_tipo_persona = 2 THEN
        PERFORM fun_verify_retardo_aprendiz(wid_persona, CURRENT_TIMESTAMP);
    END IF;

    RETURN wid_ingreso;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------
-- 10. fun_registrar_salida_manual (4 → 3 params)
-- -------------------------------------------------------
DROP FUNCTION IF EXISTS fun_registrar_salida_manual(
    numeric, character varying, text, character varying
);
CREATE OR REPLACE FUNCTION fun_registrar_salida_manual(
    wid_persona        tab_personas.id_persona%TYPE,
    wid_tipo_docum     tab_personas.id_tipo_docum%TYPE,
    wval_observaciones tab_log_ingresos.val_observaciones%TYPE
) RETURNS INTEGER AS $$
DECLARE
    wid_ingreso  INTEGER;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_persona IS NULL OR wid_persona < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El número de documento no es válido.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wid_tipo_docum IS NULL OR TRIM(wid_tipo_docum) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de documento.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_personas WHERE id_persona = wid_persona
    ) THEN
        PERFORM smartcset_raise_no_encontrado(
            'No hay visitante registrado con ese documento.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;

    wid_ingreso := fun_buscar_ingreso_abierto(wid_persona);

    IF wid_ingreso IS NULL THEN
        PERFORM smartcset_raise_negocio(
            'No tiene un ingreso activo para registrar salida.',
            'id_persona=' || wid_persona::TEXT,
            'Registre primero el ingreso o verifique documento y tipo.'
        );
    END IF;

    wid_ingreso := fun_update_log_salida(
        wid_ingreso,
        NULLIF(TRIM(wval_observaciones), '')
    );

    PERFORM fun_update_persona_tras_salida(wid_persona);

    RETURN wid_ingreso;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;
