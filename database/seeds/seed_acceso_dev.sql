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
    ('SN', 'Sin tipo', 'seed', NOW())
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
    (3, 'Código de barras', 'seed', NOW())
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
