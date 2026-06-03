-- Personas (03) + Configuración raíz (04) con hijos 0401, 0402.
UPDATE tab_menus SET nom_menu = 'Personas', nom_programa = 'no_aplica', ind_id_padre = '00', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '03';

UPDATE tab_menus SET nom_menu = 'Aprendices', nom_programa = 'src/admin/personas/aprendices/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0301';

UPDATE tab_menus SET nom_menu = 'Instructores', nom_programa = 'src/admin/personas/instructores/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0302';

UPDATE tab_menus SET nom_menu = 'Funcionarios', nom_programa = 'src/admin/personas/funcionarios/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0303';

UPDATE tab_menus SET nom_menu = 'Contratistas', nom_programa = 'src/admin/personas/contratistas/index.php', usr_update = 'migration', fec_update = NOW()
WHERE id_menu = '0304';

INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('04', 'Configuración', '00', 'no_aplica', 'migration', NOW()),
    ('0401', 'Config. sistema', '04', 'src/admin/configuracion.php', 'migration', NOW()),
    ('0402', 'Config. módulo', '04', 'src/admin/personas/config.php', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa,
    usr_update = 'migration',
    fec_update = NOW();

DELETE FROM tab_menu_usuarios WHERE id_menu IN ('0205', '0305', '0207');
DELETE FROM tab_menus WHERE id_menu IN ('0205', '0305', '0207');
