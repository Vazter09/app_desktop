-- Asigna un menú a un usuario (tab_menu_usuarios).
CREATE OR REPLACE FUNCTION fun_insert_menu_usuarios(
    p_id_usuario tab_usuarios.id_usuario%TYPE,
    p_id_menu    tab_menus.id_menu%TYPE
) RETURNS VOID AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_id_usuario) THEN
        PERFORM smartcset_raise_no_encontrado(
            'El usuario no existe.',
            'id_usuario=' || p_id_usuario
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_menus WHERE id_menu = p_id_menu) THEN
        PERFORM smartcset_raise_no_encontrado(
            'El menú no existe.',
            'id_menu=' || p_id_menu
        );
    END IF;

    INSERT INTO tab_menu_usuarios (id_usuario, id_menu)
    VALUES (p_id_usuario, p_id_menu)
    ON CONFLICT (id_usuario, id_menu) DO NOTHING;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;
