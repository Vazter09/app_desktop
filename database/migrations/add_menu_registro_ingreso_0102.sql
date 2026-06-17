-- Menú: registro de ingresos (portería) — no confundir con 0101 (catálogo de puertas)
INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa, usr_insert, fec_insert) VALUES
    ('0102', 'Registro ingreso', '01', 'src/modulos/porteria/ingreso/index.php', 'migration', NOW())
ON CONFLICT (id_menu) DO UPDATE SET
    nom_menu = EXCLUDED.nom_menu,
    ind_id_padre = EXCLUDED.ind_id_padre,
    nom_programa = EXCLUDED.nom_programa;

CREATE SEQUENCE IF NOT EXISTS seq_log_ingresos START WITH 1 INCREMENT BY 1;

-- Acceso portería: solo agrupador Acceso + registro (sin catálogo 0101 ni administración)
DELETE FROM tab_menu_usuarios
WHERE id_usuario = 'porteria'
  AND id_menu NOT IN ('01', '0102');

INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
VALUES
    ('porteria', '01', 'migration', NOW()),
    ('porteria', '0102', 'migration', NOW())
ON CONFLICT (id_usuario, id_menu) DO NOTHING;
