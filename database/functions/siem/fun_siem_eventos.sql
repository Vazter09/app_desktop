-- Función: lista paginada de eventos de autenticación con filtros

-- El RETURNS TABLE cambió (columna motivo_fallo, E3 enriquecido); PostgreSQL
-- no permite alterar el tipo de retorno con CREATE OR REPLACE, hay que dropear.
DROP FUNCTION IF EXISTS fun_siem_list_eventos(
    TEXT, TEXT, DATE, DATE, TEXT, INT, INT
);

CREATE OR REPLACE FUNCTION fun_siem_list_eventos(
    wip_cliente  TEXT    DEFAULT NULL,
    wid_usuario  TEXT    DEFAULT NULL,
    wfecha_desde DATE    DEFAULT NULL,
    wfecha_hasta DATE    DEFAULT NULL,
    wind_exitoso TEXT    DEFAULT NULL,
    wlimit       INT     DEFAULT 50,
    woffset      INT     DEFAULT 0
) RETURNS TABLE(
    ip_cliente   VARCHAR,
    id_usuario   VARCHAR,
    ind_exitoso  BOOLEAN,
    motivo_fallo VARCHAR,
    fec_intento  TIMESTAMP,
    total_filas  BIGINT
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
        t.id_usuario,
        t.ind_exitoso,
        t.motivo_fallo,
        t.fec_intento,
        COUNT(*) OVER() AS total_filas
    FROM tab_intentos_login t
    WHERE
        (wip_cliente IS NULL OR wip_cliente = ''  OR t.ip_cliente ILIKE '%' || wip_cliente || '%')
        AND (wid_usuario IS NULL OR wid_usuario = '' OR t.id_usuario ILIKE '%' || wid_usuario || '%')
        AND (wfecha_desde IS NULL OR DATE(t.fec_intento) >= wfecha_desde)
        AND (wfecha_hasta IS NULL OR DATE(t.fec_intento) <= wfecha_hasta)
        AND (wind_exitoso IS NULL OR wind_exitoso = ''
             OR (wind_exitoso = 'true'  AND t.ind_exitoso = TRUE)
             OR (wind_exitoso = 'false' AND t.ind_exitoso = FALSE))
    ORDER BY t.fec_intento DESC
    LIMIT wlimit OFFSET woffset;

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
