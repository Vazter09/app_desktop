CREATE OR REPLACE FUNCTION fun_validar_usuario(
    _usuario tab_usuarios.id_usuario%TYPE
) RETURNS TABLE(id_usuario TEXT, nom_usuario TEXT) AS
$$
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
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;