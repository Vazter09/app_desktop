-- Alinea tab_instructores con schema V.1.10.1: columna ind_vehiculo.
-- En BD institucionales antiguas (p. ej. 10.5.213.111) faltaba; prepare.php
-- ($stmt_buscar_persona_doc / $stmt_biometria_persona_completa) hace
-- LEFT JOIN tab_instructores i y selecciona i.ind_vehiculo — PostgreSQL
-- valida la columna aunque el visitante sea aprendiz (JOIN sin fila).
-- Idempotente.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_instructores'
           AND column_name = 'ind_vehiculo'
    ) THEN
        ALTER TABLE tab_instructores
            ADD COLUMN ind_vehiculo BOOLEAN NOT NULL DEFAULT FALSE;
        COMMENT ON COLUMN tab_instructores.ind_vehiculo IS
            'TRUE=Tiene vehiculo / FALSE=No tiene vehiculo (schema V.1.10.1).';
    END IF;
END $$;
