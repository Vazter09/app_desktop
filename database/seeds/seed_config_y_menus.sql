-- Configuración del sistema y catálogo de menús (desarrollo / post-schema V.1.7)
-- Ejecutar después del schema y antes o junto con seed_acceso_dev + seed_menus_admin.
--
-- Uso manual:
--   psql -h HOST -U USER -d db_smartcset -f database/seeds/seed_config_y_menus.sql

-- Fila única de apariencia (colores, logo, tema)
INSERT INTO tab_config_sistema (
    id_config,
    ind_modulo_registro,
    ind_login_registro_standalone,
    nom_sistema,
    path_logo,
    color_primario,
    color_secundario,
    usr_registro,
    pass_registro_hash,
    usr_insert,
    fec_insert
) VALUES (
    1,
    TRUE,
    FALSE,
    'SmartCSET',
    'img/logo-sena.png',
    '#2E4731',
    '#6B8E23',
    'usuariocset',
    NULL,
    'seed',
    NOW()
) ON CONFLICT (id_config) DO NOTHING;

-- Catálogo de menús (rutas finales: migraciones update_modulos_rutas_organizadas, add_menu_config_y_registro)
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('01', 'Acceso', '00', 'no_aplica', 'seed', NOW()),
    ('0101', 'Entradas', '01', 'src/modulos/entradas/index.php', 'seed', NOW()),
    ('0102', 'Registro ingreso', '01', 'src/modulos/porteria/ingreso/index.php', 'seed', NOW()),
    ('0103', 'Registro salida', '01', 'src/modulos/porteria/salida/index.php', 'seed', NOW()),
    ('02', 'Administración', '00', 'no_aplica', 'seed', NOW()),
    ('0201', 'Usuarios', '02', 'src/usuarios/usuarios.php', 'seed', NOW()),
    ('0202', 'Menús', '02', 'src/menu/menus.php', 'seed', NOW()),
    ('0203', 'Accesos', '02', 'src/menu/menu_usuarios.php', 'seed', NOW()),
    ('0204', 'Copiar perfil', '02', 'src/menu/copiar_menu_usuarios.php', 'seed', NOW()),
    ('0205', 'Config. sistema', '02', 'src/admin/configuracion.php', 'seed', NOW()),
    ('03', 'Registro personas', '00', 'no_aplica', 'seed', NOW()),
    ('0300', 'Panel registro', '03', 'src/modulos/registro/index.php', 'seed', NOW()),
    ('0305', 'Config. registro', '03', 'src/admin/registro/config.php', 'seed', NOW()),
    ('0301', 'Aprendiz', '03', 'src/admin/registro/listado.php?menu=0301', 'seed', NOW()),
    ('0302', 'Instructor', '03', 'src/admin/registro/listado.php?menu=0302', 'seed', NOW()),
    ('0303', 'Funcionario', '03', 'src/admin/registro/listado.php?menu=0303', 'seed', NOW()),
    ('0304', 'Contratista', '03', 'src/admin/registro/listado.php?menu=0304', 'seed', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;
