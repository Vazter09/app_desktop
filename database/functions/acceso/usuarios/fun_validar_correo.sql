CREATE OR REPLACE FUNCTION fun_validar_correo(
    wuser  tab_usuarios.id_usuario%TYPE,
    wmail  tab_usuarios.mail_usuario%TYPE
) RETURNS TEXT AS $$
DECLARE
    v_existe     INTEGER;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    SELECT COUNT(*) INTO v_existe 
    FROM tab_usuarios 
    WHERE id_usuario = wuser AND mail_usuario = wmail;

    IF v_existe > 0 THEN
        RETURN 'OK';
    ELSE
        RETURN 'ERROR: Los datos no coinciden con nuestros registros.';
    END IF;
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