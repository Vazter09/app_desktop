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
    'assets/img/logo-sena.png',
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
    ('0101', 'Entradas', '01', 'pages/modulos/entradas/index.php', 'seed', NOW()),
    ('0102', 'Registro ingreso', '01', 'pages/modulos/porteria/ingreso/index.php', 'seed', NOW()),
    ('0103', 'Registro salida', '01', 'pages/modulos/porteria/salida/index.php', 'seed', NOW()),
    ('02', 'Administración', '00', 'no_aplica', 'seed', NOW()),
    ('0201', 'Usuarios', '02', 'pages/usuarios/usuarios.php', 'seed', NOW()),
    ('0202', 'Menús', '02', 'pages/menu/menus.php', 'seed', NOW()),
    ('0203', 'Accesos', '02', 'pages/menu/menu_usuarios.php', 'seed', NOW()),
    ('0204', 'Copiar perfil', '02', 'pages/menu/copiar_menu_usuarios.php', 'seed', NOW()),
    ('0206', 'Auditoría sesiones', '02', 'pages/admin/sesiones/index.php', 'seed', NOW()),
    ('04', 'Configuración', '00', 'no_aplica', 'seed', NOW()),
    ('0401', 'Config. sistema', '04', 'pages/admin/configuracion.php', 'seed', NOW()),
    ('0402', 'Config. módulo', '04', 'pages/admin/personas/config.php', 'seed', NOW()),
    ('03', 'Personas', '00', 'no_aplica', 'seed', NOW()),
    ('0300', 'Panel registro', '03', 'pages/modulos/registro/index.php', 'seed', NOW()),
    ('0301', 'Aprendices', '03', 'pages/admin/personas/aprendices/index.php', 'seed', NOW()),
    ('0302', 'Instructores', '03', 'pages/admin/personas/instructores/index.php', 'seed', NOW()),
    ('0303', 'Funcionarios', '03', 'pages/admin/personas/funcionarios/index.php', 'seed', NOW()),
    ('0304', 'Contratistas', '03', 'pages/admin/personas/contratistas/index.php', 'seed', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;
