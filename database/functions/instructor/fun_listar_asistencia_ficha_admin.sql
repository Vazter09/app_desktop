-- Asistencia de aprendices por ficha (administrador solo lectura).
CREATE OR REPLACE FUNCTION fun_listar_asistencia_ficha_admin(
    wid_ficha  tab_fichas.id_ficha%TYPE,
    wfec_desde DATE,
    wfec_hasta DATE
) RETURNS TABLE (
    fec_asistencia   DATE,
    id_aprendiz      DECIMAL,
    nom_completo     TEXT,
    id_jornada       DECIMAL,
    nom_jornada      VARCHAR,
    hora_asistencia  TIME,
    minutos_retraso  INTEGER,
    ind_estado       VARCHAR
) AS
$$
DECLARE
    v_dias INTEGER;
    v_fecha DATE;
BEGIN
    IF wfec_desde IS NULL OR wfec_hasta IS NULL THEN
        PERFORM smartcset_raise_validacion('Indique el rango de fechas.');
    END IF;

    IF wfec_desde > wfec_hasta THEN
        PERFORM smartcset_raise_validacion('La fecha inicial no puede ser posterior a la final.');
    END IF;

    v_dias := (wfec_hasta - wfec_desde) + 1;
    IF v_dias > 31 THEN
        PERFORM smartcset_raise_validacion('El rango máximo permitido es de 31 días.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_fichas f
         WHERE f.id_ficha = wid_ficha
           AND f.ind_estado = 3
    ) THEN
        PERFORM smartcset_raise_negocio('La ficha no existe o no está en ejecución.');
    END IF;

    v_fecha := wfec_desde;
    WHILE v_fecha <= wfec_hasta LOOP
        PERFORM fun_marcar_ausentes_fecha(v_fecha, wid_ficha);
        v_fecha := v_fecha + 1;
    END LOOP;

    RETURN QUERY
    WITH fechas AS (
        SELECT generate_series(wfec_desde, wfec_hasta, '1 day'::INTERVAL)::DATE AS fec
    ),
    aprendices_ficha AS (
        SELECT
            af.id_aprendiz,
            TRIM(p.nom_persona) || ' ' || TRIM(p.ape_persona) AS nom_completo,
            af.id_jornada,
            j.nom_jornada,
            j.hora_entrada,
            j.hora_salida,
            j.hora_llegada_sabado,
            j.hora_salida_sabado
        FROM tab_aprendices_fichas af
        INNER JOIN tab_aprendices a
                ON a.id_aprendiz = af.id_aprendiz
               AND a.ind_etdo_formacion = 1
        INNER JOIN tab_personas p ON p.id_persona = af.id_aprendiz
        INNER JOIN tab_jornadas j ON j.id_jornada = af.id_jornada
        WHERE af.id_ficha = wid_ficha
    ),
    grid AS (
        SELECT f.fec AS fec_asistencia, ap.*
          FROM fechas f
         CROSS JOIN aprendices_ficha ap
    )
    SELECT
        g.fec_asistencia,
        g.id_aprendiz,
        g.nom_completo,
        g.id_jornada,
        g.nom_jornada,
        COALESCE(aa.hora_asistencia, '00:00:00'::TIME) AS hora_asistencia,
        COALESCE(aa.minutos_retraso, 0) AS minutos_retraso,
        COALESCE(
            aa.ind_estado,
            CASE
                WHEN g.fec_asistencia > CURRENT_DATE THEN 'Desconocido'
                WHEN g.fec_asistencia = CURRENT_DATE
                     AND CURRENT_TIME <= CASE
                         WHEN EXTRACT(DOW FROM g.fec_asistencia) = 6 THEN g.hora_salida_sabado
                         ELSE g.hora_salida
                     END THEN 'Pendiente'
                ELSE 'Ausente'
            END
        ) AS ind_estado
    FROM grid g
    LEFT JOIN tab_asistencia_aprendiz aa
           ON aa.id_aprendiz = g.id_aprendiz
          AND aa.fec_asistencia = g.fec_asistencia
    ORDER BY g.fec_asistencia DESC, g.nom_completo ASC;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
