-- ===================================================================
-- Funciones del dashboard SIEM (panel de control)
-- Parámetros configurables para coherencia con rate limiting (E3):
--   wmax_intentos / wventana_minutos ← .env (LOGIN_MAX_INTENTOS /
--   LOGIN_VENTANA_MINUTOS), pasados desde PHP.
--   wzona_horaria ← APP_TIMEZONE: los timestamps se almacenan en la
--   zona de la conexión (DB_TIMEZONE, normalmente UTC); "hoy" y las
--   horas de la gráfica se calculan en la zona local del usuario.
-- Las firmas cambiaron (0-arg → parametrizadas); PostgreSQL trata
-- distinto número de argumentos como funciones distintas, hay que
-- dropear las firmas anteriores para no dejar huérfanas (lección E3).
-- ===================================================================

DROP FUNCTION IF EXISTS fun_siem_dashboard_kpis();
DROP FUNCTION IF EXISTS fun_siem_dashboard_kpis(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS fun_siem_eventos_por_hora();
DROP FUNCTION IF EXISTS fun_siem_top_ips_fallidas();
DROP FUNCTION IF EXISTS fun_siem_top_ips_fallidas(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS fun_siem_alertas_recientes();
DROP FUNCTION IF EXISTS fun_siem_alertas_recientes(INTEGER, INTEGER);


-- Función: KPIs del dashboard SIEM
-- Retorna conteos para las 4 tarjetas principales
CREATE OR REPLACE FUNCTION fun_siem_dashboard_kpis(
    wmax_intentos    INTEGER DEFAULT 5,
    wventana_minutos INTEGER DEFAULT 15,
    wzona_horaria    TEXT    DEFAULT 'America/Bogota'
)
RETURNS TABLE(
    total_intentos_hoy   BIGINT,
    fallos_hoy           BIGINT,
    ips_bloqueadas       BIGINT,
    sesiones_activas     BIGINT
) AS $$
DECLARE
    w_hoy_local  DATE;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    w_hoy_local := (NOW() AT TIME ZONE wzona_horaria)::DATE;

    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM tab_intentos_login
         WHERE (fec_intento::TIMESTAMPTZ AT TIME ZONE wzona_horaria)::DATE
               = w_hoy_local)::BIGINT,

        (SELECT COUNT(*) FROM tab_intentos_login
         WHERE (fec_intento::TIMESTAMPTZ AT TIME ZONE wzona_horaria)::DATE
               = w_hoy_local
           AND ind_exitoso = FALSE)::BIGINT,

        -- Subconsulta anidada: con GROUP BY+HAVING directo, 2+ IPs
        -- bloqueadas devolverían varias filas y el escalar fallaría.
        (SELECT COUNT(*) FROM (
            SELECT il.ip_cliente
            FROM tab_intentos_login il
            WHERE il.fec_intento >= NOW() - (wventana_minutos || ' minutes')::INTERVAL
              AND il.ind_exitoso = FALSE
            GROUP BY il.ip_cliente
            HAVING COUNT(*) >= wmax_intentos
        ) ips_bloq)::BIGINT,

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
-- La hora se expresa en la zona local del usuario (wzona_horaria)
CREATE OR REPLACE FUNCTION fun_siem_eventos_por_hora(
    wzona_horaria TEXT DEFAULT 'America/Bogota'
)
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
        EXTRACT(HOUR FROM fec_intento::TIMESTAMPTZ AT TIME ZONE wzona_horaria)::INT AS hora,
        COUNT(*) FILTER (WHERE ind_exitoso = TRUE)  AS exitosos,
        COUNT(*) FILTER (WHERE ind_exitoso = FALSE) AS fallidos
    FROM tab_intentos_login
    WHERE fec_intento >= NOW() - INTERVAL '24 hours'
    GROUP BY EXTRACT(HOUR FROM fec_intento::TIMESTAMPTZ AT TIME ZONE wzona_horaria)
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


-- Función: top 5 IPs con más fallos hoy (día local del usuario)
CREATE OR REPLACE FUNCTION fun_siem_top_ips_fallidas(
    wmax_intentos    INTEGER DEFAULT 5,
    wventana_minutos INTEGER DEFAULT 15,
    wzona_horaria    TEXT    DEFAULT 'America/Bogota'
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
    WHERE (t.fec_intento::TIMESTAMPTZ AT TIME ZONE wzona_horaria)::DATE
          = (NOW() AT TIME ZONE wzona_horaria)::DATE
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
-- Retorna información enriquecida: tipo, descripción, IP, fecha/hora, motivo,
-- user-agent, contador de intentos en ventana y severidad
CREATE OR REPLACE FUNCTION fun_siem_alertas_recientes(
    wmax_intentos    INTEGER DEFAULT 5,
    wventana_minutos INTEGER DEFAULT 15
)
RETURNS TABLE(
    tipo               TEXT,
    descripcion        TEXT,
    ip_cliente         VARCHAR,
    id_usuario         VARCHAR,
    fec_evento         TIMESTAMP,
    motivo_fallo       VARCHAR,
    user_agent         VARCHAR,
    intentos_ventana   BIGINT,
    severidad          TEXT
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
            ELSE 'Intento fallido: ' || COALESCE(t.motivo_fallo, '(motivo desconocido)')
        END AS descripcion,
        t.ip_cliente,
        t.id_usuario,
        t.fec_intento AS fec_evento,
        t.motivo_fallo,
        t.user_agent,
        COALESCE(ventana.intentos, 0) AS intentos_ventana,
        CASE
            WHEN bloqueo.ip_cliente IS NOT NULL THEN 'danger'
            WHEN COALESCE(ventana.intentos, 0) >= wmax_intentos THEN 'warning'
            ELSE 'info'
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
    LEFT JOIN (
        SELECT il2.ip_cliente, COUNT(*) AS intentos
        FROM tab_intentos_login il2
        WHERE il2.fec_intento >= NOW() - (wventana_minutos || ' minutes')::INTERVAL
          AND il2.ind_exitoso = FALSE
        GROUP BY il2.ip_cliente
    ) ventana ON ventana.ip_cliente = t.ip_cliente
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
