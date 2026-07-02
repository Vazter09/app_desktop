-- Marca como Ausente a aprendices activos sin registro de asistencia tras cierre de jornada.
CREATE OR REPLACE FUNCTION fun_marcar_ausentes_fecha(
    wfecha DATE,
    wid_ficha tab_fichas.id_ficha%TYPE DEFAULT NULL
) RETURNS INTEGER AS
$$
DECLARE
    v_count INTEGER := 0;
BEGIN
    IF wfecha IS NULL OR wfecha > CURRENT_DATE THEN
        PERFORM smartcset_raise_validacion('La fecha no puede ser futura.');
    END IF;

    INSERT INTO tab_asistencia_aprendiz (
        id_aprendiz,
        fec_asistencia,
        hora_asistencia,
        minutos_retraso,
        ind_estado,
        usr_insert,
        fec_insert
    )
    SELECT DISTINCT ON (af.id_aprendiz)
        af.id_aprendiz,
        wfecha,
        CASE
            WHEN EXTRACT(DOW FROM wfecha) = 6 THEN j.hora_llegada_sabado
            ELSE j.hora_entrada
        END,
        0,
        'Ausente',
        'sistema',
        CURRENT_TIMESTAMP
    FROM tab_aprendices_fichas af
    INNER JOIN tab_aprendices a
            ON a.id_aprendiz = af.id_aprendiz
           AND a.ind_etdo_formacion = 1
    INNER JOIN tab_fichas f
            ON f.id_ficha = af.id_ficha
           AND f.ind_estado = 3
    INNER JOIN tab_jornadas j
            ON j.id_jornada = af.id_jornada
    WHERE (wid_ficha IS NULL OR af.id_ficha = wid_ficha)
      AND NOT EXISTS (
        SELECT 1
          FROM tab_asistencia_aprendiz aa
         WHERE aa.id_aprendiz = af.id_aprendiz
           AND aa.fec_asistencia = wfecha
    )
      AND (
            wfecha < CURRENT_DATE
            OR (
                wfecha = CURRENT_DATE
                AND CURRENT_TIME > CASE
                    WHEN EXTRACT(DOW FROM wfecha) = 6 THEN j.hora_salida_sabado
                    ELSE j.hora_salida
                END
            )
          )
    ORDER BY af.id_aprendiz, af.id_ficha
    ON CONFLICT (id_aprendiz, fec_asistencia) DO NOTHING;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
