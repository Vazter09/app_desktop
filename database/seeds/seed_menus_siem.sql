-- Seed: Menús del módulo SIEM (mini SIEM de seguridad)
-- ID padre: 06 — no colisiona con 01-05 existentes

INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert)
VALUES
    ('06',   'SIEM',             '00', 'no_aplica',                                    'seed', NOW()),
    ('0601', 'Panel Control',    '06', 'pages/modulos/siem/index.php',                 'seed', NOW()),
    ('0602', 'Eventos Auth',     '06', 'pages/modulos/siem/eventos/index.php',         'seed', NOW()),
    ('0603', 'Sesiones Activas', '06', 'pages/modulos/siem/sesiones/index.php',        'seed', NOW()),
    ('0604', 'IPs Bloqueadas',   '06', 'pages/modulos/siem/ips/index.php',             'seed', NOW()),
    ('0605', 'Actividad Física', '06', 'pages/modulos/siem/actividad/index.php',       'seed', NOW())
ON CONFLICT (id_menu) DO NOTHING;
