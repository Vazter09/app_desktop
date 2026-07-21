/*
============================================================================================
  SCRIPT PARA CARGAR FICHAS DESDE LA TABLA TEMPORAL PE04 (PROCESO PE04)
============================================================================================
  OBJETIVO:
    Procesa los datos de fichas desde la tabla temporal tab_temp_pe04 y los distribuye
    en las tablas maestras y de fichas del sistema:
      - tab_niveles_estudio      (niveles de estudio)
      - tab_sectores             (sectores productivos)
      - tab_empresas             (empresas)
      - tab_prog_especiales      (programas especiales)
      - tab_ocupaciones          (ocupaciones)
      - tab_programas            (programas de formación)
      - tab_fichas               (fichas de formación)

  DEPENDENCIAS:
    - Extensión unaccent (para normalizar textos en comparaciones)
    - Tabla origen: tab_temp_pe04
    - Tablas destino: tab_niveles_estudio, tab_sectores, tab_empresas,
      tab_prog_especiales, tab_ocupaciones, tab_programas, tab_fichas
    - Tabla auxiliar: tab_ciudades (para obtener id_ciudad desde nom_municipio)
    - La secuencia seq_id_sector debe existir (se crea si no existe)

  AUTOR:          Grupo SMARTCSET
  FECHA:          2026-07-17
  VERSIÓN:        1.0
============================================================================================
*/
CREATE OR REPLACE FUNCTION fun_procesar_pe04()
RETURNS TABLE (insertados INTEGER, actualizados INTEGER, errores INTEGER) AS
$$
DECLARE
    -- Variables para datos de la ficha
    r                RECORD;
    v_contador       INTEGER := 0;      -- Contador de fichas procesadas (solo inserciones/actualizaciones exitosas)
    v_error_count    INTEGER := 0;      -- Contador de errores

    -- Contadores globales
    v_insertados     INTEGER := 0;
    v_actualizados   INTEGER := 0;
    v_errores        INTEGER := 0;

    -- Variables auxiliares
    v_filas          INTEGER;
