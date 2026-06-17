CREATE OR REPLACE FUNCTION fun_validar_login(
    wuser tab_usuarios.id_usuario%TYPE,
    wpass tab_usuarios.pass_usuario%TYPE
) RETURNS TABLE (
    v_status  TEXT,
    v_mensaje TEXT,
    v_id      tab_usuarios.id_usuario%TYPE,
    v_nombre  tab_usuarios.nom_usuario%TYPE
) AS $$
-- NOTA IMPORTANTE:
-- Esta función ya no compara la contraseña en el motor porque las claves
-- se almacenan como hashes PHP (bcrypt / password_hash).
-- El parámetro wpass se ignora. La comparación se hace en PHP con password_verify().
-- Se mantiene la firma original para no romper llamadas existentes.
BEGIN
    RETURN QUERY
    SELECT 'OK'::TEXT, 'Usuario encontrado'::TEXT, u.id_usuario, u.nom_usuario
    FROM tab_usuarios u
    WHERE u.id_usuario = wuser
      AND u.ind_estado = TRUE;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;