-- Biometría facial de portería (app de escritorio, PC dedicado — ver
-- reconocimientio_facial/Desktop/). Tabla standalone enlazada a tab_personas
-- por id_persona (no por cédula suelta) para evitar datos huérfanos.
-- Requiere extensión pgvector.

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS tab_biometria_facial (
    id_biometria    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona      NUMERIC(10,0) NOT NULL UNIQUE,
    vector_facial   vector(512) NOT NULL,
    uri_foto        TEXT,
    calidad_facial  NUMERIC(5,2) DEFAULT 0,
    usr_insert      VARCHAR(50) NOT NULL CHECK (LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert      TIMESTAMP NOT NULL,
    usr_update      VARCHAR(50) CHECK (LENGTH(TRIM(usr_update)) >= 3),
    fec_update      TIMESTAMP,
    CONSTRAINT fk_biometria_persona
        FOREIGN KEY (id_persona) REFERENCES tab_personas (id_persona)
);

CREATE INDEX IF NOT EXISTS idx_biometria_vector
    ON tab_biometria_facial
    USING hnsw (vector_facial vector_cosine_ops);

DROP TRIGGER IF EXISTS tri_act_tabla ON tab_biometria_facial;
CREATE TRIGGER tri_act_tabla
    BEFORE INSERT OR UPDATE ON tab_biometria_facial
    FOR EACH ROW EXECUTE FUNCTION fun_act_tabla();
