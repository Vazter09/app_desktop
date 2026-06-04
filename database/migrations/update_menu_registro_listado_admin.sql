-- Corrige rutas legacy src/admin/registro/* (carpeta eliminada; listados en src/admin/personas/).
UPDATE tab_menus SET nom_programa = 'src/admin/personas/aprendices/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0301' AND nom_programa LIKE '%admin/registro%';

UPDATE tab_menus SET nom_programa = 'src/admin/personas/instructores/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0302' AND nom_programa LIKE '%admin/registro%';

UPDATE tab_menus SET nom_programa = 'src/admin/personas/funcionarios/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0303' AND nom_programa LIKE '%admin/registro%';

UPDATE tab_menus SET nom_programa = 'src/admin/personas/contratistas/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0304' AND nom_programa LIKE '%admin/registro%';

UPDATE tab_menus SET nom_programa = 'src/admin/personas/config.php', usr_update = 'migration', fec_update = NOW()
WHERE nom_programa LIKE '%admin/registro/config%';
