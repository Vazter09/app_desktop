-- Extension de pgsql para normalizar el nombre de las ciudades.
CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE SEQUENCE IF NOT EXISTS seq_id_sector START 1;

-- Crear tabla de logging (si no existe)
CREATE TABLE IF NOT EXISTS log_migracion_pe04 (
    id_log          SERIAL PRIMARY KEY,
    fecha_log       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tabla_destino   VARCHAR(50),
    operacion       VARCHAR(10),
    id_registro     VARCHAR(100),
    observacion     TEXT
);

-- Funciones para cargar en las distintas tablas.
CREATE OR REPLACE FUNCTION fun_migrar_sectores()
RETURNS VOID AS $$
BEGIN
    INSERT INTO tab_sectores (id_sector, nom_sector, usr_insert, fec_insert)
    SELECT nextval('seq_id_sector'), nom_sector_prog, 'MIGRACION_PE04', CURRENT_TIMESTAMP
    FROM (SELECT DISTINCT nom_sector_prog FROM tab_temp_pe04 WHERE nom_sector_prog IS NOT NULL) src
    WHERE NOT EXISTS (SELECT 1 FROM tab_sectores t WHERE t.nom_sector = src.nom_sector_prog);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fun_migrar_ocupaciones()
RETURNS VOID AS $$
BEGIN
    INSERT INTO tab_ocupaciones (id_ocupacion, nom_ocupacion, usr_insert, fec_insert)
    SELECT DISTINCT id_ocupacion, nom_ocupacion, 'MIGRACION_PE04', CURRENT_TIMESTAMP
    FROM tab_temp_pe04
    WHERE id_ocupacion IS NOT NULL
    ON CONFLICT (id_ocupacion) DO UPDATE
    SET nom_ocupacion = EXCLUDED.nom_ocupacion,
        usr_update = 'MIGRACION_PE04',
        fec_update = CURRENT_TIMESTAMP
    WHERE tab_ocupaciones.nom_ocupacion IS DISTINCT FROM EXCLUDED.nom_ocupacion;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fun_migrar_empresas()
RETURNS VOID AS $$
BEGIN
    INSERT INTO tab_empresas (id_empresa, id_tipo_docum, nom_empresa, usr_insert, fec_insert)
    SELECT DISTINCT
        e.id_empresa,
        COALESCE(t.id_tipo_docum, 'NIT') AS id_tipo_docum,  -- Cambiado de 'N/A' a 'NIT'
        COALESCE(e.nom_empresa, 'Sin Empresa'),
        'MIGRACION_PE04',
        CURRENT_TIMESTAMP
    FROM tab_temp_pe04 e
    LEFT JOIN tab_tipos_docum t ON t.id_tipo_docum = e.id_tipodoc_emp
    WHERE e.id_empresa IS NOT NULL
    ON CONFLICT (id_empresa) DO UPDATE
    SET id_tipo_docum = EXCLUDED.id_tipo_docum,
        nom_empresa = EXCLUDED.nom_empresa,
        usr_update = 'MIGRACION_PE04',
        fec_update = CURRENT_TIMESTAMP;

    -- Log de empresas con tipo documento por defecto (ahora 'NIT')
    INSERT INTO log_migracion_pe04 (tabla_destino, operacion, id_registro, observacion)
    SELECT 'tab_empresas', 'WARNING', id_empresa, 'Tipo documento no existe, se asignó NIT'
    FROM tab_temp_pe04
    WHERE id_empresa IS NOT NULL
      AND id_tipodoc_emp IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM tab_tipos_docum WHERE id_tipo_docum = tab_temp_pe04.id_tipodoc_emp);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fun_migrar_prog_especiales()
