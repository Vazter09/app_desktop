-- Extension de pgsql para normalizar el nombre de las ciudades.
CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE SEQUENCE IF NOT EXISTS seq_id_sector START 1;

-- Crear tabla de logging (si no existe)
CREATE OR REPLACE FUNCTION procesar_tab_temp_pe04()
RETURNS TEXT AS $$
DECLARE
    r tab_temp_pe04%ROWTYPE;
    contador INTEGER := 0;
    v_diff_months INTEGER;
    v_id_ciudad tab_fichas.id_ciudad%TYPE;
    v_id_empresa tab_empresas.id_empresa%TYPE;
    v_tipo_docum tab_empresas.id_tipo_docum%TYPE;
    v_nom_empresa tab_empresas.nom_empresa%TYPE;
    v_id_prog_especial tab_prog_especiales.id_prog_especial%TYPE;
    v_nom_prog_especial tab_prog_especiales.nom_prog_especial%TYPE;
    v_num_version tab_programas.num_version%TYPE;
    v_fec_inicio DATE;
    v_fec_fin DATE;
BEGIN
    -- Asegurar existencia del registro por defecto para programas especiales (id=0)
    INSERT INTO tab_prog_especiales (id_prog_especial, nom_prog_especial)
    VALUES (0, 'Sin programa especial')
    ON CONFLICT (id_prog_especial) DO NOTHING;

    FOR r IN SELECT * FROM tab_temp_pe04 LOOP
        BEGIN
            -- 1. UPSERT nivel de estudio
            INSERT INTO tab_niveles_estudio (id_nivel_estudio, nom_nivel_estudio)
            VALUES (r.id_nivel_forma, r.nom_nivel_forma)
            ON CONFLICT (id_nivel_estudio) DO UPDATE SET nom_nivel_estudio = EXCLUDED.nom_nivel_estudio;

            -- 2. UPSERT sector
            INSERT INTO tab_sectores (id_sector, nom_sector)
            VALUES (r.id_sector_prog::DECIMAL(4,0), r.nom_sector_prog)
            ON CONFLICT (id_sector) DO UPDATE SET nom_sector = EXCLUDED.nom_sector;

            -- 3. UPSERT empresa con manejo de NULL
            IF r.id_empresa IS NULL THEN
                v_id_empresa := 999;
                v_tipo_docum := 'N/A';
                v_nom_empresa := 'Sin Empresa';
            ELSE
                v_id_empresa := r.id_empresa;
                v_tipo_docum := 'NIT';
                v_nom_empresa := r.nom_empresa;
            END IF;

            INSERT INTO tab_empresas (id_empresa, id_tipo_docum, nom_empresa)
            VALUES (v_id_empresa, v_tipo_docum, v_nom_empresa)
            ON CONFLICT (id_empresa) DO UPDATE SET 
                id_tipo_docum = EXCLUDED.id_tipo_docum,
                nom_empresa = EXCLUDED.nom_empresa;

            -- 4. UPSERT programa especial con manejo de NULL o 0
            IF r.id_prog_especial IS NULL OR r.id_prog_especial = 0 THEN
                v_id_prog_especial := 0;
                v_nom_prog_especial := 'Sin programa especial';
            ELSE
                v_id_prog_especial := r.id_prog_especial;
                v_nom_prog_especial := r.nom_prog_especial;
            END IF;

            INSERT INTO tab_prog_especiales (id_prog_especial, nom_prog_especial)
            VALUES (v_id_prog_especial, v_nom_prog_especial)
            ON CONFLICT (id_prog_especial) DO UPDATE SET nom_prog_especial = EXCLUDED.nom_prog_especial;

            -- 5. UPSERT ocupación
            IF r.id_ocupacion IS NOT NULL THEN
                INSERT INTO tab_ocupaciones (id_ocupacion, nom_ocupacion)
                VALUES (r.id_ocupacion, COALESCE(r.nom_ocupacion, 'OCUPACION DESCONOCIDA'))
                ON CONFLICT (id_ocupacion) DO UPDATE SET nom_ocupacion = EXCLUDED.nom_ocupacion;
            END IF;

            -- 6. UPSERT programa (tab_programas) con control de versión
            IF r.id_version IS NULL OR r.id_version > 99 THEN
                v_num_version := 1;
            ELSE
                v_num_version := r.id_version;
            END IF;

            INSERT INTO tab_programas (id_programa, nom_programa, num_version)
            VALUES (r.id_programa, r.nom_programa, v_num_version)
            ON CONFLICT (id_programa) DO UPDATE SET 
                nom_programa = EXCLUDED.nom_programa,
                num_version = EXCLUDED.num_version;

            -- 7. Preparar fechas y calcular duración en meses (val_duracion)
            v_fec_inicio := COALESCE(r.fec_inicio_ficha, CURRENT_DATE);
            v_fec_fin := COALESCE(r.fec_fin_ficha, CURRENT_DATE + INTERVAL '1 year');
            
            v_diff_months := EXTRACT(MONTH FROM age(v_fec_fin, v_fec_inicio)) 
                           + 12 * EXTRACT(YEAR FROM age(v_fec_fin, v_fec_inicio));
            v_diff_months := LEAST(v_diff_months, 99);

            -- 8. Obtener id_ciudad por nombre de municipio
            v_id_ciudad := '68001';
            IF r.nom_municipio IS NOT NULL AND r.nom_municipio != '' THEN
                SELECT id_ciudad INTO v_id_ciudad
                FROM tab_ciudades
                WHERE unaccent(lower(nom_ciudad)) = unaccent(lower(r.nom_municipio))
                LIMIT 1;
                IF NOT FOUND THEN
                    v_id_ciudad := '68001';
                END IF;
            END IF;

            -- 9. UPSERT ficha principal
            INSERT INTO tab_fichas (
                id_ficha, id_centro, id_programa, id_nivel_estudio, ind_jornada, ind_modalidad,
                fec_inicio, fec_fin_productiva, val_duracion, id_instructor_lider, id_sector,
                id_empresa, id_ocupacion, id_ciudad, cod_convenio, nom_convenio,
                ind_amp_cobertura, id_prog_especial, ind_abierta, nom_vocero, tel_vocero,
                mail_vocero, val_cupo, id_ambiente_base, num_inscritos_opcion1, num_inscritos_opcion2,
                ind_estado, num_cursos, tot_aprendices_masc, tot_aprendices_fem, tot_aprendices_nobin,
                tot_aprendices_trans, tot_horas_planta, tot_horas_contratista, tot_horas_contrat_ext,
                tot_horas_monitores, tot_horas_inst_empresa, tot_aprendices_activos, val_duracion_programa,
                id_nuevo_sector
            ) VALUES (
                COALESCE(r.id_ficha, 0)::DECIMAL(10,0),
                COALESCE(r.cod_centro, 0),
                r.id_programa,
                COALESCE(r.id_nivel_forma, 0),
                CASE WHEN COALESCE(r.id_jornada, 1) BETWEEN 1 AND 4 THEN r.id_jornada ELSE 1 END,
                CASE UPPER(TRIM(r.val_modalidad))
                    WHEN 'PRESENCIAL' THEN 1
                    WHEN 'VIRTUAL' THEN 2
                    WHEN 'DISTANCIA' THEN 3
                    ELSE 1
                END,
                v_fec_inicio,
                v_fec_fin,
                v_diff_months::DECIMAL(2,0),
                77777777,
                COALESCE(r.id_sector_prog, 0)::DECIMAL(4,0),
                v_id_empresa,
                COALESCE(r.id_ocupacion, 0),
                v_id_ciudad,
                COALESCE(r.id_convenio, 0),
                COALESCE(r.nom_convenio, 'Sin Convenio'),
                FALSE,
                v_id_prog_especial,
                FALSE,
                'Sin Vocero',
                '3000000000',
                'sin_correo@correo.com',
                COALESCE(r.num_tot_aprend, 30),
                'Sin Ambiente Base',
                0, 0,
                CASE UPPER(TRIM(r.ind_estado_curso))
                    WHEN 'INSCRIPCION' THEN 1
                    WHEN 'MATRICULA' THEN 2
                    WHEN 'EJECUCION' THEN 3
                    WHEN 'TERMINADA' THEN 7
                    WHEN 'CERRADA' THEN 8
                    ELSE 9
                END,
                COALESCE(r.num_cursos, 1),
                GREATEST(COALESCE(r.num_aprend_masc, 0), 0),
                GREATEST(COALESCE(r.num_aprend_fem, 0), 0),
                GREATEST(COALESCE(r.num_aprend_nobin, 0), 0),
                0,
                COALESCE(r.val_hrs_planta, '00:00:00'::INTERVAL),
                COALESCE(r.val_hrs_contrat, '00:00:00'::INTERVAL),
                COALESCE(r.val_hrs_context, '00:00:00'::INTERVAL),
                COALESCE(r.val_hrs_monitor, '00:00:00'::INTERVAL),
                COALESCE(r.val_hrs_instemp, '00:00:00'::INTERVAL),
                GREATEST(COALESCE(r.val_total_apr_act, 0), 0),
                make_interval(hours => COALESCE(r.val_duracion_prog, 0)::INT),  -- Conversión a integer
                COALESCE((SELECT id_sector FROM tab_sectores 
                          WHERE unaccent(lower(nom_sector)) = unaccent(lower(TRIM(r.nom_nuevo_sector))) 
                          LIMIT 1), 0)
            )
            ON CONFLICT (id_ficha) DO UPDATE SET
                id_centro = EXCLUDED.id_centro,
                id_programa = EXCLUDED.id_programa,
                id_nivel_estudio = EXCLUDED.id_nivel_estudio,
                ind_jornada = EXCLUDED.ind_jornada,
                ind_modalidad = EXCLUDED.ind_modalidad,
                fec_inicio = EXCLUDED.fec_inicio,
                fec_fin_productiva = EXCLUDED.fec_fin_productiva,
                val_duracion = EXCLUDED.val_duracion,
                id_sector = EXCLUDED.id_sector,
                id_empresa = EXCLUDED.id_empresa,
                id_ocupacion = EXCLUDED.id_ocupacion,
                id_ciudad = EXCLUDED.id_ciudad,
                cod_convenio = EXCLUDED.cod_convenio,
                nom_convenio = EXCLUDED.nom_convenio,
                ind_amp_cobertura = EXCLUDED.ind_amp_cobertura,
                id_prog_especial = EXCLUDED.id_prog_especial,
                ind_estado = EXCLUDED.ind_estado,
                num_cursos = EXCLUDED.num_cursos,
                tot_aprendices_masc = EXCLUDED.tot_aprendices_masc,
                tot_aprendices_fem = EXCLUDED.tot_aprendices_fem,
                tot_aprendices_nobin = EXCLUDED.tot_aprendices_nobin,
                tot_aprendices_trans = EXCLUDED.tot_aprendices_trans,
                tot_horas_planta = EXCLUDED.tot_horas_planta,
                tot_horas_contratista = EXCLUDED.tot_horas_contratista,
                tot_horas_contrat_ext = EXCLUDED.tot_horas_contrat_ext,
                tot_horas_monitores = EXCLUDED.tot_horas_monitores,
                tot_horas_inst_empresa = EXCLUDED.tot_horas_inst_empresa,
                tot_aprendices_activos = EXCLUDED.tot_aprendices_activos,
                val_duracion_programa = EXCLUDED.val_duracion_programa,
                id_nuevo_sector = EXCLUDED.id_nuevo_sector;

            contador := contador + 1;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Error en ficha %: %', r.id_ficha, SQLERRM;
        END;
    END LOOP;

    RETURN format('Procesadas %s filas de tab_temp_pe04', contador);
END;
$$ LANGUAGE plpgsql;


SELECT procesar_tab_temp_pe04();

