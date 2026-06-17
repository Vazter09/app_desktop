-- ===================================================================
-- Función: fun_delete_menu_usuarios_por_menu
-- Descripción: Elimina todos los registros de tab_menu_usuarios asociados a un menú.
-- Parámetro:
--   wid_menu: ID del menú (VARCHAR)
-- Retorna: VOID
-- ===================================================================
CREATE OR REPLACE FUNCTION fun_delete_menu_usuarios_por_menu(wid_menu tab_menus.id_menu%TYPE) RETURNS VOID AS
$$
DECLARE
    v_exists INTEGER;
    v_deleted INTEGER;
BEGIN
    -- Validar que el menú exista (ref. integridad referencial)
    SELECT COUNT(*) INTO v_exists FROM tab_menus WHERE id_menu = wid_menu;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'El menú % no existe en tab_menus', wid_menu;
    END IF;

    -- Eliminar los accesos de usuarios asociados al menú
    DELETE FROM tab_menu_usuarios
    WHERE id_menu = wid_menu;

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    -- Opcional: RAISE NOTICE 'Se eliminaron % registros de tab_menu_usuarios para el menú %', v_deleted, wid_menu;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error eliminando accesos para menú %: %', wid_menu, SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- ===================================================================
-- Trigger: tg_desasignar_menu
-- Descripción: Invocado antes de borrar un menú para limpiar accesos de usuarios.
-- ===================================================================
CREATE OR REPLACE FUNCTION fun_trigger_desasignar_menu() RETURNS TRIGGER AS
$$
BEGIN
    PERFORM fun_delete_menu_usuarios_por_menu(OLD.id_menu);
    RETURN OLD;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error en trigger tg_desasignar_menu para menú %: %', OLD.id_menu, SQLERRM;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER tg_desasignar_menu
BEFORE DELETE ON tab_menus FOR EACH ROW
EXECUTE FUNCTION fun_trigger_desasignar_menu();