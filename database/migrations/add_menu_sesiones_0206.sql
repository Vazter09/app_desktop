-- Menú administración: auditoría de sesiones
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('0206', 'Auditoría sesiones', '02', 'src/admin/sesiones/index.php', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;

INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT 'admin.smart', '0206', 'migration', NOW()
WHERE EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = 'admin.smart')
ON CONFLICT (id_usuario, id_menu) DO NOTHING;
