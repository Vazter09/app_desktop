-- Padre Configuración (04) + hijos 0401, 0402.
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('04', 'Configuración', '00', 'no_aplica', 'seed_config', NOW()),
    ('0401', 'Config. sistema', '04', 'src/admin/configuracion.php', 'seed_config', NOW()),
    ('0402', 'Config. módulo', '04', 'src/admin/personas/config.php', 'seed_config', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa,
    usr_update = 'seed_config',
    fec_update = NOW();

-- IDs antiguos (0205 bajo Admin, 0305 bajo Personas, 0207 agrupador).
DELETE FROM tab_menu_usuarios WHERE id_menu IN ('0205', '0305', '0207');
DELETE FROM tab_menus WHERE id_menu IN ('0205', '0305', '0207');
