CREATE OR REPLACE FUNCTION fun_procesar_df49()
RETURNS TABLE(
    insertados   BIGINT,
    actualizados BIGINT,
    codigo_error BIGINT
) AS $$
DECLARE
    v_id_ficha           tab_temp_df49.id_ficha%TYPE;
    v_id_programa        tab_temp_df49.id_programa%TYPE;
    v_nom_programa       tab_temp_df49.nom_programa%TYPE;
    v_id_version         tab_temp_df49.id_version%TYPE;
    v_ind_estado         tab_temp_df49.ind_estado%TYPE;
    v_id_prog_especial   tab_temp_df49.id_prog_especial%TYPE;
    v_nom_prog_especial  tab_temp_df49.nom_prog_especial%TYPE;
    v_num_version        tab_programas.num_version%TYPE;
    v_total_insertados   BIGINT := 0;
    v_total_actualizados BIGINT := 0;
    v_total_errores      BIGINT := 0;
    v_filas              BIGINT;
BEGIN
    -- Procesar cada ficha DISTINTA, tomando el estado más reciente
    FOR v_id_ficha, v_id_programa, v_nom_programa, v_id_version, v_ind_estado, v_id_prog_especial, v_nom_prog_especial IN
        SELECT DISTINCT ON (id_ficha) 
            id_ficha,
            id_programa,
            nom_programa,
            id_version,
            ind_estado,
            id_prog_especial,
            nom_prog_especial
        FROM tab_temp_df49
        ORDER BY id_ficha, fecha_reporte DESC
    LOOP
        BEGIN
            -- 1. Calcular versión del programa
            v_num_version := CASE WHEN v_id_version > 99 THEN 1 ELSE v_id_version END;

            -- 2. UPSERT de tab_programas
            INSERT INTO tab_programas (id_programa, nom_programa, num_version)
            VALUES (v_id_programa, v_nom_programa, v_num_version)
            ON CONFLICT (id_programa) DO NOTHING;
            GET DIAGNOSTICS v_filas = ROW_COUNT;
            v_total_insertados := v_total_insertados + v_filas;

            UPDATE tab_programas
            SET nom_programa = v_nom_programa,
                num_version  = v_num_version
            WHERE id_programa = v_id_programa
              AND (nom_programa IS DISTINCT FROM v_nom_programa
                   OR num_version IS DISTINCT FROM v_num_version);
            GET DIAGNOSTICS v_filas = ROW_COUNT;
            v_total_actualizados := v_total_actualizados + v_filas;

            -- 3. UPSERT de tab_prog_especiales (solo si id válido)
            IF v_id_prog_especial IS NOT NULL AND v_id_prog_especial > 0 THEN
                INSERT INTO tab_prog_especiales (id_prog_especial, nom_prog_especial)
                VALUES (v_id_prog_especial, v_nom_prog_especial)
                ON CONFLICT (id_prog_especial) DO NOTHING;
                GET DIAGNOSTICS v_filas = ROW_COUNT;
                v_total_insertados := v_total_insertados + v_filas;

                UPDATE tab_prog_especiales
                SET nom_prog_especial = v_nom_prog_especial
                WHERE id_prog_especial = v_id_prog_especial
                  AND nom_prog_especial IS DISTINCT FROM v_nom_prog_especial;
                GET DIAGNOSTICS v_filas = ROW_COUNT;
                v_total_actualizados := v_total_actualizados + v_filas;
            END IF;

            -- 4. Actualizar SOLO ind_estado en tab_fichas
            UPDATE tab_fichas
            SET ind_estado = 
                CASE UPPER(TRIM(v_ind_estado))
                    WHEN 'INSCRIPCION' THEN 1
                    WHEN 'MATRICULA'   THEN 2
                    WHEN 'EJECUCION'   THEN 3
                    WHEN 'TERMINADA'   THEN 7
                    WHEN 'CERRADA'     THEN 8
                    ELSE 9
                END
            WHERE id_ficha = v_id_ficha;

            GET DIAGNOSTICS v_filas = ROW_COUNT;
            v_total_actualizados := v_total_actualizados + v_filas;

            IF v_filas = 0 THEN
                v_total_errores := v_total_errores + 1;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                v_total_errores := v_total_errores + 1;
                -- Opcional: registrar el error en un log o con RAISE WARNING
                -- RAISE WARNING 'Error al procesar ficha %: %', v_id_ficha, SQLERRM;
        END;
    END LOOP;

    -- 5. Retornar totales
    RETURN QUERY SELECT v_total_insertados, v_total_actualizados, v_total_errores;
END;
$$ LANGUAGE plpgsql;


SELECT * from fun_procesar_df49();
