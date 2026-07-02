-- ===================================================================
-- Función: fun_registrar_intento_login
-- Descripción: Registra un intento de login (exitoso o fallido).
--              Limpia automáticamente registros de más de 90 días.
-- Parámetros:
--   wip_cliente: IP del cliente que intenta el login.
--   wid_usuario: ID del usuario (puede ser NULL si no existe).
--   wind_exitoso: TRUE si el login fue exitoso, FALSE si falló.
-- Retorna: TEXT 'OK'
-- ===================================================================
CREATE OR REPLACE FUNCTION fun_registrar_intento_login(
    wip_cliente  tab_intentos_login.ip_cliente%TYPE,
    wid_usuario  tab_intentos_login.id_usuario%TYPE,
    wind_exitoso tab_intentos_login.ind_exitoso%TYPE
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

    INSERT INTO tab_intentos_login (ip_cliente, id_usuario, ind_exitoso)
    VALUES (wip_cliente, wid_usuario, wind_exitoso);

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
