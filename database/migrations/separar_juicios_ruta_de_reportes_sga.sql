-- Juicios evaluativos y Ruta académica (SGA > Aprendices) son módulos académicos,
-- no las pantallas de carga SENA. Los cargadores Excel vuelven a Reportes SENA (208).

UPDATE tab_menus SET nom_programa = 'pages/modulos/en_construccion/juicios_evaluativos.php'
WHERE id_menu = '20204';

UPDATE tab_menus SET nom_programa = 'pages/modulos/en_construccion/ruta_academica.php'
WHERE id_menu = '20205';

INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('20807', 'Carga DF-51 Rutas', '208', 'pages/admin/reportes/df51/index.php', 'migration', NOW()),
    ('20808', 'Carga juicios evaluativos', '208', 'pages/admin/reportes/juicios/index.php', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;

-- Administradores: acceso a los nuevos ítems de carga
INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT u.id_usuario, m.id_menu, 'migration', NOW()
FROM tab_usuarios u
CROSS JOIN tab_menus m
WHERE u.ind_usuario = TRUE
  AND m.id_menu IN ('20807', '20808')
ON CONFLICT (id_usuario, id_menu) DO NOTHING;
