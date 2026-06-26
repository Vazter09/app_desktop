-- Ejecución la función 
-- SELECT fun_carga_df14a();

CREATE OR REPLACE FUNCTION fun_cargar_df14a()
RETURNS TEXT AS $$
DECLARE
    rec RECORD;
    v_id_nivel DECIMAL(2,0);
    v_nombre_nivel TEXT;
    v_log TEXT := '';
BEGIN
    -- Recorrer todos los registros de la tabla temporal
    FOR rec IN 
        SELECT 
            cod_programa,
            nom_programa,
            niv_formacion,
            num_docum_empresa,
            nom_empresa
        FROM tab_temp_df14A
        WHERE cod_programa IS NOT NULL 
          AND num_docum_empresa IS NOT NULL
          AND num_docum_empresa > 0
    LOOP

        -- 1. Manejo de nivel de estudio

        v_nombre_nivel := TRIM(rec.niv_formacion);
        IF v_nombre_nivel = '' THEN
            v_nombre_nivel := 'SIN NIVEL';
        END IF;

        -- Buscar el nivel por nombre
        SELECT id_nivel_estudio INTO v_id_nivel
        FROM tab_niveles_estudio
        WHERE nom_nivel_estudio = v_nombre_nivel;

        -- Si no existe, insertarlo
        IF v_id_nivel IS NULL THEN
            -- Obtener nuevo ID (usando secuencia si existe, si no, max+1)
            BEGIN
                -- Intentar usar secuencia (debe existir)
                v_id_nivel := nextval('seq_id_nivel_estudio')::DECIMAL(2,0);
            EXCEPTION
                WHEN undefined_object THEN
                    -- Si no hay secuencia, usar max+1
                    SELECT COALESCE(MAX(id_nivel_estudio), 0) + 1 INTO v_id_nivel
                    FROM tab_niveles_estudio;
                    -- Asegurar que no exceda 99
                    IF v_id_nivel > 99 THEN
                        RAISE EXCEPTION 'No hay espacio para más niveles (máximo 99)';
                    END IF;
            END;

            INSERT INTO tab_niveles_estudio (
                id_nivel_estudio,
                nom_nivel_estudio,
                usr_insert,
                fec_insert
            ) VALUES (
                v_id_nivel,
                v_nombre_nivel,
                current_user,
                now()
            ) ON CONFLICT (id_nivel_estudio) DO NOTHING;

            RAISE NOTICE 'Nivel insertado: % (id=%)', v_nombre_nivel, v_id_nivel;
        END IF;


        -- 2. Manejo de programas

        INSERT INTO tab_programas (
            id_programa,
            nom_programa
            -- Las demás columnas usarán sus DEFAULT
        ) VALUES (
            rec.cod_programa,
            rec.nom_programa
        ) ON CONFLICT (id_programa) DO UPDATE SET
            nom_programa = EXCLUDED.nom_programa,
            usr_update = current_user,
            fec_update = now()
        WHERE tab_programas.nom_programa IS DISTINCT FROM EXCLUDED.nom_programa;

        IF FOUND THEN
            IF (SELECT COUNT(*) FROM tab_programas WHERE id_programa = rec.cod_programa) = 1 THEN
                RAISE NOTICE 'Programa actualizado: id=%, nombre=%', rec.cod_programa, rec.nom_programa;
            ELSE
                RAISE NOTICE 'Programa insertado: id=%, nombre=%', rec.cod_programa, rec.nom_programa;
            END IF;
        END IF;

        -- 3. Manejo de empresas

        INSERT INTO tab_empresas (
            id_empresa,
            id_tipo_docum,
            nom_empresa
        ) VALUES (
            rec.num_docum_empresa,
            'NIT',  -- Por defecto, según especificación
            rec.nom_empresa
        ) ON CONFLICT (id_empresa) DO UPDATE SET
            nom_empresa = EXCLUDED.nom_empresa,
            usr_update = current_user,
            fec_update = now()
        WHERE tab_empresas.nom_empresa IS DISTINCT FROM EXCLUDED.nom_empresa;

        IF FOUND THEN
            IF (SELECT COUNT(*) FROM tab_empresas WHERE id_empresa = rec.num_docum_empresa) = 1 THEN
                RAISE NOTICE 'Empresa actualizada: id=%, nombre=%', rec.num_docum_empresa, rec.nom_empresa;
            ELSE
                RAISE NOTICE 'Empresa insertada: id=%, nombre=%', rec.num_docum_empresa, rec.nom_empresa;
            END IF;
        END IF;

    END LOOP;

    RETURN 'Proceso completado exitosamente.';
END;
$$ LANGUAGE plpgsql;