-- Instructores (no admin): solo menús Mis Fichas (06) y permiso 0601.

DELETE FROM tab_menu_usuarios mu
USING tab_personas p
JOIN tab_usuarios u ON u.id_usuario = p.id_persona::VARCHAR
WHERE mu.id_usuario = p.id_persona::VARCHAR
  AND p.id_tipo_persona = 3
  AND u.ind_usuario = FALSE
  AND mu.id_menu NOT IN ('06', '0601');

-- Menús mínimos del módulo instructor (solo no administradores)
INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT p.id_persona::VARCHAR, m.id_menu, 'migration', NOW()
FROM tab_personas p
JOIN tab_usuarios u ON u.id_usuario = p.id_persona::VARCHAR
CROSS JOIN (VALUES ('06'), ('0601')) AS m(id_menu)
WHERE p.id_tipo_persona = 3
  AND u.ind_usuario = FALSE
ON CONFLICT (id_usuario, id_menu) DO NOTHING;

-- Administradores: acceso total a todo el catálogo de menús
INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT u.id_usuario, m.id_menu, 'migration', NOW()
FROM tab_usuarios u
CROSS JOIN tab_menus m
WHERE u.ind_usuario = TRUE
ON CONFLICT (id_usuario, id_menu) DO NOTHING;

UPDATE tab_usuarios SET ind_usuario = TRUE WHERE id_usuario = 'admin.smart';
