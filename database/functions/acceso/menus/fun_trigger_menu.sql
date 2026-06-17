-- V.1.3 CORRECCIÓN: Función trigger actualizada
-- Ahora inserta solo (id_usuario, id_menu) - nom_programa está en tab_menus
CREATE OR REPLACE FUNCTION fun_trigger_menu() RETURNS TRIGGER AS
$$
 DECLARE wid_menu tab_menus.id_menu%TYPE;
	BEGIN
        SELECT a.id_menu INTO wid_menu FROM tab_menus a
        WHERE a.id_menu = '9';
        IF NOT FOUND THEN
            RETURN NULL;
        END IF;
        -- V.1.3: INSERT solo con 2 valores (id_usuario, id_menu)
        -- El programa 'Exit' está en tab_menus.nom_programa
        INSERT INTO tab_menu_usuarios (id_usuario, id_menu)
        VALUES (NEW.id_usuario, wid_menu);
        IF FOUND THEN
            RETURN NULL;
        END IF;
    END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tg_menu_usuarios
AFTER INSERT ON tab_usuarios FOR EACH ROW
EXECUTE FUNCTION fun_trigger_menu();