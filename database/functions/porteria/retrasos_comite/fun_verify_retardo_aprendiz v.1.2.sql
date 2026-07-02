-- Función para los retardos del aprendiz.

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
    whora_llegada_time TIME;
BEGIN
    -- Extraer solo la hora para comparar con columnas TIME
    whora_llegada_time := whora_llegada::TIME;

    -- 1. Obtener parámetros generales
    SELECT val_tiempo_gracia_aprendiz
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

    -- 4. Si llegada > hora_salida → no registrar
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
            -- Aquí YA NO hay UPDATE de llamados, solo se registra el retraso en la asistencia
        END IF;
    END IF;

    -- 7. Insertar o actualizar asistencia
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




-- Trigger para actualizar los llamados de atención del aprendiz (Según los retardos).

CREATE OR REPLACE FUNCTION fn_after_asistencia_llamados()
RETURNS TRIGGER AS $$
DECLARE
    v_tiempo_gracia INT;
    v_max_llamados  INT;
    v_llamados_actual SMALLINT;
BEGIN
    -- Obtener parámetros
    SELECT val_tiempo_gracia_aprendiz, val_max_llamados_aprendiz
      INTO v_tiempo_gracia, v_max_llamados
      FROM tab_pmtros_grales
     LIMIT 1;

    -- Solo actuar si es 'Tarde' y supera la gracia
    IF NEW.ind_estado = 'Tarde' AND NEW.minutos_retraso > v_tiempo_gracia THEN
        -- Incrementar llamados
        UPDATE tab_aprendices
           SET num_llamados = num_llamados + 1
         WHERE id_aprendiz = NEW.id_aprendiz;

        -- Obtener nuevo valor y verificar límite
        SELECT num_llamados
          INTO v_llamados_actual
          FROM tab_aprendices
         WHERE id_aprendiz = NEW.id_aprendiz;

        IF v_llamados_actual >= v_max_llamados THEN
            RAISE NOTICE 'Aprendiz % (llamados acumulados: %).',
                         NEW.id_aprendiz, v_llamados_actual;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_after_asistencia_llamados
AFTER INSERT OR UPDATE ON tab_asistencia_aprendiz
FOR EACH ROW
EXECUTE FUNCTION fn_after_asistencia_llamados();




-- Inserción de prueba para verificar la función.

SELECT fun_verify_retardo_aprendiz(
    1095951827,                              -- id_aprendiz
    '2026-07-23 13:30:00'::TIMESTAMPTZ,      -- whora_llegada (TIMESTAMPTZ)
    'postgres'                         -- wusr_insert
);