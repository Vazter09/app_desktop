-- Migración: Agregar columna ruta_foto_enrolamiento a tab_enrolamiento_facial
-- Propósito: Guardar ruta a la foto de enrolamiento (relativa a document root)
-- Formato ruta: "uploads/biometria/{id_persona}/{id_persona}_{nombre}.jpg"
-- Estado: Idempotente

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'tab_enrolamiento_facial'
        AND column_name = 'ruta_foto_enrolamiento'
    ) THEN
        ALTER TABLE tab_enrolamiento_facial
        ADD COLUMN ruta_foto_enrolamiento VARCHAR(500) NULL;

        COMMENT ON COLUMN tab_enrolamiento_facial.ruta_foto_enrolamiento IS
            'Ruta relativa a foto de enrolamiento (relativa a document root). Ej: uploads/biometria/12345/12345_juan.jpg';
    END IF;
END $$;
