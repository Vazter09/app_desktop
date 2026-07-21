-- Registra un ingreso en tab_log_ingresos. Retorna el id_ingreso generado.
-- Opcional: wfacial_embedding / whuella_template (auditoría del evento).
DROP FUNCTION IF EXISTS fun_insert_log_ingreso(
    tab_log_ingresos.id_visitante%TYPE,
    tab_log_ingresos.id_metodo_aut%TYPE,
    tab_log_ingresos.id_entrada_centro%TYPE,
    tab_log_ingresos.val_datos_origen%TYPE,
    tab_log_ingresos.val_observaciones%TYPE
);
-- Firma legacy en servidores sin val_datos_origen (4 args TEXT)
DROP FUNCTION IF EXISTS fun_insert_log_ingreso(
    NUMERIC, NUMERIC, NUMERIC, TEXT
);
DROP FUNCTION IF EXISTS fun_insert_log_ingreso(
    NUMERIC, NUMERIC, NUMERIC, JSONB, TEXT
);
DROP FUNCTION IF EXISTS fun_insert_log_ingreso(
    NUMERIC, NUMERIC, NUMERIC, JSONB, TEXT, VECTOR
);
DROP FUNCTION IF EXISTS fun_insert_log_ingreso(
    NUMERIC, NUMERIC, NUMERIC, JSONB, TEXT, VECTOR, BYTEA
);

CREATE OR REPLACE FUNCTION fun_insert_log_ingreso(
    wid_visitante       tab_log_ingresos.id_visitante%TYPE,
    wid_metodo_aut      tab_log_ingresos.id_metodo_aut%TYPE,
    wid_entrada_centro  tab_log_ingresos.id_entrada_centro%TYPE,
    wval_datos_origen   tab_log_ingresos.val_datos_origen%TYPE,
    wval_observaciones  tab_log_ingresos.val_observaciones%TYPE,
    wfacial_embedding   tab_log_ingresos.facial_embedding%TYPE DEFAULT NULL,
    whuella_template    tab_log_ingresos.huella_template%TYPE DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    wid_ingreso         INTEGER;
    wts_ingreso         TIMESTAMP WITHOUT TIME ZONE;
    wid_existente       INTEGER;
    wts_ultima_salida   TIMESTAMP WITHOUT TIME ZONE;
    wseg_desde_salida   NUMERIC;
    w_exc_state         TEXT;
    w_exc_msg           TEXT;
    w_exc_detail        TEXT;
    w_exc_hint          TEXT;
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

    -- Mínimo 5 minutos entre la última salida cerrada y un nuevo ingreso.
    SELECT l.fec_salida
      INTO wts_ultima_salida
      FROM tab_log_ingresos l
     WHERE l.id_visitante = wid_visitante
       AND l.fec_salida > l.fec_ingreso
     ORDER BY l.fec_salida DESC
     LIMIT 1;

    IF wts_ultima_salida IS NOT NULL THEN
        wseg_desde_salida := EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - wts_ultima_salida));
        IF wseg_desde_salida < 300 THEN
            PERFORM smartcset_raise_negocio(
                format(
                    'Debe esperar al menos 5 minutos desde la última salida (%s) para registrar un nuevo ingreso. Tiempo transcurrido: %s min.',
                    to_char(wts_ultima_salida, 'HH24:MI:SS'),
                    ROUND(wseg_desde_salida / 60.0, 1)::TEXT
                ),
                'id_visitante=' || wid_visitante::TEXT,
                'Espere a completar el tiempo mínimo e intente de nuevo.'
            );
        END IF;
    END IF;

    wts_ingreso := CURRENT_TIMESTAMP;
    wid_ingreso := nextval('seq_log_ingresos');

    INSERT INTO tab_log_ingresos (
        id_ingreso, id_visitante, fec_ingreso, fec_salida,
        id_metodo_aut, id_entrada_centro, val_datos_origen, val_observaciones,
        facial_embedding, huella_template
    ) VALUES (
        wid_ingreso, wid_visitante, wts_ingreso, wts_ingreso,
        wid_metodo_aut, wid_entrada_centro, wval_datos_origen, wval_observaciones,
        wfacial_embedding, whuella_template
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
