-- Verifica retardo de aprendiz tras un ingreso ya registrado en tab_log_ingresos.
-- Solo efectos: tab_asistencia_aprendiz (+ llamado id_motivo=4 si Tarde).
-- Soft-skip: RETURN FALSE (no tumba el ingreso de portería).
-- Firma alineada a fun_registrar_ingreso_manual(wid_persona, CURRENT_TIMESTAMP).

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

    -- Aprendiz en formación + ficha en ejecución
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

    -- Fuera de horario de formación: no asistencia ni llamado
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
