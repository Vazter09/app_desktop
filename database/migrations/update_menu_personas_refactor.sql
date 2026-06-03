-- Refactor admin: carpeta personas, listados por tipo, menú padre Personas.
UPDATE tab_menus SET nom_menu = 'Personas', nom_programa = 'no_aplica', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '03';

UPDATE tab_menus SET nom_menu = 'Aprendices', nom_programa = 'src/admin/personas/aprendices/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0301';

UPDATE tab_menus SET nom_menu = 'Instructores', nom_programa = 'src/admin/personas/instructores/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0302';

UPDATE tab_menus SET nom_menu = 'Funcionarios', nom_programa = 'src/admin/personas/funcionarios/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0303';

UPDATE tab_menus SET nom_menu = 'Contratistas', nom_programa = 'src/admin/personas/contratistas/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0304';

UPDATE tab_menus SET nom_menu = 'Config. módulo', nom_programa = 'src/admin/personas/config.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0305';
