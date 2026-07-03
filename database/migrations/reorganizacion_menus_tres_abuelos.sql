-- Refactor menús: 3 abuelos SGI (10) / SGA (20) / SAA (30).
-- Borra catálogo legacy y recrea con IDs jerárquicos homogéneos.

DELETE FROM tab_menu_usuarios;
DELETE FROM tab_menus;

INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    -- Abuelos
    ('10', 'SGI - Ingresos', '00', 'no_aplica', 'migration', NOW()),
    ('20', 'SGA - Administrativo', '00', 'no_aplica', 'migration', NOW()),
    ('30', 'SAA - Aprendiz', '00', 'no_aplica', 'migration', NOW()),

    -- SGI: acceso físico
    ('101', 'Entradas', '10', 'pages/modulos/entradas/index.php', 'migration', NOW()),
    ('102', 'Registro ingreso', '10', 'pages/modulos/porteria/ingreso/index.php', 'migration', NOW()),
    ('103', 'Registro salida', '10', 'pages/modulos/porteria/salida/index.php', 'migration', NOW()),
    ('104', 'Datos estadísticos', '10', 'pages/modulos/en_construccion/estadisticos.php', 'migration', NOW()),

    -- SGA: Instructores (pizarra 1.x)
    ('201', 'Instructores', '20', 'no_aplica', 'migration', NOW()),
    ('20101', 'Listado instructores', '201', 'pages/admin/personas/instructores/index.php', 'migration', NOW()),
    ('20102', 'Contratos', '201', 'pages/modulos/en_construccion/contratos.php', 'migration', NOW()),
    ('20103', 'Disciplinario', '201', 'pages/modulos/en_construccion/disciplinario_instructor.php', 'migration', NOW()),
    ('20104', 'Gestión tiempos', '201', 'pages/modulos/en_construccion/gestion_tiempos.php', 'migration', NOW()),
    ('20105', 'Portafolios', '201', 'pages/modulos/en_construccion/portafolios_instructor.php', 'migration', NOW()),

    -- SGA: Aprendices (pizarra 2.x)
    ('202', 'Aprendices', '20', 'no_aplica', 'migration', NOW()),
    ('20201', 'Listado aprendices', '202', 'pages/admin/personas/aprendices/index.php', 'migration', NOW()),
    ('20202', 'Certificaciones', '202', 'pages/modulos/en_construccion/certificaciones.php', 'migration', NOW()),
    ('20203', 'Disciplinario', '202', 'pages/modulos/en_construccion/disciplinario_aprendiz.php', 'migration', NOW()),
    ('20204', 'Juicios evaluativos', '202', 'pages/modulos/en_construccion/juicios_evaluativos.php', 'migration', NOW()),
    ('20205', 'Ruta académica', '202', 'pages/modulos/en_construccion/ruta_academica.php', 'migration', NOW()),
    ('20206', 'Portafolio', '202', 'pages/modulos/en_construccion/portafolio_aprendiz.php', 'migration', NOW()),
    ('20207', 'Caprendizaje', '202', 'pages/modulos/en_construccion/caprendizaje.php', 'migration', NOW()),

    -- SGA: Rutas (pizarra 3.x)
    ('203', 'Rutas', '20', 'no_aplica', 'migration', NOW()),
    ('20301', 'Consulta rutas', '203', 'pages/modulos/en_construccion/rutas_consulta.php', 'migration', NOW()),
    ('20302', 'Ruta CRUD', '203', 'pages/modulos/en_construccion/rutas_crud.php', 'migration', NOW()),

    -- SGA: Programas (pizarra 4)
    ('204', 'Programas', '20', 'pages/modulos/en_construccion/programas.php', 'migration', NOW()),

    -- SGA: Novedades (pizarra 5.x)
    ('205', 'Novedades', '20', 'no_aplica', 'migration', NOW()),
    ('20501', 'Llamados', '205', 'pages/modulos/en_construccion/llamados.php', 'migration', NOW()),
    ('20502', 'Comités', '205', 'pages/modulos/en_construccion/comites.php', 'migration', NOW()),

    -- SGA: Mis Fichas (instructor)
    ('206', 'Mis Fichas', '20', 'no_aplica', 'migration', NOW()),
    ('20601', 'Las fichas del instructor', '206', 'pages/modulos/instructor/fichas/index.php', 'migration', NOW()),

    -- SGA: Personas admin adicional
    ('207', 'Personas', '20', 'no_aplica', 'migration', NOW()),
    ('20701', 'Panel registro', '207', 'pages/modulos/registro/index.php', 'migration', NOW()),
    ('20702', 'Funcionarios', '207', 'pages/admin/personas/funcionarios/index.php', 'migration', NOW()),
    ('20703', 'Contratistas', '207', 'pages/admin/personas/contratistas/index.php', 'migration', NOW()),

    -- SGA: Reportes SENA (carga)
    ('208', 'Reportes SENA', '20', 'no_aplica', 'migration', NOW()),
    ('20801', 'DF-49 Fichas', '208', 'pages/admin/reportes/df49/index.php', 'migration', NOW()),
    ('20802', 'DF-53 Empresas', '208', 'pages/admin/reportes/df53/index.php', 'migration', NOW()),
    ('20803', 'DF-14A Estado', '208', 'pages/admin/reportes/df14a/index.php', 'migration', NOW()),
    ('20804', 'PE-04 Detalle', '208', 'pages/admin/reportes/pe04/index.php', 'migration', NOW()),
    ('20805', 'Aprendices', '208', 'pages/admin/reportes/aprendices/index.php', 'migration', NOW()),
    ('20806', 'Fichas creadas', '208', 'pages/admin/reportes/fichas_creadas/index.php', 'migration', NOW()),
    ('20807', 'Carga DF-51 Rutas', '208', 'pages/admin/reportes/df51/index.php', 'migration', NOW()),
    ('20808', 'Carga juicios evaluativos', '208', 'pages/admin/reportes/juicios/index.php', 'migration', NOW()),

    -- SGA: Administración sistema
    ('209', 'Administración', '20', 'no_aplica', 'migration', NOW()),
    ('20901', 'Usuarios', '209', 'pages/usuarios/usuarios.php', 'migration', NOW()),
    ('20902', 'Menús', '209', 'pages/menu/menus.php', 'migration', NOW()),
    ('20903', 'Accesos', '209', 'pages/menu/menu_usuarios.php', 'migration', NOW()),
    ('20904', 'Copiar perfil', '209', 'pages/menu/copiar_menu_usuarios.php', 'migration', NOW()),
    ('20905', 'Auditoría sesiones', '209', 'pages/admin/sesiones/index.php', 'migration', NOW()),

    -- SGA: Configuración
    ('210', 'Configuración', '20', 'no_aplica', 'migration', NOW()),
    ('21001', 'Config. sistema', '210', 'pages/admin/configuracion.php', 'migration', NOW()),
    ('21002', 'Config. módulo', '210', 'pages/admin/personas/config.php', 'migration', NOW()),
    ('21003', 'Config. parámetros', '210', 'pages/admin/parametros.php', 'migration', NOW()),

    -- SAA: apoyo al aprendiz
    ('301', 'Biblioteca', '30', 'pages/modulos/en_construccion/biblioteca.php', 'migration', NOW()),
    ('302', 'Gimnasio', '30', 'pages/modulos/en_construccion/gimnasio.php', 'migration', NOW()),
    ('303', 'Bienestar', '30', 'pages/modulos/en_construccion/bienestar.php', 'migration', NOW());
