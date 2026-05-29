-- Menú administración: configuración sistema
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('0205', 'Config. sistema', '02', 'src/admin/configuracion.php', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;

-- Módulo registro de personas (ex carpeta files/)
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('03', 'Registro personas', '00', 'no_aplica', 'migration', NOW()),
    ('0300', 'Panel registro', '03', 'src/modulos/registro/index.php', 'migration', NOW()),
    ('0305', 'Config. registro', '03', 'src/admin/registro/config.php', 'migration', NOW()),
    ('0301', 'Aprendiz', '03', 'src/admin/registro/listado.php?menu=0301', 'migration', NOW()),
    ('0302', 'Instructor', '03', 'src/admin/registro/listado.php?menu=0302', 'migration', NOW()),
    ('0303', 'Funcionario', '03', 'src/admin/registro/listado.php?menu=0303', 'migration', NOW()),
    ('0304', 'Contratista', '03', 'src/admin/registro/listado.php?menu=0304', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;

INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
SELECT 'admin.smart', id_menu, 'migration', NOW()
FROM tab_menus
WHERE id_menu IN ('0205', '03', '0300', '0305', '0301', '0302', '0303', '0304')
ON CONFLICT (id_usuario, id_menu) DO NOTHING;
