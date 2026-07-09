-- ===================================================================
-- Migración: tab_enrolamiento_facial.facial_embedding VECTOR(512) -> VECTOR(128)
-- Motivo: el modelo real elegido para el motor biométrico (SFace,
-- opencv_zoo, vía cv2.FaceRecognizerSF — ya incluido en
-- opencv-python-headless, sin dependencia nueva) entrega vectores de
-- 128 dimensiones, no 512. La tabla se creó antes de tener el modelo
-- real seleccionado (ver REGLAS_APP_ESCRITORIO_SGI.md, decisión #1 de
-- la sección 10) — se ajusta ahora que ya existe, sin costo real
-- porque la tabla todavía no tiene datos de producción.
-- Idempotente: solo altera si la dimensión actual es distinta de 128.
-- ===================================================================

DO $$
DECLARE
    w_dim INTEGER;
BEGIN
    SELECT atttypmod INTO w_dim
    FROM pg_attribute
    WHERE attrelid = 'tab_enrolamiento_facial'::regclass
      AND attname = 'facial_embedding';

    IF w_dim IS DISTINCT FROM 128 THEN
        DROP INDEX IF EXISTS idx_enrolamiento_facial_hnsw;
        ALTER TABLE tab_enrolamiento_facial
            ALTER COLUMN facial_embedding TYPE VECTOR(128);
        CREATE INDEX idx_enrolamiento_facial_hnsw
            ON tab_enrolamiento_facial USING hnsw (facial_embedding vector_cosine_ops);
    END IF;
END $$;
