-- ===================================================================
-- Migración: tab_enrolamiento_facial
-- Descripción: Tabla de referencia biométrica facial por persona
--              (pgvector, ya instalado — extensión "vector" v0.8.1).
--              NO reutiliza tab_log_ingresos.facial_embedding (esa es
--              histórica por evento de ingreso, no un vector de
--              referencia estable por persona) — ver
--              REGLAS_APP_ESCRITORIO_SGI.md sección 6.1.
-- Idempotente: seguro de re-ejecutar contra una BD que ya la tenga.
-- ===================================================================

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS tab_enrolamiento_facial (
    id_enrolamiento    SERIAL PRIMARY KEY,
    id_persona         NUMERIC(10,0) NOT NULL REFERENCES tab_personas(id_persona),
    facial_embedding   VECTOR(512) NOT NULL,
    calidad_facial     NUMERIC(5,2),
    ind_activo         BOOLEAN NOT NULL DEFAULT TRUE,
    usr_insert         VARCHAR(50) NOT NULL,
    fec_insert         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usr_update         VARCHAR(50),
    fec_update         TIMESTAMP,
    CONSTRAINT tab_enrolamiento_facial_calidad_check
        CHECK (calidad_facial IS NULL OR (calidad_facial >= 0 AND calidad_facial <= 100)),
    CONSTRAINT tab_enrolamiento_facial_usr_insert_check
        CHECK (length(TRIM(usr_insert)) >= 3)
);

CREATE INDEX IF NOT EXISTS idx_enrolamiento_facial_persona
    ON tab_enrolamiento_facial (id_persona) WHERE ind_activo = TRUE;

-- Índice HNSW para búsqueda por similitud (distancia coseno) — igual
-- patrón que se usaría en cualquier búsqueda de vecino más cercano.
CREATE INDEX IF NOT EXISTS idx_enrolamiento_facial_hnsw
    ON tab_enrolamiento_facial USING hnsw (facial_embedding vector_cosine_ops);

-- Auditoría automática (usr_insert/usr_update vía app.usuario, mismo
-- patrón que el resto del proyecto — ver fun_act_tabla()).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'tri_act_tabla'
          AND tgrelid = 'tab_enrolamiento_facial'::regclass
    ) THEN
        CREATE TRIGGER tri_act_tabla
            BEFORE INSERT OR UPDATE ON tab_enrolamiento_facial
            FOR EACH ROW EXECUTE FUNCTION fun_act_tabla();
    END IF;
END $$;
