-- Menú Instructor (07) con vista Mis fichas (0701) para panel de asistencia.
-- Idempotente. No asigna a administradores (solo instructores vía fun_crear_usuarios_instructores).
-- NOTA: originalmente usaba id_menu '06'/'0601', pero esos IDs ya los usa el módulo SIEM
-- (ver database/functions/siem/ y seed_menus_siem.sql) — renumerado a 07/0701 para evitar colisión.

INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('07',   'Mis Fichas',              '00', 'no_aplica',                                  'migration', NOW()),
    ('0701', 'Las fichas del instructor', '07', 'pages/modulos/instructor/fichas/index.php', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu     = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa,
    usr_update   = 'migration',
    fec_update   = NOW();
