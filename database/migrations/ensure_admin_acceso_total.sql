-- Garantiza que administradores conserven acceso total al catálogo de menús.

INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT u.id_usuario, m.id_menu, 'migration', NOW()
FROM tab_usuarios u
CROSS JOIN tab_menus m
WHERE u.ind_usuario = TRUE
ON CONFLICT (id_usuario, id_menu) DO NOTHING;

UPDATE tab_usuarios SET ind_usuario = TRUE WHERE id_usuario = 'admin.smart';
