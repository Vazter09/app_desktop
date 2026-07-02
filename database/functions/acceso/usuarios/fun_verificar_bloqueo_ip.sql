-- ===================================================================
-- Función: fun_verificar_bloqueo_ip
-- Descripción: Verifica si una IP está bloqueada por exceder el
--              límite de intentos fallidos en la ventana de tiempo.
--              Lanza excepción de negocio si la IP está bloqueada.
-- Parámetros:
--   wip_cliente:      IP del cliente a verificar.
--   wmax_intentos:    Máximo de intentos fallidos permitidos.
--   wventana_minutos: Ventana de tiempo en minutos a evaluar.
-- Retorna: TEXT — 'OK' si no está bloqueada, lanza excepción si sí.
-- ===================================================================
CREATE OR REPLACE FUNCTION fun_verificar_bloqueo_ip(
    wip_cliente       tab_intentos_login.ip_cliente%TYPE,
    wmax_intentos     INTEGER DEFAULT 5,
    wventana_minutos  INTEGER DEFAULT 15
) RETURNS TEXT AS $$
DECLARE
    v_intentos   INTEGER;
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

    SELECT COUNT(*)
    INTO v_intentos
    FROM tab_intentos_login
    WHERE ip_cliente    = wip_cliente
      AND ind_exitoso   = FALSE
      AND fec_intento  >= CURRENT_TIMESTAMP - (wventana_minutos || ' minutes')::INTERVAL;

    IF v_intentos >= wmax_intentos THEN
        PERFORM smartcset_raise_negocio(
            'Acceso bloqueado temporalmente por múltiples intentos fallidos. '
            || 'Intente de nuevo en ' || wventana_minutos || ' minutos.',
            'ip=' || wip_cliente || ' intentos_fallidos=' || v_intentos
        );
    END IF;

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
