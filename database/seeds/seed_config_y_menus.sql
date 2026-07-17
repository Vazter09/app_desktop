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
    'SISTEMA',
    NOW()
) ON CONFLICT (id_config) DO NOTHING;

-- Catálogo de menús (árbol SGI/SGA/SAA — ver reorganizacion_menus_tres_abuelos.sql)
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('10', 'SGI - Ingresos', '00', 'no_aplica', 'SISTEMA', NOW()),
    ('20', 'SGA - Administrativo', '00', 'no_aplica', 'SISTEMA', NOW()),
    ('30', 'SAA - Aprendiz', '00', 'no_aplica', 'SISTEMA', NOW()),
    ('101', 'Entradas', '10', 'pages/modulos/entradas/index.php', 'SISTEMA', NOW()),
    ('102', 'Registro ingreso', '10', 'pages/modulos/porteria/ingreso/index.php', 'SISTEMA', NOW()),
    ('103', 'Registro salida', '10', 'pages/modulos/porteria/salida/index.php', 'SISTEMA', NOW()),
    ('104', 'Datos estadísticos', '10', 'pages/modulos/en_construccion/estadisticos.php', 'SISTEMA', NOW()),
    ('201', 'Instructores', '20', 'no_aplica', 'SISTEMA', NOW()),
    ('20101', 'Listado instructores', '201', 'pages/admin/personas/instructores/index.php', 'SISTEMA', NOW()),
    ('20102', 'Contratos', '201', 'pages/modulos/en_construccion/contratos.php', 'SISTEMA', NOW()),
    ('20103', 'Disciplinario', '201', 'pages/modulos/en_construccion/disciplinario_instructor.php', 'SISTEMA', NOW()),
    ('20104', 'Gestión tiempos', '201', 'pages/modulos/en_construccion/gestion_tiempos.php', 'SISTEMA', NOW()),
    ('20105', 'Portafolios', '201', 'pages/modulos/en_construccion/portafolios_instructor.php', 'SISTEMA', NOW()),
    ('202', 'Aprendices', '20', 'no_aplica', 'SISTEMA', NOW()),
    ('20201', 'Listado aprendices', '202', 'pages/admin/personas/aprendices/index.php', 'SISTEMA', NOW()),
    ('20202', 'Certificaciones', '202', 'pages/modulos/en_construccion/certificaciones.php', 'SISTEMA', NOW()),
    ('20203', 'Disciplinario', '202', 'pages/modulos/en_construccion/disciplinario_aprendiz.php', 'SISTEMA', NOW()),
    ('20204', 'Juicios evaluativos', '202', 'pages/modulos/en_construccion/juicios_evaluativos.php', 'SISTEMA', NOW()),
    ('20205', 'Ruta académica', '202', 'pages/modulos/en_construccion/ruta_academica.php', 'SISTEMA', NOW()),
    ('20206', 'Portafolio', '202', 'pages/modulos/en_construccion/portafolio_aprendiz.php', 'SISTEMA', NOW()),
    ('20207', 'Caprendizaje', '202', 'pages/modulos/en_construccion/caprendizaje.php', 'SISTEMA', NOW()),
    ('203', 'Rutas', '20', 'no_aplica', 'SISTEMA', NOW()),
    ('20301', 'Consulta rutas', '203', 'pages/modulos/en_construccion/rutas_consulta.php', 'SISTEMA', NOW()),
    ('20302', 'Ruta CRUD', '203', 'pages/modulos/en_construccion/rutas_crud.php', 'SISTEMA', NOW()),
    ('204', 'Programas', '20', 'pages/modulos/en_construccion/programas.php', 'SISTEMA', NOW()),
    ('205', 'Novedades', '20', 'no_aplica', 'SISTEMA', NOW()),
    ('20501', 'Llamados', '205', 'pages/modulos/en_construccion/llamados.php', 'SISTEMA', NOW()),
    ('20502', 'Comités', '205', 'pages/modulos/en_construccion/comites.php', 'SISTEMA', NOW()),
    ('206', 'Mis Fichas', '20', 'no_aplica', 'SISTEMA', NOW()),
    ('20601', 'Las fichas del instructor', '206', 'pages/modulos/instructor/fichas/index.php', 'SISTEMA', NOW()),
    ('207', 'Personas', '20', 'no_aplica', 'SISTEMA', NOW()),
    ('20701', 'Panel registro', '207', 'pages/modulos/registro/index.php', 'SISTEMA', NOW()),
    ('20702', 'Funcionarios', '207', 'pages/admin/personas/funcionarios/index.php', 'SISTEMA', NOW()),
    ('20703', 'Contratistas', '207', 'pages/admin/personas/contratistas/index.php', 'SISTEMA', NOW()),
    ('208', 'Reportes SENA', '20', 'pages/admin/reportes/df49/index.php', 'SISTEMA', NOW()),
    ('20802', 'DF-53 Empresas', '208', 'pages/admin/reportes/df53/index.php', 'SISTEMA', NOW()),
    ('20803', 'DF-14A Estado', '208', 'pages/admin/reportes/df14a/index.php', 'SISTEMA', NOW()),
    ('20804', 'PE-04 Detalle', '208', 'pages/admin/reportes/pe04/index.php', 'SISTEMA', NOW()),
    ('20805', 'Aprendices', '208', 'pages/admin/reportes/aprendices/index.php', 'SISTEMA', NOW()),
    ('20806', 'Fichas creadas', '208', 'pages/admin/reportes/fichas_creadas/index.php', 'SISTEMA', NOW()),
    ('20807', 'Carga DF-51 Rutas', '208', 'pages/admin/reportes/df51/index.php', 'SISTEMA', NOW()),
    ('20808', 'Carga juicios evaluativos', '208', 'pages/admin/reportes/juicios/index.php', 'SISTEMA', NOW()),
    ('209', 'Administración', '20', 'no_aplica', 'SISTEMA', NOW()),
    ('20901', 'Usuarios', '209', 'pages/usuarios/usuarios.php', 'SISTEMA', NOW()),
    ('20902', 'Menús', '209', 'pages/menu/menus.php', 'SISTEMA', NOW()),
    ('20903', 'Accesos', '209', 'pages/menu/menu_usuarios.php', 'SISTEMA', NOW()),
    ('20904', 'Copiar perfil', '209', 'pages/menu/copiar_menu_usuarios.php', 'SISTEMA', NOW()),
    ('20905', 'Auditoría sesiones', '209', 'pages/admin/sesiones/index.php', 'SISTEMA', NOW()),
    ('210', 'Configuración', '20', 'no_aplica', 'SISTEMA', NOW()),
    ('21001', 'Config. sistema', '210', 'pages/admin/configuracion.php', 'SISTEMA', NOW()),
    ('21002', 'Config. módulo', '210', 'pages/admin/personas/config.php', 'SISTEMA', NOW()),
    ('21003', 'Config. parámetros', '210', 'pages/admin/parametros.php', 'SISTEMA', NOW()),
    ('301', 'Biblioteca', '30', 'pages/modulos/en_construccion/biblioteca.php', 'SISTEMA', NOW()),
    ('302', 'Gimnasio', '30', 'pages/modulos/en_construccion/gimnasio.php', 'SISTEMA', NOW()),
    ('303', 'Bienestar', '30', 'pages/modulos/en_construccion/bienestar.php', 'SISTEMA', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;
