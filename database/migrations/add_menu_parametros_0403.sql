-- Menú Config. parámetros (0403) bajo Configuración (04)
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('0403', 'Config. parámetros', '04', 'pages/admin/parametros.php', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;

INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT 'admin.smart', '0403', 'migration', NOW()
WHERE EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = 'admin.smart')
ON CONFLICT (id_usuario, id_menu) DO NOTHING;
