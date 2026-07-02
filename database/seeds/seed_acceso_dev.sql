-- Datos operativos mínimos — módulo acceso / registro / portería SMARTCSET
-- Ejecutar después del schema (y, en producción, después de inserts SENA: regionales, centros, sedes, geo, profesiones).
-- Idempotente: ON CONFLICT DO NOTHING en todos los INSERT.
--
-- NO incluye: regionales, centros, sedes, catálogo DANE (dptos/ciudades masivos), profesiones SENA.
-- Solo sentinelas 00/00000 y profesión 00 cuando hace falta portería/visitante demo.

-- Sentinelas geográficas (no duplican el catálogo DANE; portería usa estos defaults en upsert mínimo)
INSERT INTO tab_dptos (id_dpto, nom_dpto, usr_insert, fec_insert)
VALUES ('00', 'Sin Departamento', 'seed', NOW())
ON CONFLICT (id_dpto) DO NOTHING;

INSERT INTO tab_ciudades (id_ciudad, nom_ciudad, id_dpto, usr_insert, fec_insert)
VALUES ('00000', 'Sin Ciudad', '00', 'seed', NOW())
ON CONFLICT (id_ciudad) DO NOTHING;

INSERT INTO tab_tipos_docum (id_tipo_docum, nom_tipo_docum, usr_insert, fec_insert) VALUES
    ('CC', 'Cédula de ciudadanía', 'seed', NOW()),
    ('CE', 'Cédula de extranjería', 'seed', NOW()),
    ('TI', 'Tarjeta de identidad', 'seed', NOW()),
    ('PA', 'Pasaporte', 'seed', NOW()),
    ('NIT', 'Número de identificación tributaria', 'seed', NOW()),
    ('SN', 'Sin tipo', 'seed', NOW()),
    ('PPT', 'Permiso por protección temporal', 'seed', NOW()),
    ('RC', 'Registro civil', 'seed', NOW()),
    ('PEP', 'Permiso especial de permanencia', 'seed', NOW())
ON CONFLICT (id_tipo_docum) DO NOTHING;

INSERT INTO tab_niveles_estudio (id_nivel_estudio, nom_nivel_estudio, usr_insert, fec_insert)
VALUES (99, 'Sin nivel', 'seed', NOW())
ON CONFLICT (id_nivel_estudio) DO NOTHING;

INSERT INTO tab_profesiones (id_profesion, nom_profesion, usr_insert, fec_insert)
VALUES ('00', 'Genérica', 'seed', NOW())
ON CONFLICT (id_profesion) DO NOTHING;

-- IDs alineados con listados admin (personasResolveTipoId por nombre)
INSERT INTO tab_tipos_persona (id_tipo_persona, nom_tipo_persona, usr_insert, fec_insert) VALUES
    (1, 'Visitante', 'seed', NOW()),
    (2, 'Aprendiz', 'seed', NOW()),
    (3, 'Instructor', 'seed', NOW()),
    (4, 'Funcionario', 'seed', NOW()),
    (5, 'Contratista', 'seed', NOW()),
    (99, 'Sin tipo', 'seed', NOW())
ON CONFLICT (id_tipo_persona) DO NOTHING;

INSERT INTO tab_metodos_aut (id_metodo_aut, nom_metodo_aut, usr_insert, fec_insert) VALUES
    (1, 'Registro manual', 'seed', NOW()),
    (2, 'Código QR', 'seed', NOW()),
    (3, 'Código de barras', 'seed', NOW()),
    (4, 'Biométrico facial', 'seed', NOW())
ON CONFLICT (id_metodo_aut) DO NOTHING;

-- Puertas del centro: solo si ya hay sedes (p. ej. tras inserts SENA) y aún no hay entradas
DO $$
DECLARE
    w_centro DECIMAL(4,0);
    w_sede   DECIMAL(1,0);
