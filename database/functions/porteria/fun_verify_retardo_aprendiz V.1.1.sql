CREATE OR REPLACE FUNCTION fun_verify_retardo_aprendiz(
    wid_aprendiz   tab_aprendices.id_aprendiz%TYPE,
    whora_llegada  TIMESTAMPTZ,                    
    wusr_insert    VARCHAR(50)                      
) RETURNS BOOLEAN AS
$$
DECLARE
    wreg_pmtros       RECORD;
    wreg_trabajo      RECORD;
    wreg_jornadas     RECORD;
    wminutos_retardo  INT := 0;
    wind_estado       VARCHAR;
    whora_limite_gracia TIME;
    wtiene_permiso    BOOLEAN := FALSE;
    wnum_llamados_actual SMALLINT;
    whora_llegada_time TIME;
BEGIN
    -- Extraer solo la hora (sin zona) para comparar con columnas TIME
    whora_llegada_time := whora_llegada::TIME;

    -- 1. Obtener parámetros generales
    SELECT val_tiempo_gracia_aprendiz, val_max_llamados_aprendiz
      INTO wreg_pmtros
      FROM tab_pmtros_grales
     LIMIT 1;

    IF NOT FOUND THEN
        RAISE NOTICE 'No hay datos en parámetros generales. Consulte con el administrador.';
        RETURN FALSE;
    END IF;

    -- 2. Validar aprendiz activo (ind_etdo_formacion = 1) y ficha en ejecución (ind_estado = 3)
    SELECT a.id_ficha, b.id_jornada
      INTO wreg_trabajo
      FROM tab_aprendices a
      JOIN tab_fichas b ON a.id_ficha = b.id_ficha
     WHERE a.id_aprendiz = wid_aprendiz
       AND a.ind_etdo_formacion = 1
       AND b.ind_estado = 3;

    IF NOT FOUND THEN
        RAISE NOTICE 'El aprendiz % no está activo o su ficha no está en ejecución.', wid_aprendiz;
        RETURN FALSE;
    END IF;

    -- 3. Obtener jornada
    SELECT hora_entrada, hora_salida
      INTO wreg_jornadas
      FROM tab_jornadas
     WHERE id_jornada = wreg_trabajo.id_jornada;

    IF NOT FOUND THEN
        RAISE NOTICE 'No se encontró la jornada asociada. Consulte con el administrador.';
        RETURN FALSE;
    END IF;

    -- 4. Si llegada > hora_salida → no registrar (dejar para CRON)
    IF whora_llegada_time > wreg_jornadas.hora_salida THEN
        RETURN FALSE;
    END IF;

    -- 5. Calcular límite de gracia
    whora_limite_gracia := wreg_jornadas.hora_entrada +
                           (wreg_pmtros.val_tiempo_gracia_aprendiz || ' minutes')::INTERVAL;

    -- 6. Determinar estado y retardo
    IF whora_llegada_time <= whora_limite_gracia THEN
        wind_estado      := 'Presente';
        wminutos_retardo := 0;
    ELSE
        -- Verificar permiso activo para el aprendiz
        SELECT EXISTS (
            SELECT 1
              FROM tab_permisos_aprendiz
             WHERE id_aprendiz = wid_aprendiz
               AND CURRENT_DATE BETWEEN fec_inicio_permiso AND fec_final_permiso
        ) INTO wtiene_permiso;

        IF wtiene_permiso THEN
            wind_estado      := 'Presente';
            wminutos_retardo := 0;
        ELSE
            wind_estado      := 'Tarde';
            wminutos_retardo := EXTRACT(EPOCH FROM (whora_llegada_time - wreg_jornadas.hora_entrada)) / 60;

            -- Incrementar llamados
            UPDATE tab_aprendices
               SET num_llamados = num_llamados + 1
             WHERE id_aprendiz = wid_aprendiz;

            -- Obtener nuevo valor y verificar límite
            SELECT num_llamados
              INTO wnum_llamados_actual
              FROM tab_aprendices
             WHERE id_aprendiz = wid_aprendiz;

            IF wnum_llamados_actual >= wreg_pmtros.val_max_llamados_aprendiz THEN
                RAISE NOTICE 'Aprendiz % será citado a comité (llamados acumulados: %).',
                             wid_aprendiz, wnum_llamados_actual;
            END IF;
        END IF;
    END IF;

    -- 7. Insertar o actualizar asistencia (guardamos el TIMESTAMPTZ completo en hora_asistencia)
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
        CURRENT_DATE,
        whora_llegada,               
        wminutos_retardo,
        wind_estado,
        wusr_insert,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (id_aprendiz, fec_asistencia) DO UPDATE
    SET hora_asistencia  = EXCLUDED.hora_asistencia,
        minutos_retraso  = EXCLUDED.minutos_retraso,
        ind_estado       = EXCLUDED.ind_estado,
        usr_update       = wusr_insert,
        fec_update       = CURRENT_TIMESTAMP;

    RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Excepción al procesar asistencia del aprendiz %. ERROR: % - ESTADO: %',
                      wid_aprendiz, SQLERRM, SQLSTATE;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;