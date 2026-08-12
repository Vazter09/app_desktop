-- Novedades diarias (motivo del operador) + quitar val_observaciones del log.
-- Idempotente.

CREATE TABLE IF NOT EXISTS tab_novedades_diarias
(
    id_novedad_diaria       BIGSERIAL                   NOT NULL,
    id_ingreso              BIGINT                      NOT NULL,
    motivo_novedad          VARCHAR(100)                NOT NULL CHECK(LENGTH(TRIM(motivo_novedad)) >= 5),
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY(id_novedad_diaria),
    FOREIGN KEY(id_ingreso) REFERENCES tab_log_ingresos(id_ingreso)
);

-- Si la tabla ya existía con INTEGER, alinear a BIGINT (mismo tipo que id_ingreso).
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_novedades_diarias'
           AND column_name = 'id_ingreso'
           AND data_type = 'integer'
    ) THEN
        ALTER TABLE tab_novedades_diarias
            ALTER COLUMN id_ingreso TYPE BIGINT;
    END IF;
END $$;

-- Migrar textos existentes y eliminar columna del log.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_log_ingresos'
           AND column_name = 'val_observaciones'
    ) THEN
        INSERT INTO tab_novedades_diarias (
            id_ingreso, motivo_novedad, usr_insert, fec_insert
        )
        SELECT
            l.id_ingreso,
            LEFT(TRIM(l.val_observaciones), 100),
            COALESCE(NULLIF(TRIM(l.usr_insert), ''), 'migracion'),
            COALESCE(l.fec_insert, CURRENT_TIMESTAMP)
          FROM tab_log_ingresos l
         WHERE l.val_observaciones IS NOT NULL
           AND LENGTH(TRIM(l.val_observaciones)) >= 5
           AND NOT EXISTS (
               SELECT 1
                 FROM tab_novedades_diarias n
                WHERE n.id_ingreso = l.id_ingreso
                  AND n.motivo_novedad = LEFT(TRIM(l.val_observaciones), 100)
           );

        ALTER TABLE tab_log_ingresos DROP COLUMN val_observaciones;
    END IF;
END $$;
