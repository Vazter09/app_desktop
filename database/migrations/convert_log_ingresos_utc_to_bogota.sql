-- Convierte TIMESTAMP naive (UTC wall-clock) de tab_log_ingresos a America/Bogota.
-- Idempotente vía tab_mig_meta. Desactiva triggers de auditoría durante el UPDATE
-- para no romper CHECK (fec_update >= fec_insert).

DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS tab_mig_meta (
        clave TEXT PRIMARY KEY,
        fec_aplicada TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        nota TEXT
    );

    IF EXISTS (
        SELECT 1 FROM tab_mig_meta WHERE clave = 'log_ingresos_utc_to_bogota'
    ) THEN
        RAISE NOTICE 'Migración log_ingresos_utc_to_bogota ya aplicada — skip';
        RETURN;
    END IF;

    ALTER TABLE tab_log_ingresos DISABLE TRIGGER USER;

    UPDATE tab_log_ingresos
       SET fec_ingreso = (fec_ingreso AT TIME ZONE 'UTC') AT TIME ZONE 'America/Bogota',
           fec_salida  = (fec_salida  AT TIME ZONE 'UTC') AT TIME ZONE 'America/Bogota',
           fec_insert  = (fec_insert  AT TIME ZONE 'UTC') AT TIME ZONE 'America/Bogota',
           fec_update  = CASE
               WHEN fec_update IS NULL THEN NULL
               ELSE (fec_update AT TIME ZONE 'UTC') AT TIME ZONE 'America/Bogota'
           END;

    ALTER TABLE tab_log_ingresos ENABLE TRIGGER USER;

    INSERT INTO tab_mig_meta (clave, nota)
    VALUES (
        'log_ingresos_utc_to_bogota',
        'fec_ingreso/fec_salida/fec_insert/fec_update: UTC naive → America/Bogota naive'
    );

    RAISE NOTICE 'OK migración log_ingresos_utc_to_bogota';
END $$;
