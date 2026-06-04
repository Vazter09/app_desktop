CREATE OR REPLACE FUNCTION fun_ingreso_sesion(
    p_user tab_usuarios.id_usuario%TYPE,
    p_ip_cliente tab_sesiones.ip_cliente%TYPE DEFAULT NULL
) RETURNS TEXT AS $$
DECLARE
    w_id_sesion tab_sesiones.id_sesion%TYPE;
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

    IF EXISTS (
        SELECT 1 FROM tab_sesiones
        WHERE id_usuario = p_user AND fec_fin IS NULL
    ) THEN
        PERFORM smartcset_raise_negocio(
            'Ya tiene una sesión activa en el sistema. Cierre sesión en el otro equipo o contacte al administrador.'
        );
    END IF;

    INSERT INTO tab_sesiones (id_usuario, ip_cliente, ult_ruta)
    VALUES (
        p_user,
        NULLIF(TRIM(p_ip_cliente), ''),
        'index.php'
    )
    RETURNING id_sesion INTO w_id_sesion;

    RETURN w_id_sesion::TEXT;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
