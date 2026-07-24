-- Función para los retardos del aprendiz.

CREATE OR REPLACE FUNCTION fun_verify_retardo_aprendiz(
    p_id_aprendiz        DECIMAL(10,0),             -- id del aprendiz
    p_hora_llegada       TIMESTAMPTZ,               -- hora de llegada con zona horaria
    p_usr_insert         VARCHAR(50),               -- usuario que registra
    p_id_metodo_aut      DECIMAL(2,0)   DEFAULT 1,  -- Método de autenticación (ej: 1 = manual)
    p_id_entrada_centro  DECIMAL(1,0)   DEFAULT 1,  -- Entrada principal
    p_val_observaciones  TEXT           DEFAULT NULL
) RETURNS BOOLEAN AS
$$
DECLARE
    v_tiempo_gracia       DECIMAL(2,0);
    v_id_ficha            DECIMAL(10,0);
    v_id_jornada          DECIMAL(2,0);
    v_hora_entrada        TIME;
    v_hora_salida         TIME;
    v_hora_limite_gracia  TIME;
    v_minutos_retardo     INT := 0;
    v_estado              VARCHAR(20);
    v_tiene_permiso       BOOLEAN := FALSE;
    v_hora_llegada_time   TIME;
    v_usr_actual          VARCHAR(50);
    v_id_centro           DECIMAL(8,0);
    v_motivo_llamado      TEXT;
    v_id_ingreso          INTEGER;
    v_fec_ingreso         TIMESTAMP;
    v_fecha_asistencia    DATE;
