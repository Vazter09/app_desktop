-- Listados de registro en admin (0301–0304); formularios siguen en módulo público.
UPDATE tab_menus SET nom_programa = 'src/admin/registro/listado.php?menu=0301', usr_update = 'migration', fec_update = NOW() WHERE id_menu = '0301';
UPDATE tab_menus SET nom_programa = 'src/admin/registro/listado.php?menu=0302', usr_update = 'migration', fec_update = NOW() WHERE id_menu = '0302';
UPDATE tab_menus SET nom_programa = 'src/admin/registro/listado.php?menu=0303', usr_update = 'migration', fec_update = NOW() WHERE id_menu = '0303';
UPDATE tab_menus SET nom_programa = 'src/admin/registro/listado.php?menu=0304', usr_update = 'migration', fec_update = NOW() WHERE id_menu = '0304';