BEGIN
    /*
     ====================================================================
      PASO 0: GARANTIZAR LA EXISTENCIA DE LA SECUENCIA PARA id_sector
     ====================================================================
     */
    CREATE SEQUENCE IF NOT EXISTS seq_id_sector START 1;

    /*
     ====================================================================
      PASO 1: CARGA MASIVA DE TABLAS MAESTRAS (CON DISTINCT ON)
     ====================================================================
      Se cargan las tablas maestras usando DISTINCT ON para evitar
      duplicados y ON CONFLICT para manejar inserciones/actualizaciones.
     */

    -- 1.1 Asegurar registro por defecto para programas especiales (id=0)
    INSERT INTO tab_prog_especiales (id_prog_especial, nom_prog_especial)
    VALUES (0, 'Sin programa especial')
    ON CONFLICT (id_prog_especial) DO NOTHING;

    -- 1.2 Cargar niveles de estudio
    INSERT INTO tab_niveles_estudio (id_nivel_estudio, nom_nivel_estudio)
    SELECT DISTINCT ON (id_nivel_forma) id_nivel_forma, nom_nivel_forma
    FROM tab_temp_pe04
    WHERE id_nivel_forma IS NOT NULL
    ORDER BY id_nivel_forma, nom_nivel_forma
    ON CONFLICT (id_nivel_estudio) DO UPDATE SET nom_nivel_estudio = EXCLUDED.nom_nivel_estudio;

    -- 1.3 Cargar sectores (con conversión a DECIMAL)
    INSERT INTO tab_sectores (id_sector, nom_sector)
    SELECT DISTINCT ON (id_sector_prog) id_sector_prog::DECIMAL(4,0), nom_sector_prog
    FROM tab_temp_pe04
    WHERE id_sector_prog IS NOT NULL
    ORDER BY id_sector_prog, nom_sector_prog
    ON CONFLICT (id_sector) DO UPDATE SET nom_sector = EXCLUDED.nom_sector;

    -- 1.4 Cargar empresas (con valor por defecto 999 para 'Sin Empresa')
    INSERT INTO tab_empresas (id_empresa, id_tipo_docum, nom_empresa)
    SELECT DISTINCT ON (COALESCE(id_empresa, 999))
        COALESCE(id_empresa, 999),
        CASE WHEN id_empresa IS NULL THEN 'SN' ELSE 'NIT' END,
        COALESCE(nom_empresa, 'Sin Empresa')
    FROM tab_temp_pe04
    ORDER BY COALESCE(id_empresa, 999), nom_empresa
    ON CONFLICT (id_empresa) DO UPDATE SET
        id_tipo_docum = EXCLUDED.id_tipo_docum,
        nom_empresa = EXCLUDED.nom_empresa;

    -- 1.5 Cargar programas especiales (con valor por defecto 0)
    INSERT INTO tab_prog_especiales (id_prog_especial, nom_prog_especial)
    SELECT DISTINCT ON (COALESCE(NULLIF(id_prog_especial, 0), 0))
        COALESCE(NULLIF(id_prog_especial, 0), 0),
        COALESCE(NULLIF(nom_prog_especial, ''), 'Sin programa especial')
    FROM tab_temp_pe04
    ORDER BY COALESCE(NULLIF(id_prog_especial, 0), 0), nom_prog_especial
    ON CONFLICT (id_prog_especial) DO UPDATE SET nom_prog_especial = EXCLUDED.nom_prog_especial;

    -- 1.6 Cargar ocupaciones
    INSERT INTO tab_ocupaciones (id_ocupacion, nom_ocupacion)
    SELECT DISTINCT ON (id_ocupacion) id_ocupacion, COALESCE(nom_ocupacion, 'OCUPACION DESCONOCIDA')
    FROM tab_temp_pe04
    WHERE id_ocupacion IS NOT NULL
    ORDER BY id_ocupacion, nom_ocupacion
    ON CONFLICT (id_ocupacion) DO UPDATE SET nom_ocupacion = EXCLUDED.nom_ocupacion;

    -- 1.7 Cargar programas de formación (con versión por defecto)
    INSERT INTO tab_programas (id_programa, nom_programa, num_version)
    SELECT DISTINCT ON (id_programa)
        id_programa,
        nom_programa,
        CASE WHEN id_version IS NULL OR id_version > 99 THEN 1 ELSE id_version END
    FROM tab_temp_pe04
    WHERE id_programa IS NOT NULL
    ORDER BY id_programa, id_version DESC NULLS LAST
    ON CONFLICT (id_programa) DO UPDATE SET
        nom_programa = EXCLUDED.nom_programa,
        num_version = EXCLUDED.num_version;

    /*
     ====================================================================
      PASO 2: BUCLE PRINCIPAL PARA CARGAR tab_fichas
     ====================================================================
      Se recorren los registros de la tabla temporal, se calculan valores
      derivados (fechas, duración, id_ciudad, id_sector) y se insertan
      o actualizan en tab_fichas.
     */
    FOR r IN (
        SELECT
            t.*,
            -- Cálculo de id_ciudad a partir de nom_municipio (usando unaccent)
            COALESCE(c.id_ciudad, '68001') AS id_ciudad_calc,
            -- Cálculo de id_nuevo_sector a partir de nom_nuevo_sector
            COALESCE(s.id_sector, 0) AS id_nuevo_sector_calc,
            -- Fechas de inicio y fin (con valores por defecto)
            COALESCE(t.fec_inicio_ficha, CURRENT_DATE) AS fec_inicio_calc,
            COALESCE(t.fec_fin_ficha, CURRENT_DATE + INTERVAL '1 year') AS fec_fin_calc,
            -- Cálculo de duración en meses (máximo 99)
            LEAST(
                EXTRACT(MONTH FROM age(
                    COALESCE(t.fec_fin_ficha, CURRENT_DATE + INTERVAL '1 year'),
                    COALESCE(t.fec_inicio_ficha, CURRENT_DATE)
                )) + 12 * EXTRACT(YEAR FROM age(
                    COALESCE(t.fec_fin_ficha, CURRENT_DATE + INTERVAL '1 year'),
                    COALESCE(t.fec_inicio_ficha, CURRENT_DATE)
                )),
                99
            )::DECIMAL(2,0) AS diff_months_calc
        FROM tab_temp_pe04 t
        LEFT JOIN tab_ciudades c
            ON unaccent(lower(c.nom_ciudad)) = unaccent(lower(t.nom_municipio))
        LEFT JOIN tab_sectores s
            ON unaccent(lower(s.nom_sector)) = unaccent(lower(TRIM(t.nom_nuevo_sector)))
    ) LOOP
        BEGIN
            -- 2.1 Insertar o actualizar en tab_fichas
            INSERT INTO tab_fichas (
                id_ficha, id_centro, id_programa, id_nivel_estudio, id_jornada,
                ind_modalidad, fec_inicio, fec_fin_productiva, val_duracion,
                id_instructor_lider, id_sector, id_empresa, id_ocupacion,
                id_ciudad, cod_convenio, nom_convenio, ind_amp_cobertura,
                id_prog_especial, ind_abierta, nom_vocero, tel_vocero,
                mail_vocero, val_cupo, id_ambiente_base, num_inscritos_opcion1,
                num_inscritos_opcion2, ind_estado, num_cursos,
                tot_aprendices_masc, tot_aprendices_fem, tot_aprendices_nobin,
                tot_aprendices_trans, tot_horas_planta, tot_horas_contratista,
                tot_horas_contrat_ext, tot_horas_monitores, tot_horas_inst_empresa,
                tot_aprendices_activos, val_duracion_programa, id_nuevo_sector
            ) VALUES (
                r.id_ficha,
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
                r.fec_inicio_calc,
                r.fec_fin_calc,
                r.diff_months_calc,
                77777777,  -- id_instructor_lider por defecto (ajustar según lógica)
                COALESCE(r.id_sector_prog, 0)::DECIMAL(4,0),
                COALESCE(r.id_empresa, 999),
                COALESCE(r.id_ocupacion, 0),
                r.id_ciudad_calc,
                COALESCE(r.id_convenio, 0),
                COALESCE(r.nom_convenio, 'Sin Convenio'),
                FALSE,     -- ind_amp_cobertura
                COALESCE(NULLIF(r.id_prog_especial, 0), 0),
                FALSE,     -- ind_abierta
                'Sin Vocero',
                '3000000000',
                'sin_correo@correo.com',
                COALESCE(r.num_tot_aprend, 30),
                'Sin Ambiente Base',
                0, 0,      -- num_inscritos_opcion1 y opcion2
                CASE UPPER(TRIM(r.ind_estado_curso))
                    WHEN 'INSCRIPCION' THEN 1
                    WHEN 'MATRICULA' THEN 2
                    WHEN 'EN EJECUCION' THEN 3
                    WHEN 'TERMINADA' THEN 7
                    WHEN 'CERRADA' THEN 8
                    ELSE 9
                END,
                COALESCE(r.num_cursos, 1),
                GREATEST(COALESCE(r.num_aprend_masc, 0), 0),
                GREATEST(COALESCE(r.num_aprend_fem, 0), 0),
                GREATEST(COALESCE(r.num_aprend_nobin, 0), 0),
                0,         -- tot_aprendices_trans (sin datos)
                COALESCE(r.val_hrs_planta, '00:00:00'::INTERVAL),
                COALESCE(r.val_hrs_contrat, '00:00:00'::INTERVAL),
                COALESCE(r.val_hrs_context, '00:00:00'::INTERVAL),
                COALESCE(r.val_hrs_monitor, '00:00:00'::INTERVAL),
                COALESCE(r.val_hrs_instemp, '00:00:00'::INTERVAL),
                GREATEST(COALESCE(r.val_total_apr_act, 0), 0),
                -- Duración del programa en meses, días y horas
                make_interval(
                    months => (COALESCE(r.val_duracion_prog, 0)::INT / 24) / 30,
                    days => (COALESCE(r.val_duracion_prog, 0)::INT / 24) % 30,
                    hours => COALESCE(r.val_duracion_prog, 0)::INT % 24
                ),
                COALESCE(r.id_nuevo_sector_calc, 0)
            )
            ON CONFLICT (id_ficha) DO UPDATE SET
                id_centro = EXCLUDED.id_centro,
                id_programa = EXCLUDED.id_programa,
                id_nivel_estudio = EXCLUDED.id_nivel_estudio,
                id_jornada = EXCLUDED.id_jornada,
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

            -- 2.2 Contar inserciones/actualizaciones exitosas
            GET DIAGNOSTICS v_filas = ROW_COUNT;
            IF v_filas = 1 THEN
                IF EXISTS (SELECT 1 FROM tab_fichas WHERE id_ficha = r.id_ficha AND fec_update IS NULL) THEN
                    v_insertados := v_insertados + 1;
                ELSE
                    v_actualizados := v_actualizados + 1;
                END IF;
            END IF;

            v_contador := v_contador + 1;

        -- 2.3 Manejo de errores por ficha
        EXCEPTION
            WHEN OTHERS THEN
                v_errores := v_errores + 1;
                v_error_count := v_error_count + 1;
                RAISE WARNING 'Error en ficha % (SQLSTATE %): %', r.id_ficha, SQLSTATE, SQLERRM;
        END;
    END LOOP;

    -- Retornar resumen consolidado
    RETURN QUERY SELECT v_insertados, v_actualizados, v_errores;
END;
$$ LANGUAGE plpgsql;

-- ===========================================================================
-- NOTAS ADICIONALES PARA EL ADMINISTRADOR:
-- ===========================================================================
-- 1. Antes de ejecutar, verificar que la extensión unaccent esté instalada:
--      CREATE EXTENSION IF NOT EXISTS unaccent;
--
-- 2. La secuencia seq_id_sector se crea automáticamente si no existe.
--    Se utiliza para generar ids de sector si no se proporcionan.
--
-- 3. Esta función es idempotente: puede ejecutarse varias veces sin generar
--    duplicados (ON CONFLICT).
--
-- 4. Los errores se registran como WARNING; revisar el log de PostgreSQL
--    después de cada ejecución para corregir datos problemáticos.
--
-- 5. La función utiliza la tabla tab_ciudades para mapear nom_municipio a id_ciudad.
--    Si no existe coincidencia, se asigna '68001' (Bucaramanga) como valor por defecto.
--
-- 6. Para ejecutar:
--      SELECT * FROM fun_procesar_pe04();
--    Ejemplo de salida:
--      insertados | actualizados | errores
--     ------------+--------------+---------
--              50 |           10 |       0
-- ===========================================================================