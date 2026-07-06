-- Función: KPIs del dashboard SIEM
-- Retorna conteos para las 4 tarjetas principales
-- Parámetros configurables para coherencia con rate limiting (E3)

CREATE OR REPLACE FUNCTION fun_siem_dashboard_kpis(
    wmax_intentos    INTEGER DEFAULT 5,
    wventana_minutos INTEGER DEFAULT 15
)
RETURNS TABLE(
    total_intentos_hoy   BIGINT,
    fallos_hoy           BIGINT,
    ips_bloqueadas       BIGINT,
    sesiones_activas     BIGINT
) AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM tab_intentos_login
         WHERE DATE(fec_intento) = CURRENT_DATE)::BIGINT,

        (SELECT COUNT(*) FROM tab_intentos_login
         WHERE DATE(fec_intento) = CURRENT_DATE
           AND ind_exitoso = FALSE)::BIGINT,

        (SELECT COUNT(DISTINCT ip_cliente) FROM tab_intentos_login
         WHERE fec_intento >= NOW() - (wventana_minutos || ' minutes')::INTERVAL
           AND ind_exitoso = FALSE
         GROUP BY ip_cliente
         HAVING COUNT(*) >= wmax_intentos)::BIGINT,

        (SELECT COUNT(*) FROM tab_sesiones
         WHERE fec_fin IS NULL)::BIGINT;

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


-- Función: eventos por hora (últimas 24h) para gráfica Chart.js
CREATE OR REPLACE FUNCTION fun_siem_eventos_por_hora()
RETURNS TABLE(
    hora       INT,
    exitosos   BIGINT,
    fallidos   BIGINT
) AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        EXTRACT(HOUR FROM fec_intento)::INT AS hora,
        COUNT(*) FILTER (WHERE ind_exitoso = TRUE)  AS exitosos,
        COUNT(*) FILTER (WHERE ind_exitoso = FALSE) AS fallidos
    FROM tab_intentos_login
    WHERE fec_intento >= NOW() - INTERVAL '24 hours'
    GROUP BY EXTRACT(HOUR FROM fec_intento)
    ORDER BY hora;

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


-- Función: top 5 IPs con más fallos hoy
-- Parámetro configurable para coherencia con rate limiting (E3)
CREATE OR REPLACE FUNCTION fun_siem_top_ips_fallidas(
    wmax_intentos    INTEGER DEFAULT 5,
    wventana_minutos INTEGER DEFAULT 15
)
RETURNS TABLE(
    ip_cliente   VARCHAR,
    total_fallos BIGINT,
    ultimo_fallo TIMESTAMP,
    bloqueada    BOOLEAN
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
        COUNT(*) AS total_fallos,
        MAX(t.fec_intento) AS ultimo_fallo,
        (COUNT(*) FILTER (
            WHERE t.fec_intento >= NOW() - (wventana_minutos || ' minutes')::INTERVAL
        ) >= wmax_intentos) AS bloqueada
    FROM tab_intentos_login t
    WHERE DATE(t.fec_intento) = CURRENT_DATE
      AND t.ind_exitoso = FALSE
    GROUP BY t.ip_cliente
    ORDER BY total_fallos DESC
    LIMIT 5;

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


-- Función: últimas alertas (8 eventos recientes de seguridad)
-- Parámetro configurable para coherencia con rate limiting (E3)
CREATE OR REPLACE FUNCTION fun_siem_alertas_recientes(
    wmax_intentos    INTEGER DEFAULT 5,
    wventana_minutos INTEGER DEFAULT 15
)
RETURNS TABLE(
    tipo        TEXT,
    descripcion TEXT,
    ip_cliente  VARCHAR,
    fec_evento  TIMESTAMP,
    severidad   TEXT
) AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        CASE
            WHEN bloqueo.ip_cliente IS NOT NULL THEN 'IP_BLOQUEADA'
            ELSE 'FALLO_AUTH'
        END AS tipo,
        CASE
            WHEN bloqueo.ip_cliente IS NOT NULL
                THEN 'IP bloqueada por ' || bloqueo.total_fallos || ' intentos fallidos'
            ELSE 'Intento fallido: usuario ' || COALESCE(t.id_usuario, '(desconocido)')
        END AS descripcion,
        t.ip_cliente,
        t.fec_intento AS fec_evento,
        CASE
            WHEN bloqueo.ip_cliente IS NOT NULL THEN 'danger'
            ELSE 'warning'
        END AS severidad
    FROM tab_intentos_login t
    LEFT JOIN (
        SELECT il.ip_cliente, COUNT(*) AS total_fallos
        FROM tab_intentos_login il
        WHERE il.fec_intento >= NOW() - (wventana_minutos || ' minutes')::INTERVAL
          AND il.ind_exitoso = FALSE
        GROUP BY il.ip_cliente
        HAVING COUNT(*) >= wmax_intentos
    ) bloqueo ON bloqueo.ip_cliente = t.ip_cliente
    WHERE t.ind_exitoso = FALSE
    ORDER BY t.fec_intento DESC
    LIMIT 8;

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