BEGIN
    IF EXISTS (SELECT 1 FROM tab_entradas_centro LIMIT 1) THEN
        RETURN;
    END IF;

    SELECT s.id_centro, s.id_sede
      INTO w_centro, w_sede
      FROM tab_sedes s
     ORDER BY s.id_centro, s.id_sede
     LIMIT 1;

    IF w_centro IS NULL THEN
        RAISE NOTICE 'seed_acceso_dev: sin tab_sedes; omitiendo tab_entradas_centro';
        RETURN;
    END IF;

    INSERT INTO tab_entradas_centro (id_entrada_centro, nom_entrada_centro, id_centro, id_sede, usr_insert, fec_insert)
    VALUES
        (1, 'Entrada principal', w_centro, w_sede, 'seed', NOW()),
        (2, 'Entrada visitantes', w_centro, w_sede, 'seed', NOW())
    ON CONFLICT (id_entrada_centro) DO NOTHING;
END $$;

-- Usuario demo: admin.smart / AdminSmart2026!
INSERT INTO tab_usuarios (
    id_usuario, nom_usuario, pass_usuario, mail_usuario,
    ind_usuario, ind_estado, usr_insert, fec_insert
) VALUES (
    'admin.smart',
    'Administrador SMARTCSET',
    '$2y$12$hiMIJY0gO3kRI8qP1B05/eGyiqNbAsINzcCoi3n18GAYAJdLgY1fS',
    'admin@cset.sena.edu.co',
    TRUE,
    TRUE,
    'seed',
    NOW()
) ON CONFLICT (id_usuario) DO NOTHING;

-- Usuario portería: porteria / Porteria2026!
INSERT INTO tab_usuarios (
    id_usuario, nom_usuario, pass_usuario, mail_usuario,
    ind_usuario, ind_estado, usr_insert, fec_insert
) VALUES (
    'porteria',
    'Usuario Portería',
    '$2y$12$51zVarrVv5NAwGTIoa7WEuMqmHk7HmSLhhKb396GIrDDYFTEAN39y',
    'porteria@cset.sena.edu.co',
    FALSE,
    TRUE,
    'seed',
    NOW()
) ON CONFLICT (id_usuario) DO NOTHING;

-- Visitante de prueba (usa sentinelas; no depende de catálogo DANE cargado)
INSERT INTO tab_personas (
    id_persona, id_tipo_docum, id_tipo_persona, nom_persona, ape_persona,
    mail_persona, ind_genero, fec_ultima_entrada, fec_ultima_salida,
    id_nivel_estudio, id_profesion, id_dpto_reside, id_ciudad_reside,
    dir_ciudad_reside, tel_persona_fijo, tel_persona_movil,
    nom_contacto_emergencias, tel_contacto_emergencias,
    usr_insert, fec_insert
) VALUES (
    1234567890, 'CC', 1, 'Juan', 'Pérez Demo',
    'juan.demo@cset.sena.edu.co', 99,
    '1900-01-01', '1900-01-01',
    99, '00', '00', '00000',
    'Calle 1 # 2-3', 6012345678, 3001234567,
    'Contacto Demo', 3009876543,
    'seed', NOW()
) ON CONFLICT (id_persona) DO NOTHING;

-- Cargos demo (FK tab_funcionarios)
INSERT INTO tab_cargos (id_cargo, nom_cargo, usr_insert, fec_insert)
VALUES
    (98, 'Asistente administrativo demo', 'seed', NOW()),
    (99, 'Coordinador demo desarrollo', 'seed', NOW())
ON CONFLICT (id_cargo) DO NOTHING;

-- Áreas demo: requiere al menos un centro existente (no inserta centros/sedes)
DO $$
DECLARE
    w_centro DECIMAL(4,0);
