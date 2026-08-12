-- Reloj de aplicación para columnas TIMESTAMP WITHOUT TIME ZONE.
-- No depende del TimeZone de la sesión PostgreSQL (suele ser UTC en el host).
-- Equivale a la hora civil de Colombia (America/Bogota, UTC-5 sin DST).
DROP FUNCTION IF EXISTS smartcset_now_local();

CREATE OR REPLACE FUNCTION smartcset_now_local()
RETURNS TIMESTAMP WITHOUT TIME ZONE
LANGUAGE sql
STABLE
AS $$
    SELECT (CURRENT_TIMESTAMP AT TIME ZONE 'America/Bogota');
$$;

COMMENT ON FUNCTION smartcset_now_local() IS
    'Ahora en America/Bogota como timestamp sin zona (tab_log_ingresos, auditoría local).';
