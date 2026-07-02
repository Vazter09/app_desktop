-- Función: IPs bloqueadas actualmente por rate limiting E3

CREATE OR REPLACE FUNCTION fun_siem_ips_bloqueadas(
    wmax_intentos   INT DEFAULT 5,
    wventana_minutos INT DEFAULT 15
) RETURNS TABLE(
    ip_cliente      VARCHAR,
    total_intentos  BIGINT,
    ultimo_intento  TIMESTAMP,
    minutos_expira  INT,
    expirada        BOOLEAN
) AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        t.ip_cliente,
        COUNT(*)                      AS total_intentos,
        MAX(t.fec_intento)            AS ultimo_intento,
        GREATEST(0,
            wventana_minutos - EXTRACT(EPOCH FROM (NOW() - MIN(t.fec_intento)))::INT / 60
        )                             AS minutos_expira,
        (MAX(t.fec_intento) < NOW() - (wventana_minutos || ' minutes')::INTERVAL) AS expirada
    FROM tab_intentos_login t
    WHERE t.ind_exitoso = FALSE
      AND t.fec_intento >= NOW() - (wventana_minutos * 2 || ' minutes')::INTERVAL
    GROUP BY t.ip_cliente
    HAVING COUNT(*) >= wmax_intentos
    ORDER BY MAX(t.fec_intento) DESC;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;


-- Función: desbloquear IP (elimina sus intentos fallidos recientes)
CREATE OR REPLACE FUNCTION fun_siem_desbloquear_ip(
    wip_cliente     TEXT,
    wid_operador    TEXT
) RETURNS TEXT AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wip_cliente IS NULL OR TRIM(wip_cliente) = '' THEN
        PERFORM smartcset_raise_validacion('La IP es obligatoria.');
    END IF;

    DELETE FROM tab_intentos_login
    WHERE ip_cliente = wip_cliente
      AND ind_exitoso = FALSE
      AND fec_intento >= NOW() - INTERVAL '30 minutes';

    RETURN 'OK';

EXCEPTION
    WHEN SQLSTATE 'P0001' THEN RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;
