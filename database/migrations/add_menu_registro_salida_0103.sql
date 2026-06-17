-- Menú: registro de salidas (portería)
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('0103', 'Registro salida', '01', 'src/modulos/porteria/salida/index.php', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;

-- Acceso portería: Acceso + ingreso + salida (sin catálogo 0101)
DELETE FROM tab_menu_usuarios
WHERE id_usuario = 'porteria'
  AND id_menu NOT IN ('01', '0102', '0103');

INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
VALUES
    ('porteria', '01', 'migration', NOW()),
    ('porteria', '0102', 'migration', NOW()),
    ('porteria', '0103', 'migration', NOW())
ON CONFLICT (id_usuario, id_menu) DO NOTHING;
