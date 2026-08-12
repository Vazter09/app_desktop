-- Corrige solo filas con fec_ingreso "en el futuro" respecto a hora Bogotá
-- (reloj UTC naive legado). No toca filas ya en hora civil Colombia.
-- Idempotente: tras corregir, fec_ingreso deja de estar en el futuro.

DO $$
DECLARE
    w_now TIMESTAMP WITHOUT TIME ZONE := (
        CURRENT_TIMESTAMP AT TIME ZONE 'America/Bogota'
    );
    w_rows INTEGER;
BEGIN
    ALTER TABLE tab_log_ingresos DISABLE TRIGGER USER;

    UPDATE tab_log_ingresos
       SET fec_ingreso = (fec_ingreso AT TIME ZONE 'UTC')
                         AT TIME ZONE 'America/Bogota',
           fec_salida = CASE
               WHEN fec_salida = fec_ingreso THEN
                   (fec_ingreso AT TIME ZONE 'UTC')
                   AT TIME ZONE 'America/Bogota'
               WHEN fec_salida > w_now + interval '15 minutes' THEN
                   (fec_salida AT TIME ZONE 'UTC')
                   AT TIME ZONE 'America/Bogota'
               ELSE
                   fec_salida
           END
     WHERE fec_ingreso > w_now + interval '15 minutes';

    GET DIAGNOSTICS w_rows = ROW_COUNT;

    ALTER TABLE tab_log_ingresos ENABLE TRIGGER USER;

    RAISE NOTICE 'OK fix_log_ingresos_utc_futuros: % filas', w_rows;
END $$;
