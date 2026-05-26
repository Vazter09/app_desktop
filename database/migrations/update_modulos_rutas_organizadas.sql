-- Rutas de menú tras reorganización de src/modulos/
UPDATE tab_menus SET nom_programa = 'src/modulos/entradas/index.php'
 WHERE id_menu = '0101' OR nom_programa IN ('src/modulos/entradas.php', 'entradas.php', '../modulos/entradas.php');

UPDATE tab_menus SET nom_programa = 'src/modulos/porteria/ingreso/index.php'
 WHERE id_menu = '0102' OR nom_programa IN ('src/modulos/ingresos.php', 'ingresos.php', '../modulos/ingresos.php');

UPDATE tab_menus SET nom_programa = 'src/modulos/porteria/salida/index.php'
 WHERE id_menu = '0103' OR nom_programa IN ('src/modulos/salidas.php', 'salidas.php', '../modulos/salidas.php');
