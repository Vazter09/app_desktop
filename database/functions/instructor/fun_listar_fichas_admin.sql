-- Fichas en ejecución (consulta administrador solo lectura).
CREATE OR REPLACE FUNCTION fun_listar_fichas_admin()
RETURNS TABLE (
    id_ficha            DECIMAL,
    nom_programa        VARCHAR,
    id_jornada          DECIMAL,
    nom_jornada         VARCHAR,
    ind_estado_ficha    DECIMAL,
    origen_vinculo      TEXT,
    num_aprendices      BIGINT,
    fec_inicio          DATE,
    fec_fin_lectiva     DATE
) AS
$$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        f.id_ficha,
        pr.nom_programa,
        f.id_jornada,
        j.nom_jornada,
        f.ind_estado AS ind_estado_ficha,
        'admin'::TEXT AS origen_vinculo,
        COUNT(af.id_aprendiz) FILTER (WHERE a.ind_etdo_formacion = 1) AS num_aprendices,
        f.fec_inicio,
        f.fec_fin_lectiva
    FROM tab_fichas f
    INNER JOIN tab_programas pr ON pr.id_programa = f.id_programa
    INNER JOIN tab_jornadas j ON j.id_jornada = f.id_jornada
    LEFT JOIN tab_aprendices_fichas af ON af.id_ficha = f.id_ficha
    LEFT JOIN tab_aprendices a ON a.id_aprendiz = af.id_aprendiz
    WHERE f.ind_estado = 3
    GROUP BY
        f.id_ficha,
        pr.nom_programa,
        f.id_jornada,
        j.nom_jornada,
        f.ind_estado,
        f.fec_inicio,
        f.fec_fin_lectiva
    ORDER BY f.id_ficha;
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
