-- Migración nom_programa → rutas bajo pages/ (arquitectura en capas)
-- Idempotente: puede ejecutarse varias veces.

UPDATE tab_menus SET nom_programa = 'pages/modulos/entradas/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0101' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/modulos/porteria/ingreso/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0102' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/modulos/porteria/salida/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0103' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/usuarios/usuarios.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0201' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/menu/menus.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0202' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/menu/menu_usuarios.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0203' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/menu/copiar_menu_usuarios.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0204' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/admin/sesiones/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0206' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/admin/configuracion.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0401' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/admin/personas/config.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0402' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/modulos/registro/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0300' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/admin/personas/aprendices/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0301' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/admin/personas/instructores/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0302' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/admin/personas/funcionarios/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0303' AND nom_programa LIKE 'src/%';

UPDATE tab_menus SET nom_programa = 'pages/admin/personas/contratistas/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0304' AND nom_programa LIKE 'src/%';

-- Catch-all: cualquier nom_programa legacy src/* → pages/*
UPDATE tab_menus
   SET nom_programa = 'pages/' || substring(nom_programa from 5),
       usr_update = 'migration',
       fec_update = NOW()
 WHERE nom_programa LIKE 'src/%'
   AND nom_programa NOT LIKE 'pages/%';

UPDATE tab_config_sistema
   SET path_logo = 'assets/img/logo-sena.png',
       usr_update = 'migration',
       fec_update = NOW()
 WHERE id_config = 1
   AND path_logo IN ('img/logo_empresa.png', 'img/logo-sena.png');
