-- Menús mínimos para admin.smart (desarrollo)
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('01', 'Acceso', '0', 'no_aplica', 'seed', NOW()),
    ('0101', 'Entradas', '01', 'src/modulos/entradas/index.php', 'seed', NOW()),
    ('0102', 'Registro ingreso', '01', 'src/modulos/porteria/ingreso/index.php', 'seed', NOW()),
    ('0103', 'Registro salida', '01', 'src/modulos/porteria/salida/index.php', 'seed', NOW()),
    ('02', 'Administración', '0', 'no_aplica', 'seed', NOW()),
    ('0201', 'Usuarios', '02', 'src/usuarios/usuarios.php', 'seed', NOW()),
    ('0202', 'Menús', '02', 'src/menu/menus.php', 'seed', NOW()),
    ('0203', 'Accesos', '02', 'src/menu/menu_usuarios.php', 'seed', NOW()),
    ('0204', 'Copiar perfil', '02', 'src/menu/copiar_menu_usuarios.php', 'seed', NOW())
ON CONFLICT (id_menu) DO NOTHING;

INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT 'admin.smart', id_menu, 'seed', NOW()
FROM tab_menus
WHERE id_menu IN ('01', '0101', '0102', '0103', '02', '0201', '0202', '0203', '0204')
ON CONFLICT (id_usuario, id_menu) DO NOTHING;
