-- Menús de asignación de accesos (si solo existían 0201 y 0202 en Administración)
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('0203', 'Accesos', '02', 'src/menu/menu_usuarios.php', 'migration', NOW()),
    ('0204', 'Copiar perfil', '02', 'src/menu/copiar_menu_usuarios.php', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;

-- Dar acceso al administrador (ajuste id_usuario si usa otro admin)
INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT 'admin.smart', id_menu, 'migration', NOW()
FROM tab_menus
WHERE id_menu IN ('0203', '0204')
ON CONFLICT (id_usuario, id_menu) DO NOTHING;
