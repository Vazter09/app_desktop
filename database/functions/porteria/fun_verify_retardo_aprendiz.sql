CREATE OR REPLACE FUNCTION fun_verify_retardo_aprendiz(wid_aprendiz tab_aprendices.id_aprendiz%TYPE,
                                                       whora_llegada tab_pmtros_grales.hora_entrada_jornada_m%TYPE) RETURNS BOOLEAN AS
$$
    DECLARE wreg_pmtros   RECORD;
            wreg_trabajo  RECORD;
            wreg_jornadas RECORD;
            wminutos_retardo INT := 0;
            wind_estado tab_asistencia_aprendiz.ind_estado%TYPE;
            whora_limite_gracia TIME;
            wtiene_permiso BOOLEAN := FALSE;
    BEGIN
        -- Extracción de parámetros
        SELECT val_tiempo_gracia_aprendiz, val_max_llamados_aprendiz INTO wreg_pmtros 
        FROM tab_pmtros_grales LIMIT 1;
        IF NOT FOUND THEN
            RAISE NOTICE 'No hay datos en parámetros. Consulte con el administrador';
            RETURN FALSE;
        END IF;
-- Validación de aprendiz activo y ficha en ejecución
        SELECT a.id_ficha, b.id_jornada INTO wreg_trabajo FROM tab_aprendices a, tab_fichas b
        JOIN tab_fichas b ON b.id_ficha = a.id_ficha
        WHERE a.id_aprendiz        = wid_aprendiz AND
              a.ind_etdo_formacion = 3            AND
              b.ind_estado         = 1;
        IF NOT FOUND THEN
            RAISE NOTICE 'El visitante no es un aprendiz activo o la ficha no está en ejecución';
            RETURN FALSE;
        END IF;
-- Extracción de la jornada del aprendiz
        SELECT hora_entrada, hora_salida INTO wreg_jornadas FROM tab_jornadas
        WHERE id_jornada = wreg_trabajo.id_jornada;
        IF NOT FOUND THEN
            RAISE NOTICE 'No hay jornadas creadas. Consulte con el administrador';
            RETURN FALSE;
        END IF;
        IF whora_llegada BETWEEN wreg_jornadas.hora_entrada AND wreg_jornadas.hora_salida THEN
            whora_limite_gracia := wreg_jornadas.hora_entrada + (wreg_pmtros.val_tiempo_gracia_aprendiz || ' minutes')::INTERVAL;
            IF whora_llegada > whora_limite_gracia THEN
-- Verificar si existe un permiso válido para hoy
                SELECT EXISTS (SELECT 1 FROM tab_permisos_aprendiz 
                WHERE CURRENT_DATE BETWEEN fec_inicio_permiso AND fec_final_permiso) INTO wtiene_permiso;
                IF wtiene_permiso THEN
                    wind_estado      := 'Presente';
                    wminutos_retardo := 0;
                ELSE
                    wind_estado      := 'Tarde';
                    wminutos_retardo := EXTRACT(EPOCH FROM (whora_llegada - wreg_jornadas.hora_entrada)) / 60;
                END IF;
            ELSE
                wind_estado      := 'Presente';
                wminutos_retardo := 0;
            END IF;
            INSERT INTO tab_asistencia_aprendiz (id_aprendiz, fec_asistencia, hora_llegada, minutos_retardo, ind_estado) 
            VALUES (wid_aprendiz, CURRENT_DATE, whora_llegada, wminutos_retardo, wind_estado)
            ON CONFLICT (id_aprendiz, fec_asistencia) 
            DO UPDATE SET hora_llegada    = EXCLUDED.hora_llegada,
                          ind_estado      = EXCLUDED.ind_estado,
                          minutos_retardo = EXCLUDED.minutos_retardo;
            RETURN TRUE;
        END IF;
        RETURN FALSE;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Excepción al procesar asistencia. ERROR: % - ESTADO: %', SQLERRM, SQLSTATE;
            RETURN FALSE;
    END;
$$
LANGUAGE plpgsql;