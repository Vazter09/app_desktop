CREATE OR REPLACE FUNCTION fun_actualizar_password(
    wid_usuario TEXT,
    wpass_nuevo TEXT
) RETURNS TEXT AS $$
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
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
