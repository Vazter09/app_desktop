CREATE OR REPLACE FUNCTION fun_actualizar_sesion_actividad(
    p_user tab_usuarios.id_usuario%TYPE
) RETURNS TEXT AS $$
BEGIN
    IF p_user IS NULL OR TRIM(p_user) = '' THEN
        RETURN 'OK';
    END IF;

    UPDATE tab_sesiones
    SET ult_actividad = CURRENT_TIMESTAMP
    WHERE id_usuario = p_user;

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
