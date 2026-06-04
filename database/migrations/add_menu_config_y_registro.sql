-- Configuración (04) al nivel raíz → 0401 Config. sistema, 0402 Config. módulo
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('04', 'Configuración', '00', 'no_aplica', 'migration', NOW()),
    ('0401', 'Config. sistema', '04', 'src/admin/configuracion.php', 'migration', NOW()),
    ('0402', 'Config. módulo', '04', 'src/admin/personas/config.php', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;

-- Módulo Personas (listados admin + panel standalone)
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('03', 'Personas', '00', 'no_aplica', 'migration', NOW()),
    ('0300', 'Panel registro', '03', 'src/modulos/registro/index.php', 'migration', NOW()),
    ('0301', 'Aprendices', '03', 'src/admin/personas/aprendices/index.php', 'migration', NOW()),
    ('0302', 'Instructores', '03', 'src/admin/personas/instructores/index.php', 'migration', NOW()),
    ('0303', 'Funcionarios', '03', 'src/admin/personas/funcionarios/index.php', 'migration', NOW()),
    ('0304', 'Contratistas', '03', 'src/admin/personas/contratistas/index.php', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;

INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT 'admin.smart', id_menu, 'migration', NOW()
FROM tab_menus
WHERE id_menu IN ('04', '0401', '0402', '03', '0300', '0301', '0302', '0303', '0304')
ON CONFLICT (id_usuario, id_menu) DO NOTHING;
