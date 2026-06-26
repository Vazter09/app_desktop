-- Fichas a cargo de un instructor (líder y/o programación transversal vigente).
CREATE OR REPLACE FUNCTION fun_listar_fichas_instructor(
    wid_instructor tab_instructores.id_instructor%TYPE
) RETURNS TABLE (
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
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM tab_instructores i WHERE i.id_instructor = wid_instructor
    ) THEN
        PERFORM smartcset_raise_negocio('El instructor no está registrado en el sistema.');
    END IF;

    RETURN QUERY
    WITH fichas_lider AS (
        SELECT
            f.id_ficha,
            pr.nom_programa,
            f.id_jornada,
            j.nom_jornada,
            f.ind_estado AS ind_estado_ficha,
            'lider'::TEXT AS origen_vinculo,
            f.fec_inicio,
            f.fec_fin_lectiva
        FROM tab_fichas f
        INNER JOIN tab_programas pr ON pr.id_programa = f.id_programa
        INNER JOIN tab_jornadas j ON j.id_jornada = f.id_jornada
        WHERE f.id_instructor_lider = wid_instructor
          AND f.ind_estado = 3
    ),
    fichas_prog AS (
        SELECT DISTINCT ON (f.id_ficha)
            f.id_ficha,
            pr.nom_programa,
            p.id_jornada,
            j.nom_jornada,
            f.ind_estado AS ind_estado_ficha,
            'programacion'::TEXT AS origen_vinculo,
            f.fec_inicio,
            f.fec_fin_lectiva
        FROM tab_programacion p
        INNER JOIN tab_fichas f ON f.id_ficha = p.id_ficha AND f.ind_estado = 3
        INNER JOIN tab_programas pr ON pr.id_programa = f.id_programa
        INNER JOIN tab_jornadas j ON j.id_jornada = p.id_jornada
        WHERE p.id_instructor = wid_instructor
          AND CURRENT_DATE BETWEEN p.fec_inicial AND p.fec_final
        ORDER BY f.id_ficha, p.fec_inicial DESC
    ),
    fichas_union AS (
        SELECT * FROM fichas_lider
        UNION ALL
        SELECT fp.*
          FROM fichas_prog fp
         WHERE NOT EXISTS (
             SELECT 1 FROM fichas_lider fl WHERE fl.id_ficha = fp.id_ficha
         )
    )
    SELECT
        fu.id_ficha,
        fu.nom_programa,
        fu.id_jornada,
        fu.nom_jornada,
        fu.ind_estado_ficha,
        fu.origen_vinculo,
        COUNT(af.id_aprendiz) FILTER (WHERE a.ind_etdo_formacion = 1) AS num_aprendices,
        fu.fec_inicio,
        fu.fec_fin_lectiva
    FROM fichas_union fu
    LEFT JOIN tab_aprendices_fichas af ON af.id_ficha = fu.id_ficha
    LEFT JOIN tab_aprendices a ON a.id_aprendiz = af.id_aprendiz
    GROUP BY
        fu.id_ficha,
        fu.nom_programa,
        fu.id_jornada,
        fu.nom_jornada,
        fu.ind_estado_ficha,
        fu.origen_vinculo,
        fu.fec_inicio,
        fu.fec_fin_lectiva
    ORDER BY fu.id_ficha;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
