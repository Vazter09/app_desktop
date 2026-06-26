-- Menú Instructor (06) con vista Mis fichas (0601) para panel de asistencia.
-- Idempotente. No asigna a administradores (solo instructores vía fun_crear_usuarios_instructores).

INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('06',   'Instructor', '00', 'no_aplica',                                  'migration', NOW()),
    ('0601', 'Mis fichas', '06', 'pages/modulos/instructor/fichas/index.php', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu     = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa,
    usr_update   = 'migration',
    fec_update   = NOW();
