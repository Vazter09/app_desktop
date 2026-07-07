-- Función: log de actividad física paginado con filtros
-- wzona_horaria ← APP_TIMEZONE: los filtros Desde/Hasta llegan como
-- fechas locales del usuario; fec_ingreso se almacena en la zona de
-- la conexión (DB_TIMEZONE, normalmente UTC), por lo que la
-- comparación de días se hace en la zona local (mismo patrón de
-- fun_siem_list_eventos / fun_siem_dashboard).

-- La firma cambió (se agregó wzona_horaria); PostgreSQL trata
-- distinto número de argumentos como funciones distintas, hay que
-- dropear la firma anterior para no dejar huérfanas (lección E3).
DROP FUNCTION IF EXISTS fun_siem_actividad_fisica(
    DATE, DATE, TEXT, INT, INT
);

CREATE OR REPLACE FUNCTION fun_siem_actividad_fisica(
    wfecha_desde  DATE    DEFAULT NULL,
    wfecha_hasta  DATE    DEFAULT NULL,
    wtipo_persona TEXT    DEFAULT NULL,
    wlimit        INT     DEFAULT 50,
    woffset       INT     DEFAULT 0,
    wzona_horaria TEXT    DEFAULT 'America/Bogota'
) RETURNS TABLE(
    id_log           NUMERIC,
    nom_persona      VARCHAR,
    id_persona       VARCHAR,
    nom_tipo_persona VARCHAR,
    nom_entrada      VARCHAR,
    fec_ingreso      TIMESTAMP,
    fec_salida       TIMESTAMP,
    abierto          BOOLEAN,
    total_filas      BIGINT
) AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        l.id_ingreso::NUMERIC,
        p.nom_persona::VARCHAR,
        l.id_visitante::VARCHAR AS id_persona,
        tp.nom_tipo_persona,
        e.nom_entrada_centro AS nom_entrada,
        l.fec_ingreso,
        l.fec_salida,
        (l.fec_salida = l.fec_ingreso) AS abierto,
        COUNT(*) OVER() AS total_filas
    FROM tab_log_ingresos l
    JOIN tab_personas          p  ON p.id_persona         = l.id_visitante
    JOIN tab_tipos_persona     tp ON tp.id_tipo_persona    = p.id_tipo_persona
    JOIN tab_entradas_centro   e  ON e.id_entrada_centro   = l.id_entrada_centro
    WHERE
        (wfecha_desde IS NULL
         OR (l.fec_ingreso::TIMESTAMPTZ AT TIME ZONE wzona_horaria)::DATE >= wfecha_desde)
        AND (wfecha_hasta IS NULL
             OR (l.fec_ingreso::TIMESTAMPTZ AT TIME ZONE wzona_horaria)::DATE <= wfecha_hasta)
        AND (wtipo_persona IS NULL OR wtipo_persona = ''
             OR tp.nom_tipo_persona ILIKE '%' || wtipo_persona || '%')
    ORDER BY l.fec_ingreso DESC
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
