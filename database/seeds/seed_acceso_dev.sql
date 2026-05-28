-- Datos de desarrollo — módulo acceso SMARTCSET
-- Ejecutar después de bootstrap_modulo_acceso.sql

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

INSERT INTO tab_tipos_persona (id_tipo_persona, nom_tipo_persona, usr_insert, fec_insert) VALUES
    (1, 'Visitante', 'seed', NOW()),
    (2, 'Aprendiz', 'seed', NOW()),
    (3, 'Instructor', 'seed', NOW()),
    (99, 'Sin tipo', 'seed', NOW())
ON CONFLICT (id_tipo_persona) DO NOTHING;

INSERT INTO tab_metodos_aut (id_metodo_aut, nom_metodo_aut, usr_insert, fec_insert) VALUES
    (1, 'Registro manual', 'seed', NOW()),
    (2, 'Código QR', 'seed', NOW()),
    (3, 'Código de barras', 'seed', NOW())
ON CONFLICT (id_metodo_aut) DO NOTHING;

-- Cadena institucional mínima (V.1.5: tab_entradas_centro exige id_centro + id_sede)
INSERT INTO tab_regionales (
    id_regional, nom_regional, dir_regional, id_dpto, tel_regional,
    num_extension_tel, nom_director, usr_insert, fec_insert
) VALUES (
    '99', 'Regional desarrollo', 'Sin dirección', '00', 6010000000, 0, 'Seed', 'seed', NOW()
) ON CONFLICT (id_regional) DO NOTHING;

INSERT INTO tab_centros (
    id_centro, nom_centro, dir_centro, tel_centro, num_extension_tel,
    nom_subdirector, id_regional, usr_insert, fec_insert
) VALUES (
    9001, 'Centro desarrollo SMARTCSET', 'Sin dirección', 6010000001, 0,
    'Seed', '99', 'seed', NOW()
) ON CONFLICT (id_centro) DO NOTHING;

INSERT INTO tab_sedes (
    id_centro, id_sede, nom_sede, dir_sede, nom_encargado, tel_sede,
    usr_insert, fec_insert
) VALUES (
    9001, 1, 'Sede principal', 'Sin dirección', 'Seed', 6010000002, 'seed', NOW()
) ON CONFLICT (id_centro, id_sede) DO NOTHING;

INSERT INTO tab_entradas_centro (
    id_entrada_centro, nom_entrada_centro, id_centro, id_sede, usr_insert, fec_insert
) VALUES
    (1, 'Entrada principal', 9001, 1, 'seed', NOW()),
    (2, 'Entrada visitantes', 9001, 1, 'seed', NOW())
ON CONFLICT (id_entrada_centro) DO NOTHING;

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

-- Usuario portería (menús 0102/0103 vía migraciones)
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

-- Visitante de prueba
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
