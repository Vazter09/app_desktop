-- E2 (FASE 1 - Blindaje Técnico Inmediato): Cifrado en reposo de datos sensibles
-- Paso 1: habilitar pgcrypto (puede ya existir, p.ej. usado por fun_actualizar_password)
-- Paso 2: agregar columnas no destructivas para cifrado de documento_identidad
-- La columna original documento_identidad_enc se llena en una migración aparte
-- (migrate_cifrado_documentos.sql) y la columna documento_identidad original
-- se conserva hasta validar el funcionamiento completo del sistema.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE tab_personas
    ADD COLUMN IF NOT EXISTS documento_identidad_enc BYTEA,
    ADD COLUMN IF NOT EXISTS ind_cifrado BOOLEAN NOT NULL DEFAULT FALSE;
