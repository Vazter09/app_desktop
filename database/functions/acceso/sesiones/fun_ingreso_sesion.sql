CREATE OR REPLACE FUNCTION fun_ingreso_sesion(
    p_user tab_usuarios.id_usuario%TYPE,
    p_ip_cliente tab_sesiones.ip_cliente%TYPE DEFAULT NULL,
    p_timeout_seg INTEGER DEFAULT 1800
) RETURNS TEXT AS $$
DECLARE
    w_id_sesion  tab_sesiones.id_sesion%TYPE;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
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

    -- Administradores: al reingresar, cierra cualquier sesión abierta previa (sin bloqueo).
    IF EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_user AND ind_usuario = TRUE) THEN
        UPDATE tab_sesiones
        SET fec_fin = CURRENT_TIMESTAMP,
            cod_cierre = 'LOGOUT',
            usr_cierre = p_user
        WHERE id_usuario = p_user
          AND fec_fin IS NULL;
    END IF;

    -- Usuarios normales: bloqueo si aún tienen sesión activa (hasta cierre manual del admin).
    IF NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_user AND ind_usuario = TRUE)
       AND EXISTS (
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
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;
