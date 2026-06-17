-- Al crear un menú nuevo, asignarlo automáticamente a todos los administradores (ind_usuario = TRUE)
CREATE OR REPLACE FUNCTION fun_trigger_menu_admin() RETURNS TRIGGER AS
$$
BEGIN
    INSERT INTO tab_menu_usuarios (id_usuario, id_menu)
    SELECT u.id_usuario, NEW.id_menu
    FROM tab_usuarios u
    WHERE u.ind_usuario = TRUE
    ON CONFLICT (id_usuario, id_menu) DO NOTHING;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_menu_dmin ON tab_menus;
CREATE TRIGGER tg_menu_dmin
    AFTER INSERT ON tab_menus
    FOR EACH ROW
    EXECUTE FUNCTION fun_trigger_menu_admin();
