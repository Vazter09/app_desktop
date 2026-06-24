-- Menú "Reportes SENA" (padre 05) con un sub-item por cada reporte SENA.
-- Las páginas son vistas de solo lectura sobre las tablas tab_temp_* (DF-49, DF-51,
-- DF-53, DF-14A, PE-04, aprendices, fichas creadas, juicios).
-- Idempotente: ON CONFLICT DO NOTHING. Se asigna a TODOS los administradores.

INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('05',   'Reportes SENA', '00', 'no_aplica',                                  'migration', NOW()),
    ('0501', 'DF-49 Fichas',  '05', 'pages/admin/reportes/df49/index.php',         'migration', NOW()),
    ('0502', 'DF-51 Rutas',   '05', 'pages/admin/reportes/df51/index.php',         'migration', NOW()),
    ('0503', 'DF-53 Empresas','05', 'pages/admin/reportes/df53/index.php',         'migration', NOW()),
    ('0504', 'DF-14A Estado', '05', 'pages/admin/reportes/df14a/index.php',        'migration', NOW()),
    ('0505', 'PE-04 Detalle', '05', 'pages/admin/reportes/pe04/index.php',         'migration', NOW()),
    ('0506', 'Aprendices',    '05', 'pages/admin/reportes/aprendices/index.php',   'migration', NOW()),
    ('0507', 'Fichas creadas','05', 'pages/admin/reportes/fichas_creadas/index.php','migration', NOW()),
    ('0508', 'Juicios',       '05', 'pages/admin/reportes/juicios/index.php',      'migration', NOW())
ON CONFLICT (id_menu) DO NOTHING;

INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT u.id_usuario, m.id_menu, 'migration', NOW()
FROM tab_usuarios u
CROSS JOIN (
    SELECT id_menu FROM tab_menus
    WHERE id_menu IN ('05','0501','0502','0503','0504','0505','0506','0507','0508')
) m
WHERE u.ind_usuario = TRUE
ON CONFLICT (id_usuario, id_menu) DO NOTHING;
