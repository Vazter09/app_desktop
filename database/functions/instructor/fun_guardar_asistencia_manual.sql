-- Registro o actualización manual de asistencia por el instructor.
CREATE OR REPLACE FUNCTION fun_guardar_asistencia_manual(
    wid_instructor tab_instructores.id_instructor%TYPE,
    wid_ficha      tab_fichas.id_ficha%TYPE,
    wid_aprendiz   tab_aprendices.id_aprendiz%TYPE,
    wfec_asistencia DATE,
    wind_estado    VARCHAR,
    wusr_audit     VARCHAR,
    wind_solo_insert BOOLEAN DEFAULT FALSE
) RETURNS TEXT AS
$$
DECLARE
    v_hora TIME;
    v_minutos INTEGER := 0;
    v_existe BOOLEAN;
BEGIN
    IF wid_instructor IS NULL OR wid_ficha IS NULL OR wid_aprendiz IS NULL THEN
        PERFORM smartcset_raise_validacion('Datos incompletos para registrar asistencia.');
    END IF;

    IF wfec_asistencia IS NULL OR wfec_asistencia > CURRENT_DATE THEN
        PERFORM smartcset_raise_validacion('La fecha de asistencia no puede ser futura.');
    END IF;

    IF wind_estado NOT IN ('Presente', 'Tarde', 'Ausente', 'Desconocido') THEN
        PERFORM smartcset_raise_validacion('Estado de asistencia no válido.');
    END IF;

    IF wusr_audit IS NULL OR LENGTH(TRIM(wusr_audit)) < 3 THEN
        PERFORM smartcset_raise_validacion('Usuario de auditoría inválido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM tab_fichas f
         WHERE f.id_ficha = wid_ficha
           AND f.id_instructor_lider = wid_instructor
           AND f.ind_estado = 3
        UNION ALL
        SELECT 1
          FROM tab_programacion p
         WHERE p.id_ficha = wid_ficha
           AND p.id_instructor = wid_instructor
           AND wfec_asistencia BETWEEN p.fec_inicial AND p.fec_final
    ) THEN
        PERFORM smartcset_raise_negocio('No tiene permiso para registrar asistencia en esta ficha.');
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM tab_aprendices_fichas af
         INNER JOIN tab_aprendices a
                 ON a.id_aprendiz = af.id_aprendiz
                AND a.ind_etdo_formacion = 1
         WHERE af.id_ficha = wid_ficha
           AND af.id_aprendiz = wid_aprendiz
    ) THEN
        PERFORM smartcset_raise_negocio('El aprendiz no está activo en la ficha seleccionada.');
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM tab_asistencia_aprendiz aa
         WHERE aa.id_aprendiz = wid_aprendiz
           AND aa.fec_asistencia = wfec_asistencia
    ) INTO v_existe;

    IF wind_solo_insert AND v_existe THEN
        PERFORM smartcset_raise_negocio('Ya existe un registro de asistencia para este aprendiz en la fecha indicada.');
    END IF;

    IF NOT wind_solo_insert AND NOT v_existe THEN
        PERFORM smartcset_raise_negocio('No hay registro de asistencia para actualizar en la fecha indicada.');
    END IF;

    SELECT CASE
        WHEN EXTRACT(DOW FROM wfec_asistencia) = 6 THEN j.hora_llegada_sabado
        ELSE j.hora_entrada
    END
    INTO v_hora
    FROM tab_aprendices_fichas af
    INNER JOIN tab_jornadas j ON j.id_jornada = af.id_jornada
    WHERE af.id_ficha = wid_ficha
      AND af.id_aprendiz = wid_aprendiz
    LIMIT 1;

    IF v_hora IS NULL THEN
        v_hora := CURRENT_TIME;
    END IF;

    IF wind_estado = 'Tarde' THEN
        v_minutos := 15;
    END IF;

    IF wind_estado IN ('Ausente', 'Desconocido') THEN
        v_hora := '00:00:00'::TIME;
        v_minutos := 0;
    END IF;

    IF v_existe THEN
        UPDATE tab_asistencia_aprendiz
           SET ind_estado = wind_estado,
               hora_asistencia = v_hora,
               minutos_retraso = v_minutos,
               usr_update = wusr_audit,
               fec_update = CURRENT_TIMESTAMP
         WHERE id_aprendiz = wid_aprendiz
           AND fec_asistencia = wfec_asistencia;
    ELSE
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
            wfec_asistencia,
            v_hora,
            v_minutos,
            wind_estado,
            wusr_audit,
            CURRENT_TIMESTAMP
        );
    END IF;

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