BEGIN
    SELECT c.id_centro
      INTO w_centro
      FROM tab_centros c
     ORDER BY c.id_centro
     LIMIT 1;

    IF w_centro IS NULL THEN
        RAISE NOTICE 'seed_acceso_dev: sin tab_centros; omitiendo tab_areas demo';
        RETURN;
    END IF;

    INSERT INTO tab_areas (
        id_area, nom_area, id_centro, nom_encargado, tel_area, usr_insert, fec_insert
    ) VALUES
        (98, 'Área administrativa demo', w_centro, 'Encargado Demo', 6010000001, 'seed', NOW()),
        (99, 'Área registro demo', w_centro, 'Encargado Demo', 6010000001, 'seed', NOW())
    ON CONFLICT (id_area) DO NOTHING;
END $$;

-- tab_fichas.id_centro DECIMAL(2,0) no admite centros SENA (9101+); ampliar una sola vez en DEV
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_fichas'
           AND column_name = 'id_centro'
           AND numeric_precision = 2
    ) THEN
        ALTER TABLE tab_fichas ALTER COLUMN id_centro TYPE DECIMAL(4,0);
    END IF;
END $$;

-- Fichas abiertas demo: dependencias mínimas; usa centro/sede/programa/instructor existentes si hay
DO $$
DECLARE
    w_centro        DECIMAL(4,0);
    w_sede          DECIMAL(1,0);
    w_programa      DECIMAL(8,0);
    w_instructor    DECIMAL(10,0);
    w_ciudad        VARCHAR;
