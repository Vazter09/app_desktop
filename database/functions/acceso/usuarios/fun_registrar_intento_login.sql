-- ===================================================================
-- Función: fun_registrar_intento_login
-- Descripción: Registra un intento de login (exitoso o fallido).
--              Limpia automáticamente registros de más de 90 días.
-- Parámetros:
--   wip_cliente:   IP del cliente que intenta el login.
--   wid_usuario:   ID del usuario (puede ser NULL si no existe).
--   wind_exitoso:  TRUE si el login fue exitoso, FALSE si falló.
--   wmotivo_fallo: Motivo del fallo (NULL en intentos exitosos):
--                  'usuario_no_existe' | 'cuenta_bloqueada' |
--                  'contrasena_incorrecta' | 'usuario_inactivo' |
--                  'ip_bloqueada_por_rate_limit'.
--   wuser_agent:   User-Agent del navegador (auditoría forense).
-- Retorna: TEXT 'OK'
-- ===================================================================

-- Eliminar la firma legacy de 3 argumentos (antes del enriquecimiento E3).
-- PostgreSQL trata distinto nº de args como funciones distintas; sin este
-- DROP quedarían dos versiones y un llamado de 3 args sería ambiguo.
DROP FUNCTION IF EXISTS fun_registrar_intento_login(
    character varying, character varying, boolean
);

CREATE OR REPLACE FUNCTION fun_registrar_intento_login(
    wip_cliente   tab_intentos_login.ip_cliente%TYPE,
    wid_usuario   tab_intentos_login.id_usuario%TYPE,
    wind_exitoso  tab_intentos_login.ind_exitoso%TYPE,
    wmotivo_fallo tab_intentos_login.motivo_fallo%TYPE DEFAULT NULL,
    wuser_agent   tab_intentos_login.user_agent%TYPE   DEFAULT NULL
) RETURNS TEXT AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wip_cliente IS NULL OR LENGTH(TRIM(wip_cliente)) < 7 THEN
        PERFORM smartcset_raise_validacion(
            'IP de cliente inválida.',
            'ip_cliente=' || COALESCE(wip_cliente, 'NULL')
        );
    END IF;

    -- Validación de dominio del motivo (solo cuando el intento falló).
    IF NOT wind_exitoso AND wmotivo_fallo IS NOT NULL
       AND wmotivo_fallo NOT IN (
           'usuario_no_existe', 'cuenta_bloqueada', 'contrasena_incorrecta',
           'usuario_inactivo', 'ip_bloqueada_por_rate_limit'
       ) THEN
        PERFORM smartcset_raise_validacion(
            'Motivo de fallo de login no reconocido.',
            'motivo_fallo=' || wmotivo_fallo
        );
    END IF;

    INSERT INTO tab_intentos_login (
        ip_cliente, id_usuario, ind_exitoso, motivo_fallo, user_agent
    )
    VALUES (
        wip_cliente,
        wid_usuario,
        wind_exitoso,
        CASE WHEN wind_exitoso THEN NULL ELSE wmotivo_fallo END,
        NULLIF(TRIM(wuser_agent), '')
    );

    -- Limpiar registros de más de 90 días para no crecer indefinidamente
    DELETE FROM tab_intentos_login
    WHERE fec_intento < CURRENT_TIMESTAMP - INTERVAL '90 days';

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
