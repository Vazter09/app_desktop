CREATE OR REPLACE FUNCTION fun_salida_sesion(
    p_user tab_usuarios.id_usuario%TYPE
) RETURNS TEXT AS $$
BEGIN
    IF p_user IS NULL OR TRIM(p_user) = '' THEN
        PERFORM smartcset_raise_validacion('El usuario de sesión es obligatorio.');
    END IF;

    DELETE FROM tab_sesiones WHERE id_usuario = p_user;

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
