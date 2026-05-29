CREATE OR REPLACE FUNCTION fun_ingreso_sesion(
    p_user tab_usuarios.id_usuario%TYPE
) RETURNS TEXT AS $$
BEGIN
    IF p_user IS NULL OR TRIM(p_user) = '' THEN
        PERFORM smartcset_raise_validacion('El usuario de sesión es obligatorio.');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_user) THEN
        PERFORM smartcset_raise_no_encontrado(
            'No se puede registrar sesión: usuario inexistente.',
            'id_usuario=' || p_user
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_user AND ind_estado = TRUE) THEN
        PERFORM smartcset_raise_negocio(
            'El usuario se encuentra inhabilitado.',
            'id_usuario=' || p_user
        );
    END IF;

    IF EXISTS (SELECT 1 FROM tab_sesiones WHERE id_usuario = p_user) THEN
        PERFORM smartcset_raise_negocio(
            'Ya tiene una sesión activa en el sistema. Cierre sesión en el otro equipo o contacte al administrador.'
        );
    END IF;

    INSERT INTO tab_sesiones (id_usuario, fec_inicio, ult_actividad)
    VALUES (p_user, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
