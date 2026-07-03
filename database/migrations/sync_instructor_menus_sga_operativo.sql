-- Instructores (no admin): subconjunto operativo SGA.
-- Portería: subárbol SGI.

DELETE FROM tab_menu_usuarios mu
USING tab_personas p
JOIN tab_usuarios u ON u.id_usuario = p.id_persona::VARCHAR
WHERE mu.id_usuario = p.id_persona::VARCHAR
  AND p.id_tipo_persona = 3
  AND u.ind_usuario = FALSE
  AND mu.id_menu NOT IN (
      '20', '202', '20201',
      '205', '20501', '20502',
      '206', '20601'
  );

INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT p.id_persona::VARCHAR, m.id_menu, 'migration', NOW()
FROM tab_personas p
JOIN tab_usuarios u ON u.id_usuario = p.id_persona::VARCHAR
CROSS JOIN (
    VALUES
        ('20'), ('202'), ('20201'),
        ('205'), ('20501'), ('20502'),
        ('206'), ('20601')
) AS m(id_menu)
WHERE p.id_tipo_persona = 3
  AND u.ind_usuario = FALSE
ON CONFLICT (id_usuario, id_menu) DO NOTHING;

-- Portería: solo SGI
DELETE FROM tab_menu_usuarios
WHERE id_usuario = 'porteria';

INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT 'porteria', m.id_menu, 'migration', NOW()
FROM tab_menus m
WHERE m.id_menu IN ('10', '101', '102', '103', '104')
ON CONFLICT (id_usuario, id_menu) DO NOTHING;

-- Administradores: acceso total al catálogo nuevo
INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT u.id_usuario, m.id_menu, 'migration', NOW()
FROM tab_usuarios u
CROSS JOIN tab_menus m
WHERE u.ind_usuario = TRUE
ON CONFLICT (id_usuario, id_menu) DO NOTHING;

UPDATE tab_usuarios SET ind_usuario = TRUE WHERE id_usuario = 'admin.smart';
