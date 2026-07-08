-- Módulo SIEM (mini SIEM de seguridad) como submenú de SGA - Administrativo (20).
-- Trasladado desde feat/seguridad, donde vivía como menú raíz independiente ('06').
-- Debe ejecutarse DESPUÉS de reorganizacion_menus_tres_abuelos.sql (que recrea el
-- árbol de menús desde cero) y ANTES de ensure_admin_acceso_total.sql (que otorga
-- acceso a admins sobre todo tab_menus, incluido este submenú nuevo).
--
-- Módulo reducido a 2 submenús (Panel Control + Sesiones Activas): se
-- eliminaron Eventos Auth (21102), IPs Bloqueadas (21104) y Actividad
-- Física (21105), junto con sus páginas y funciones PL/pgSQL asociadas.

INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert)
VALUES
    ('211',   'SIEM',             '20',  'no_aplica',                               'migration', NOW()),
    ('21101', 'Panel Control',    '211', 'pages/modulos/siem/index.php',            'migration', NOW()),
    ('21103', 'Sesiones Activas', '211', 'pages/modulos/siem/sesiones/index.php',   'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;
