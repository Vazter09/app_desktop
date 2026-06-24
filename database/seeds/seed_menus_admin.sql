-- Menús mínimos para admin.smart (desarrollo) — rutas bajo pages/
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('01', 'Acceso', '00', 'no_aplica', 'seed', NOW()),
    ('0101', 'Entradas', '01', 'pages/modulos/entradas/index.php', 'seed', NOW()),
    ('0102', 'Registro ingreso', '01', 'pages/modulos/porteria/ingreso/index.php', 'seed', NOW()),
    ('0103', 'Registro salida', '01', 'pages/modulos/porteria/salida/index.php', 'seed', NOW()),
    ('02', 'Administración', '00', 'no_aplica', 'seed', NOW()),
    ('0201', 'Usuarios', '02', 'pages/usuarios/usuarios.php', 'seed', NOW()),
    ('0202', 'Menús', '02', 'pages/menu/menus.php', 'seed', NOW()),
    ('0203', 'Accesos', '02', 'pages/menu/menu_usuarios.php', 'seed', NOW()),
    ('0204', 'Copiar perfil', '02', 'pages/menu/copiar_menu_usuarios.php', 'seed', NOW()),
    ('0206', 'Auditoría sesiones', '02', 'pages/admin/sesiones/index.php', 'seed', NOW())
ON CONFLICT (id_menu) DO NOTHING;

INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT 'admin.smart', id_menu, 'seed', NOW()
FROM tab_menus
WHERE id_menu IN ('01', '0101', '0102', '0103', '02', '0201', '0202', '0203', '0204', '0206')
ON CONFLICT (id_usuario, id_menu) DO NOTHING;