BEGIN
    IF EXISTS (
        SELECT 1 FROM tab_fichas
         WHERE id_ficha IN (2999900001, 2999900002) AND ind_abierta = TRUE
    ) THEN
        RETURN;
    END IF;

    SELECT c.id_centro, s.id_sede
      INTO w_centro, w_sede
      FROM tab_centros c
      JOIN tab_sedes s ON s.id_centro = c.id_centro
     ORDER BY c.id_centro, s.id_sede
     LIMIT 1;

    IF w_centro IS NULL THEN
        RAISE NOTICE 'seed_acceso_dev: sin tab_centros/tab_sedes; omitiendo fichas demo';
        RETURN;
    END IF;

    SELECT id_programa INTO w_programa FROM tab_programas ORDER BY id_programa LIMIT 1;
    IF w_programa IS NULL THEN
        INSERT INTO tab_programas (
            id_programa, nom_programa, num_snies, num_version, ind_tipo,
            val_duracion_lect_hrs, val_duracion_prod_hrs, val_duracion_lect_mes, val_duracion_prod_me,
            usr_insert, fec_insert
        ) VALUES (
            29999001, 'Programa demo SmartCSET DEV', 'NA', 1, '1',
            24, 24, 12, 12, 'seed', NOW()
        ) ON CONFLICT (id_programa) DO NOTHING;
        w_programa := 29999001;
    END IF;

    SELECT id_instructor INTO w_instructor FROM tab_instructores ORDER BY id_instructor LIMIT 1;
    IF w_instructor IS NULL THEN
        INSERT INTO tab_redes (id_red, nom_red, nom_lider, usr_insert, fec_insert)
        VALUES (99, 'Red demo DEV', 'Líder Demo', 'seed', NOW())
        ON CONFLICT (id_red) DO NOTHING;

        INSERT INTO tab_instructores (
            id_instructor, id_centro, ind_tipo_contrato, ind_contratado_actual,
            ind_genero, ind_est_civil, id_nivel_estudio, id_profesion, id_red,
            ind_disponibilidad, ind_estado, usr_insert, fec_insert
        ) VALUES (
            2999900001, w_centro, TRUE, TRUE,
            2, 2, 99, '00', 99,
            TRUE, 0, 'seed', NOW()
        ) ON CONFLICT (id_instructor) DO NOTHING;
        w_instructor := 2999900001;
    END IF;

    INSERT INTO tab_sectores (id_sector, nom_sector, usr_insert, fec_insert)
    VALUES (0, 'Sin Sector', 'seed', NOW())
    ON CONFLICT (id_sector) DO NOTHING;

    INSERT INTO tab_empresas (id_empresa, id_tipo_docum, nom_empresa, usr_insert, fec_insert)
    VALUES (999, 'SN', 'Sin Empresa', 'seed', NOW())
    ON CONFLICT (id_empresa) DO NOTHING;

    INSERT INTO tab_ocupaciones (id_ocupacion, nom_ocupacion, usr_insert, fec_insert)
    VALUES (0, 'Sin ocupación definida', 'seed', NOW())
    ON CONFLICT (id_ocupacion) DO NOTHING;

    INSERT INTO tab_prog_especiales (id_prog_especial, nom_prog_especial, usr_insert, fec_insert)
    VALUES (0, 'Sin programa especial', 'seed', NOW())
    ON CONFLICT (id_prog_especial) DO NOTHING;

    w_ciudad := COALESCE(
        (SELECT id_ciudad FROM tab_ciudades WHERE id_dpto <> '00' ORDER BY id_ciudad LIMIT 1),
        '00000'
    );

    INSERT INTO tab_ambientes (
        id_ambiente, nom_ambiente, id_centro, id_sede,
        inventario_ambiente, equipos_ambiente, usr_insert, fec_insert
    ) VALUES (
        'Sin Ambiente Base', 'Ambiente base demo DEV', w_centro, w_sede,
        ROW(FALSE, 0, FALSE, FALSE, FALSE, FALSE, 20)::inv_ambiente,
        NULL, 'seed', NOW()
    ) ON CONFLICT (id_ambiente) DO NOTHING;

    INSERT INTO tab_fichas (
        id_ficha, id_centro, id_programa, id_nivel_estudio,
        id_jornada, ind_modalidad, fec_inicio, fec_fin_lectiva, fec_fin_productiva,
        val_duracion, id_instructor_lider, id_sector, id_empresa, id_ocupacion, id_ciudad,
        cod_convenio, nom_convenio, ind_amp_cobertura, id_prog_especial, ind_abierta,
        nom_vocero, tel_vocero, mail_vocero, val_cupo, id_ambiente_base,
        num_inscritos_opcion1, num_inscritos_opcion2, ind_estado, num_cursos,
        tot_aprendices_masc, tot_aprendices_fem, tot_aprendices_nobin, tot_aprendices_trans,
        tot_horas_planta, tot_horas_contratista, tot_horas_contrat_ext,
        tot_horas_monitores, tot_horas_inst_empresa,
        tot_aprendices_activos, val_duracion_programa, id_nuevo_sector,
        usr_insert, fec_insert
    ) VALUES
        (
            2999900001, w_centro, w_programa, 99,
            1, 1, CURRENT_DATE, CURRENT_DATE + 180, CURRENT_DATE + 365,
            12, w_instructor, 0, 999, 0, w_ciudad,
            0, 'Sin Convenio', FALSE, 0, TRUE,
            'Vocero Demo', 3001234567, 'vocero.demo@cset.sena.edu.co', 30, 'Sin Ambiente Base',
            0, 0, 3, 1,
            0, 0, 0, 0,
            '00:00:00', '00:00:00', '00:00:00', '00:00:00', '00:00:00',
            0, INTERVAL '12 months', 0,
            'seed', NOW()
        ),
        (
            2999900002, w_centro, w_programa, 99,
            2, 1, CURRENT_DATE, CURRENT_DATE + 180, CURRENT_DATE + 365,
            12, w_instructor, 0, 999, 0, w_ciudad,
            0, 'Sin Convenio', FALSE, 0, TRUE,
            'Vocero Demo Dos', 3001234568, 'vocero2.demo@cset.sena.edu.co', 25, 'Sin Ambiente Base',
            0, 0, 3, 1,
            0, 0, 0, 0,
            '00:00:00', '00:00:00', '00:00:00', '00:00:00', '00:00:00',
            0, INTERVAL '12 months', 0,
            'seed', NOW()
        )
    ON CONFLICT (id_ficha) DO NOTHING;
END $$;