RETURNS VOID AS $$
BEGIN
    -- Insertar o actualizar solo programas especiales con id != 0 (el 0 ya existe por defecto)
    INSERT INTO tab_prog_especiales (id_prog_especial, nom_prog_especial, usr_insert, fec_insert)
    SELECT DISTINCT 
        id_prog_especial, 
        COALESCE(NULLIF(TRIM(nom_prog_especial), ''), 'Sin programa especial') AS nom_prog_especial,
        'MIGRACION_PE04', 
        CURRENT_TIMESTAMP
    FROM tab_temp_pe04
    WHERE id_prog_especial IS NOT NULL 
      AND id_prog_especial != 0   -- Excluir el id por defecto, que ya existe en la tabla
    ON CONFLICT (id_prog_especial) DO UPDATE
    SET nom_prog_especial = EXCLUDED.nom_prog_especial,
        usr_update = 'MIGRACION_PE04',
        fec_update = CURRENT_TIMESTAMP
    WHERE tab_prog_especiales.nom_prog_especial IS DISTINCT FROM EXCLUDED.nom_prog_especial;

    -- Registrar advertencias cuando el nombre original era nulo o vacío (excepto para id=0)
    INSERT INTO log_migracion_pe04 (tabla_destino, operacion, id_registro, observacion)
    SELECT 'tab_prog_especiales', 'WARNING', id_prog_especial, 
           'nom_prog_especial era nulo o vacío, se asignó "Sin programa especial"'
    FROM tab_temp_pe04
    WHERE id_prog_especial IS NOT NULL 
      AND id_prog_especial != 0
      AND (nom_prog_especial IS NULL OR TRIM(nom_prog_especial) = '');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fun_migrar_fichas()
