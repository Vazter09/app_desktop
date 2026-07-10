-- Trae al schema los 2 objetos nuevos de la reconciliación con
-- origin/main (merge feat/implementacion_MSPI, 2026-07-09): columna
-- id_motivo en tab_llamados_atencion + tabla tab_comite_aprendices
-- completa. Idempotente — seguro correr en una BD que ya los tenga
-- (instalación limpia futura) o que aún no (BD existente a actualizar).

ALTER TABLE tab_llamados_atencion
    ADD COLUMN IF NOT EXISTS id_motivo SMALLINT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'tab_llamados_atencion_id_motivo_fkey'
          AND table_name = 'tab_llamados_atencion'
    ) THEN
        ALTER TABLE tab_llamados_atencion
            ADD CONSTRAINT tab_llamados_atencion_id_motivo_fkey
            FOREIGN KEY (id_motivo) REFERENCES tab_motivos(id_motivo);
    END IF;
END $$;

ALTER TABLE tab_llamados_atencion
    ALTER COLUMN id_motivo SET NOT NULL;

CREATE TABLE IF NOT EXISTS tab_comite_aprendices
(
    id_comite               SERIAL                      NOT NULL,
    id_implicado            DECIMAL(10,0)               NOT NULL,
    responsable_comite      DECIMAL(10,0)               NOT NULL,
    ciclo_comite            SMALLINT                    NOT NULL DEFAULT 0,
    estado_comite           DECIMAL(1,0)                NOT NULL DEFAULT 0,
    observacion_comite      TEXT                        NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_comite)
);

CREATE INDEX IF NOT EXISTS idx_comite_implicado ON tab_comite_aprendices (id_implicado);
CREATE INDEX IF NOT EXISTS idx_comite_estado ON tab_comite_aprendices (estado_comite);

DROP TRIGGER IF EXISTS tri_act_tabla ON tab_comite_aprendices;
CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_comite_aprendices
    FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
