-- ===================================================================
-- Migración: biometría facial en tab_personas + tab_novedades_ingreso
-- - val_patron_facial / facial_embedding → VECTOR(128) (SFace)
-- - ruta_foto_facial en tab_personas (antes en tab_enrolamiento_facial)
-- - tab_novedades_ingreso (idempotente; ya puede existir en servidor)
-- - Copia datos activos desde tab_enrolamiento_facial si existe
-- ===================================================================

CREATE EXTENSION IF NOT EXISTS vector;

-- ---- tab_personas.val_patron_facial → VECTOR(128) --------------------
DO $$
DECLARE
    wtyp TEXT;
    wdim INT;
BEGIN
    SELECT t.typname, a.atttypmod
      INTO wtyp, wdim
      FROM pg_attribute a
      JOIN pg_type t ON t.oid = a.atttypid
     WHERE a.attrelid = 'tab_personas'::regclass
       AND a.attname = 'val_patron_facial'
       AND a.attnum > 0
       AND NOT a.attisdropped;

    IF wtyp IS NULL THEN
        ALTER TABLE tab_personas
            ADD COLUMN val_patron_facial VECTOR(128);
    ELSIF wtyp = 'jsonb' THEN
        ALTER TABLE tab_personas DROP COLUMN val_patron_facial;
        ALTER TABLE tab_personas
            ADD COLUMN val_patron_facial VECTOR(128);
    ELSIF wtyp = 'vector' AND (wdim IS DISTINCT FROM 128) THEN
        -- atttypmod para vector(n) es n+4 en pgvector; si no coincide, recrear
        ALTER TABLE tab_personas
            ALTER COLUMN val_patron_facial TYPE VECTOR(128)
            USING CASE
                WHEN val_patron_facial IS NULL THEN NULL
                WHEN vector_dims(val_patron_facial::vector) = 128
                    THEN val_patron_facial::vector(128)
                ELSE NULL
            END;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_name = 'tab_personas'
           AND column_name = 'ruta_foto_facial'
    ) THEN
        ALTER TABLE tab_personas
            ADD COLUMN ruta_foto_facial VARCHAR(500) NULL;
        COMMENT ON COLUMN tab_personas.ruta_foto_facial IS
            'Ruta relativa de la foto de enrolamiento facial (filesystem).';
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_personas_patron_facial_hnsw
    ON tab_personas USING hnsw (val_patron_facial vector_cosine_ops)
    WHERE val_patron_facial IS NOT NULL;

-- ---- tab_log_ingresos.facial_embedding → VECTOR(128) -----------------
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_name = 'tab_log_ingresos'
           AND column_name = 'facial_embedding'
    ) THEN
        BEGIN
            ALTER TABLE tab_log_ingresos
                ALTER COLUMN facial_embedding TYPE VECTOR(128)
                USING CASE
                    WHEN facial_embedding IS NULL THEN NULL
                    WHEN vector_dims(facial_embedding::vector) = 128
                        THEN facial_embedding::vector(128)
                    ELSE NULL
                END;
        EXCEPTION
            WHEN OTHERS THEN
                -- Si hay vectores 512 incompatibles, anular y tipar limpio
                UPDATE tab_log_ingresos SET facial_embedding = NULL
                 WHERE facial_embedding IS NOT NULL
                   AND vector_dims(facial_embedding::vector) <> 128;
                ALTER TABLE tab_log_ingresos
                    ALTER COLUMN facial_embedding TYPE VECTOR(128);
        END;
    ELSE
        ALTER TABLE tab_log_ingresos
            ADD COLUMN facial_embedding VECTOR(128);
    END IF;
END $$;

-- ---- tab_novedades_ingreso (personas no registradas) -----------------
CREATE SEQUENCE IF NOT EXISTS seq_novedades_ingreso
    START WITH 1 INCREMENT BY 1;

-- Estructura alineada con el servidor institucional (VECTOR tipado a 128 abajo).
CREATE TABLE IF NOT EXISTS tab_novedades_ingreso
(
    id_novedad          DECIMAL(10,0)               NOT NULL,
    nom_tercero         VARCHAR(40)                 NOT NULL CHECK(LENGTH(TRIM(nom_tercero)) >= 3),
    ape_tercero         VARCHAR(30)                 NOT NULL CHECK(LENGTH(TRIM(ape_tercero)) >= 2),
    id_entrada_centro   DECIMAL(1,0)                NOT NULL,
    val_huella_digital  BYTEA,
    val_patron_facial   VECTOR,
    uri_imagen_huella   VARCHAR(500),
    uri_foto_facial     VARCHAR(500),
    fec_ingreso         TIMESTAMP                   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fec_salida          TIMESTAMP                   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usr_insert          VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert          TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY (id_novedad),
    FOREIGN KEY(id_entrada_centro)  REFERENCES tab_entradas_centro(id_entrada_centro)
);

-- Si la tabla ya existía con VECTOR sin dimensión, tipar a 128
DO $$
BEGIN
    BEGIN
        ALTER TABLE tab_novedades_ingreso
            ALTER COLUMN val_patron_facial TYPE VECTOR(128)
            USING CASE
                WHEN val_patron_facial IS NULL THEN NULL
                WHEN vector_dims(val_patron_facial::vector) = 128
                    THEN val_patron_facial::vector(128)
                ELSE NULL
            END;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;
END $$;

-- Migrar enrolamientos activos → tab_personas (si la tabla legacy existe)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
         WHERE table_name = 'tab_enrolamiento_facial'
    ) THEN
        UPDATE tab_personas p
           SET val_patron_facial = e.facial_embedding,
               ruta_foto_facial = COALESCE(p.ruta_foto_facial, e.ruta_foto_enrolamiento)
          FROM (
                SELECT DISTINCT ON (id_persona)
                       id_persona,
                       facial_embedding,
                       ruta_foto_enrolamiento
                  FROM tab_enrolamiento_facial
                 WHERE ind_activo = TRUE
                   AND facial_embedding IS NOT NULL
                   AND vector_dims(facial_embedding::vector) = 128
                 ORDER BY id_persona, fec_insert DESC
          ) e
         WHERE p.id_persona = e.id_persona
           AND p.val_patron_facial IS NULL;
    END IF;
END $$;
