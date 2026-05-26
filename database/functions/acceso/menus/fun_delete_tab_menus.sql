-- Borrado atómico de menú (sin hijos ni accesos pendientes).
CREATE OR REPLACE FUNCTION fun_delete_tab_menus(p_id_menu tab_menus.id_menu%TYPE) RETURNS TEXT AS $$
DECLARE
    v_tiene_hijos INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_menus WHERE id_menu = p_id_menu) THEN
        PERFORM smartcset_raise_no_encontrado(
            'El menú no existe.',
            'id_menu=' || p_id_menu
        );
    END IF;

    SELECT COUNT(*) INTO v_tiene_hijos FROM tab_menus WHERE ind_id_padre = p_id_menu;
    IF v_tiene_hijos > 0 THEN
        PERFORM smartcset_raise_negocio(
            format(
                'El menú %s tiene %s submenú(s). Elimine primero los hijos.',
                p_id_menu, v_tiene_hijos
            ),
            NULL,
            'Borre o reasigne los submenús antes de eliminar este ítem.'
        );
    END IF;

    PERFORM fun_delete_menu_usuarios_por_menu(p_id_menu);
    DELETE FROM tab_menus WHERE id_menu = p_id_menu;

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN foreign_key_violation THEN
        PERFORM smartcset_raise_negocio(
            'No se puede eliminar el menú porque está en uso.',
            NULL,
            'Revise accesos de usuarios y submenús.'
        );
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
