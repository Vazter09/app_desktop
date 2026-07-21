-- Alinea fec_ultima_entrada/salida de personas a America/Bogota (UTC residual)
-- y evita CHECK fec_ultima_salida >= fec_ultima_entrada tras el cambio de TZ.
DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS tab_mig_meta (
        clave TEXT PRIMARY KEY,
        fec_aplicada TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        nota TEXT
    );

    IF EXISTS (
        SELECT 1 FROM tab_mig_meta WHERE clave = 'personas_fec_ultima_utc_to_bogota'
    ) THEN
        RAISE NOTICE 'Migración personas_fec_ultima_utc_to_bogota ya aplicada — skip';
        RETURN;
    END IF;

    ALTER TABLE tab_personas DISABLE TRIGGER USER;

    UPDATE tab_personas
       SET fec_ultima_entrada = (fec_ultima_entrada AT TIME ZONE 'UTC')
                                AT TIME ZONE 'America/Bogota',
           fec_ultima_salida  = (fec_ultima_salida AT TIME ZONE 'UTC')
                                AT TIME ZONE 'America/Bogota';

    -- Por si alguna fila quedó inconsistente tras conversiones parciales.
    UPDATE tab_personas
       SET fec_ultima_salida = fec_ultima_entrada
     WHERE fec_ultima_salida < fec_ultima_entrada;

    ALTER TABLE tab_personas ENABLE TRIGGER USER;

    INSERT INTO tab_mig_meta (clave, nota)
    VALUES (
        'personas_fec_ultima_utc_to_bogota',
        'fec_ultima_entrada/salida: UTC naive → America/Bogota + fix CHECK'
    );

    RAISE NOTICE 'OK migración personas_fec_ultima_utc_to_bogota';
END $$;
