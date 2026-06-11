CREATE OR REPLACE FUNCTION fun_migrar_fichas_creadas()
RETURNS TABLE (insertados INTEGER, actualizados INTEGER, errores INTEGER) AS
$$
DECLARE
    v_rec RECORD;
    v_id_persona tab_personas.id_persona%TYPE;
    v_nom_persona tab_personas.nom_persona%TYPE;
    v_ape_persona tab_personas.ape_persona%TYPE;
    v_insertados  INTEGER := 0;
    v_actualizados INTEGER := 0;
    v_errores     INTEGER := 0;
    v_rowcount    INTEGER;
BEGIN
    FOR v_rec IN
        SELECT DISTINCT
            num_documento,
            nombre_instructor,
            apellido_instructor
        FROM tab_temp_fichas_creadas
        WHERE num_documento IS NOT NULL
          AND num_documento > 0
          AND TRIM(nombre_instructor) != ''
          AND TRIM(apellido_instructor) != ''
    LOOP
        v_id_persona := v_rec.num_documento;
        v_nom_persona := INITCAP(TRIM(v_rec.nombre_instructor));
        v_ape_persona := INITCAP(TRIM(v_rec.apellido_instructor));

        -- 1. Manejo de tab_personas (UPDATE o INSERT)
        BEGIN
            -- Intentar actualizar primero
            UPDATE tab_personas
            SET nom_persona = v_nom_persona,
                ape_persona = v_ape_persona,
                usr_update = 'carga_automatica',
                fec_update = CURRENT_TIMESTAMP
            WHERE id_persona = v_id_persona;
            
            GET DIAGNOSTICS v_rowcount = ROW_COUNT;
            
            IF v_rowcount = 0 THEN
                -- No existe, insertar
                INSERT INTO tab_personas (
                    id_persona,
                    id_tipo_docum,
                    id_tipo_persona,
                    nom_persona,
                    ape_persona,
                    usr_insert,
                    fec_insert
                ) VALUES (
                    v_id_persona,
                    DEFAULT,
                    3,
                    v_nom_persona,
                    v_ape_persona,
                    'carga_automatica',
                    CURRENT_TIMESTAMP
                );
                v_insertados := v_insertados + 1;
            ELSE
                v_actualizados := v_actualizados + 1;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                v_errores := v_errores + 1;
                RAISE NOTICE 'Error en persona ID %: %', v_id_persona, SQLERRM;
                CONTINUE;
        END;

        -- 2. Manejo de tab_instructores (INSERT si no existe, UPDATE solo timestamps)
        BEGIN
            INSERT INTO tab_instructores (
                id_instructor,
                usr_insert,
                fec_insert
            ) VALUES (
                v_id_persona,
                'carga_automatica',
                CURRENT_TIMESTAMP
            )
            ON CONFLICT (id_instructor) DO UPDATE
            SET usr_update = EXCLUDED.usr_insert,
                fec_update = EXCLUDED.fec_insert;
            -- No se incrementan contadores aquí (ya se contabilizó la persona)
        EXCEPTION
            WHEN OTHERS THEN
                v_errores := v_errores + 1;
                RAISE NOTICE 'Error en instructor ID %: %', v_id_persona, SQLERRM;
        END;
    END LOOP;

    RETURN QUERY SELECT v_insertados, v_actualizados, v_errores;
END;
$$
LANGUAGE plpgsql;

SELECT fun_migrar_fichas_creadas();