BEGIN
    -- Obtener usuario de sesión o usar el proporcionado
    v_usr_actual := COALESCE(p_usr_insert, current_setting('app.current_user', true), 'SISTEMA');
    v_fec_ingreso := p_hora_llegada;
    v_fecha_asistencia := p_hora_llegada::DATE;  -- Fecha de la asistencia

    -- Extraer solo la hora sin fecha
    v_hora_llegada_time := p_hora_llegada::TIME;

    -- 1. Obtener parámetros generales (tiempo de gracia)
    SELECT val_tiempo_gracia_aprendiz
    INTO v_tiempo_gracia
    FROM tab_pmtros_grales
    LIMIT 1;

    IF v_tiempo_gracia IS NULL THEN
        RAISE NOTICE 'No se encontró tiempo de gracia en parámetros generales.';
        RETURN FALSE;
    END IF;

    -- 2. Validar que el aprendiz existe, está activo (ind_etdo_formacion = 1) y su ficha está en ejecución (ind_estado = 3)
    SELECT a.id_ficha, f.id_jornada, f.id_centro
    INTO v_id_ficha, v_id_jornada, v_id_centro
    FROM tab_aprendices a
    JOIN tab_fichas f ON a.id_ficha = f.id_ficha
    WHERE a.id_aprendiz = p_id_aprendiz
      AND a.ind_etdo_formacion = 1
      AND f.ind_estado = 3;

    IF NOT FOUND THEN
        RAISE NOTICE 'El aprendiz % no está activo o su ficha no está en ejecución.', p_id_aprendiz;
        RETURN FALSE;
    END IF;

    -- 3. Obtener la jornada (hora de entrada y salida)
    SELECT hora_entrada, hora_salida
    INTO v_hora_entrada, v_hora_salida
    FROM tab_jornadas
    WHERE id_jornada = v_id_jornada;

    IF NOT FOUND THEN
        RAISE NOTICE 'No se encontró la jornada para el aprendiz %.', p_id_aprendiz;
        RETURN FALSE;
    END IF;

    -- 4. Si la llegada es después de la hora de salida, no registrar (asistencia fuera de horario)
    IF v_hora_llegada_time > v_hora_salida THEN
        RAISE NOTICE 'La hora de llegada (%) es posterior a la hora de salida (%). No se registra.',
                     v_hora_llegada_time, v_hora_salida;
        RETURN FALSE;
    END IF;

    -- 5. Calcular hora límite con gracia (hora_entrada + tiempo_gracia minutos)
    v_hora_limite_gracia := v_hora_entrada + (v_tiempo_gracia || ' minutes')::INTERVAL;

    -- 6. Determinar si tiene permiso activo
    SELECT EXISTS (
        SELECT 1
        FROM tab_permisos_aprendiz
        WHERE id_aprendiz = p_id_aprendiz
          AND v_fecha_asistencia BETWEEN fec_inicio_permiso AND fec_final_permiso
    ) INTO v_tiene_permiso;

    -- 7. Calcular estado y minutos de retraso (CORREGIDO: desde la hora límite de gracia)
    IF v_hora_llegada_time <= v_hora_limite_gracia THEN
        v_estado := 'Presente';
        v_minutos_retardo := 0;
    ELSE
        IF v_tiene_permiso THEN
            v_estado := 'Presente';
            v_minutos_retardo := 0;
        ELSE
            v_estado := 'Tarde';
            -- Calcular retraso desde la hora límite de gracia (no desde la hora de entrada)
            v_minutos_retardo := EXTRACT(EPOCH FROM (v_hora_llegada_time - v_hora_limite_gracia)) / 60;
            -- Asegurar que no sea negativo
            IF v_minutos_retardo < 0 THEN
                v_minutos_retardo := 0;
            END IF;
        END IF;
    END IF;

    -- 8. Insertar en tab_log_ingresos (REGISTRO DE INGRESO)
    -- Obtener próximo id_ingreso (se recomienda usar una secuencia, pero por ahora se calcula)
    SELECT COALESCE(MAX(id_ingreso), 0) + 1 INTO v_id_ingreso FROM tab_log_ingresos;

    INSERT INTO tab_log_ingresos (
        id_ingreso,
        id_visitante,
        fec_ingreso,
        fec_salida,
        id_metodo_aut,
        id_entrada_centro,
        val_observaciones,
        usr_insert,
        fec_insert
    ) VALUES (
        v_id_ingreso,
        p_id_aprendiz,
        v_fec_ingreso,
        v_fec_ingreso,  -- fec_salida igual por ahora (se actualizará después)
        p_id_metodo_aut,
        p_id_entrada_centro,
        COALESCE(p_val_observaciones, 'Ingreso registrado automáticamente: ' || v_estado || ' (retraso: ' || v_minutos_retardo || ' min)'),
        v_usr_actual,
        CURRENT_TIMESTAMP
    );

    RAISE NOTICE 'Registro de ingreso insertado en tab_log_ingresos. ID: %, Visitante: %, Estado: %, Retraso real: % min',
                 v_id_ingreso, p_id_aprendiz, v_estado, v_minutos_retardo;

    -- 9. Insertar o actualizar asistencia en tab_asistencia_aprendiz (respetando PK compuesta)
    INSERT INTO tab_asistencia_aprendiz (
        id_aprendiz,
        fec_asistencia,
        hora_asistencia,
        minutos_retraso,
        ind_estado,
        usr_insert,
        fec_insert
    ) VALUES (
        p_id_aprendiz,
        v_fecha_asistencia,   -- Fecha de la asistencia (NO CURRENT_DATE)
        p_hora_llegada,
        v_minutos_retardo,
        v_estado,
        v_usr_actual,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (id_aprendiz, fec_asistencia) DO UPDATE
    SET hora_asistencia  = EXCLUDED.hora_asistencia,
        minutos_retraso  = EXCLUDED.minutos_retraso,
        ind_estado       = EXCLUDED.ind_estado,
        usr_update       = v_usr_actual,
        fec_update       = CURRENT_TIMESTAMP;

    RAISE NOTICE 'Asistencia registrada en tab_asistencia_aprendiz para aprendiz %. Fecha: %, Estado: %, Retardo real: % min',
                 p_id_aprendiz, v_fecha_asistencia, v_estado, v_minutos_retardo;

    -- 10. Si es Tarde y tiene retraso > 0, insertar llamado de atención
    IF v_estado = 'Tarde' AND v_minutos_retardo > 0 THEN
        v_motivo_llamado := 'Retardo de ' || v_minutos_retardo || ' minutos (excediendo gracia de ' || v_tiempo_gracia || ' min). Llegada a las ' || v_hora_llegada_time;

        INSERT INTO tab_llamados_atencion (
            ind_tipo,
            id_tercero,
            ind_tipo_tercero,
            motivo_llamado,
            usr_insert,
            fec_insert
        ) VALUES (
            FALSE,                           -- Disciplinario
            p_id_aprendiz,
            TRUE,                            -- Es aprendiz
            v_motivo_llamado,
            v_usr_actual,
            CURRENT_TIMESTAMP
        );

        RAISE NOTICE 'Se insertó llamado de atención por retardo para aprendiz %. Minutos de retraso real: %',
                     p_id_aprendiz, v_minutos_retardo;
    END IF;

    RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error al procesar asistencia del aprendiz %. ERROR: % - ESTADO: %',
                      p_id_aprendiz, SQLERRM, SQLSTATE;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;


-- Inserción de prueba para verificar la función.

SELECT fun_verify_retardo_aprendiz(
    1095951827,                      	-- id_aprendiz
    '2026-07-03 12:15:00'::TIMESTAMPTZ, -- hora de llegada
    'admin.smart',      	            -- usuario
    1,                               	-- id_metodo_aut (1 = manual)
    1,                               	-- id_entrada_centro (1 = principal)
    'Ingreso registrado desde test'  	-- observaciones
);