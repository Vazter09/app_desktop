CREATE OR REPLACE FUNCTION fun_validar_usuario(
    _usuario tab_usuarios.id_usuario%TYPE
) RETURNS TABLE(id_usuario TEXT, nom_usuario TEXT) AS
$$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    -- Solo verifica que el usuario exista y esté activo.
    -- La validación de la contraseña se hace en PHP con password_verify().
    RETURN QUERY
    SELECT u.id_usuario, u.nom_usuario
    FROM tab_usuarios u
    WHERE u.id_usuario = _usuario
      AND u.ind_estado = TRUE;
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