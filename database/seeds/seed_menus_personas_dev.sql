-- Menús módulo Personas (admin). Idempotente: seguro ejecutar en cada entorno dev.
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('03', 'Personas', '00', 'no_aplica', 'SISTEMA', NOW()),
    ('0300', 'Panel registro', '03', 'src/modulos/registro/index.php', 'SISTEMA', NOW()),
    ('0301', 'Aprendices', '03', 'src/admin/personas/aprendices/index.php', 'SISTEMA', NOW()),
    ('0302', 'Instructores', '03', 'src/admin/personas/instructores/index.php', 'SISTEMA', NOW()),
    ('0303', 'Funcionarios', '03', 'src/admin/personas/funcionarios/index.php', 'SISTEMA', NOW()),
    ('0304', 'Contratistas', '03', 'src/admin/personas/contratistas/index.php', 'SISTEMA', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa,
    usr_update = 'SISTEMA',
    fec_update = NOW();
