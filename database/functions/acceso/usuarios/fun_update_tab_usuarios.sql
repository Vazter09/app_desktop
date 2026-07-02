CREATE OR REPLACE FUNCTION fun_update_tab_usuarios(
    wid_usuario   tab_usuarios.id_usuario%TYPE,
    wnom_usuario  tab_usuarios.nom_usuario%TYPE,
    wpass_usuario tab_usuarios.pass_usuario%TYPE,
    wmail_usuario tab_usuarios.mail_usuario%TYPE,
    wind_usuario  tab_usuarios.ind_usuario%TYPE,
    wind_estado   tab_usuarios.ind_estado%TYPE
) RETURNS TEXT AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    UPDATE tab_usuarios
    SET nom_usuario  = wnom_usuario,
        pass_usuario = wpass_usuario,
        mail_usuario = wmail_usuario,
        ind_usuario  = wind_usuario,
        ind_estado   = wind_estado
    WHERE id_usuario = wid_usuario;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'El usuario no existe.',
            'id_usuario=' || wid_usuario
        );
    END IF;

    RETURN 'OK';
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