RETURNS VOID AS $$
BEGIN
    INSERT INTO tab_fichas (
        id_ficha, id_centro, id_programa, id_nivel_estudio, ind_jornada,
        ind_modalidad, fec_inicio, fec_fin_productiva, val_duracion,
        id_instructor_lider, id_sector, id_empresa, id_ocupacion, id_ciudad,
        cod_convenio, nom_convenio, ind_amp_cobertura, id_prog_especial,
        ind_abierta, nom_vocero, tel_vocero, mail_vocero, val_cupo,
        id_ambiente_base, num_inscritos_opcion1, num_inscritos_opcion2, ind_estado,
        num_cursos, tot_aprendices_masc, tot_aprendices_fem, tot_aprendices_nobin,
        tot_aprendices_trans, tot_horas_planta, tot_horas_contratista,
        tot_horas_contrat_ext, tot_horas_monitores, tot_horas_inst_empresa,
        tot_aprendices_activos, val_duracion_programa, id_nuevo_sector,
        usr_insert, fec_insert
    )
    SELECT
        t.id_ficha,
        COALESCE(c.id_centro, 1) AS id_centro,
        t.id_programa,
        COALESCE(t.id_nivel_forma, 99) AS id_nivel_estudio,
        COALESCE(t.id_jornada, 1) AS ind_jornada,
        CASE UPPER(TRIM(t.val_modalidad))
            WHEN 'PRESENCIAL' THEN 1
            WHEN 'VIRTUAL' THEN 2
            WHEN 'DISTANCIA' THEN 3
            ELSE 1
        END AS ind_modalidad,
        t.fec_inicio_ficha,
        t.fec_fin_ficha,
        COALESCE(t.val_duracion_prog, 0) AS val_duracion,
        77777777 AS id_instructor_lider,
        COALESCE(sec.id_sector, 0) AS id_sector,
        COALESCE(t.id_empresa, 999) AS id_empresa,
        COALESCE(t.id_ocupacion, 0) AS id_ocupacion,
        COALESCE(ciu.id_ciudad, '68001') AS id_ciudad,
        COALESCE(t.id_convenio, 0) AS cod_convenio,
        COALESCE(t.nom_convenio, 'Sin Convenio') AS nom_convenio,
        (UPPER(TRIM(t.ind_cobertura)) = 'SI') AS ind_amp_cobertura,
        COALESCE(t.id_prog_especial, 0) AS id_prog_especial,
        FALSE AS ind_abierta,
        'Sin Vocero' AS nom_vocero,
        3000000000 AS tel_vocero,
        'sin_correo@correo.com' AS mail_vocero,
        30 AS val_cupo,
        'Sin Ambiente Base' AS id_ambiente_base,
        0 AS num_inscritos_opcion1,
        0 AS num_inscritos_opcion2,
        CASE UPPER(TRIM(t.ind_estado_curso))
            WHEN 'TERMINADA' THEN 8
            WHEN 'EN EJECUCIÓN' THEN 3
            ELSE 1
        END AS ind_estado,
        COALESCE(t.num_cursos, 1) AS num_cursos,
        COALESCE(t.num_aprend_masc, 0) AS tot_aprendices_masc,
        COALESCE(t.num_aprend_fem, 0) AS tot_aprendices_fem,
        COALESCE(t.num_aprend_nobin, 0) AS tot_aprendices_nobin,
        0 AS tot_aprendices_trans,
        COALESCE(t.val_hrs_planta, '0'::INTERVAL) AS tot_horas_planta,
        COALESCE(t.val_hrs_contrat, '0'::INTERVAL) AS tot_horas_contratista,
        COALESCE(t.val_hrs_context, '0'::INTERVAL) AS tot_horas_contrat_ext,
        COALESCE(t.val_hrs_monitor, '0'::INTERVAL) AS tot_horas_monitores,
        COALESCE(t.val_hrs_instemp, '0'::INTERVAL) AS tot_horas_inst_empresa,
        COALESCE(t.val_total_apr_act, 0) AS tot_aprendices_activos,
        make_interval(months => COALESCE(t.val_duracion_prog, 0)::INT) AS val_duracion_programa,
        COALESCE(ns.id_sector, 0) AS id_nuevo_sector,
        'MIGRACION_PE04' AS usr_insert,
        COALESCE(t.fecha_reporte, CURRENT_DATE) AS fec_insert
    FROM tab_temp_pe04 t
    LEFT JOIN tab_centros c ON c.id_centro = t.cod_centro   -- ← CORREGIDO
    LEFT JOIN tab_sectores sec ON sec.nom_sector = t.nom_sector_prog
    LEFT JOIN tab_ciudades ciu ON unaccent(LOWER(ciu.nom_ciudad)) = unaccent(LOWER(t.nom_municipio))
    LEFT JOIN tab_dptos dpt ON dpt.id_dpto = ciu.id_dpto AND unaccent(LOWER(dpt.nom_dpto)) = unaccent(LOWER(t.nom_depto))
    LEFT JOIN tab_sectores ns ON ns.nom_sector = t.nom_nuevo_sector
    ON CONFLICT (id_ficha) DO UPDATE SET
        fec_fin_productiva = EXCLUDED.fec_fin_productiva,
        tot_aprendices_activos = EXCLUDED.tot_aprendices_activos,
        ind_estado = EXCLUDED.ind_estado,
        tot_horas_planta = EXCLUDED.tot_horas_planta,
        tot_horas_contratista = EXCLUDED.tot_horas_contratista,
        tot_horas_contrat_ext = EXCLUDED.tot_horas_contrat_ext,
        tot_horas_monitores = EXCLUDED.tot_horas_monitores,
        tot_horas_inst_empresa = EXCLUDED.tot_horas_inst_empresa,
        tot_aprendices_masc = EXCLUDED.tot_aprendices_masc,
        tot_aprendices_fem = EXCLUDED.tot_aprendices_fem,
        tot_aprendices_nobin = EXCLUDED.tot_aprendices_nobin,
        num_cursos = EXCLUDED.num_cursos,
        id_ciudad = EXCLUDED.id_ciudad,
        usr_update = 'MIGRACION_PE04',
        fec_update = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;


-- Para ejecutar todas las funciones

CREATE OR REPLACE FUNCTION fun_migrar_pe04()
RETURNS TEXT AS $$
BEGIN
    PERFORM fun_migrar_sectores();
    PERFORM fun_migrar_ocupaciones();
    PERFORM fun_migrar_empresas();
    PERFORM fun_migrar_prog_especiales();
    PERFORM fun_migrar_fichas();
    RETURN 'Migración completada exitosamente. Revise log_migracion_pe04 para advertencias.';
END;
$$ LANGUAGE plpgsql;

BEGIN;
SELECT fun_migrar_pe04();
COMMIT;