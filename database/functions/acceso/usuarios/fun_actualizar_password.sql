CREATE OR REPLACE FUNCTION fun_actualizar_password(
    wid_usuario TEXT,
    wpass_nuevo TEXT
) RETURNS TEXT AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_usuario IS NULL OR TRIM(wid_usuario) = '' THEN
        PERFORM smartcset_raise_validacion('El usuario es obligatorio.');
    END IF;

    IF wpass_nuevo IS NULL OR LENGTH(wpass_nuevo) < 12 THEN
        PERFORM smartcset_raise_validacion(
            'La contraseña debe tener al menos 12 caracteres.',
            NULL,
            'Use una contraseña más larga o un hash bcrypt válido.'
        );
    END IF;

    UPDATE tab_usuarios
    SET pass_usuario = wpass_nuevo
    WHERE id_usuario = wid_usuario;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'Usuario no encontrado.',
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
