-- ===================================================================
-- Migración: asegurar tab_log_ingresos.val_datos_origen JSONB
-- Motivo: V.1.10.1 dejó la columna comentada; fun_insert_log_ingreso
--         y fun_registrar_ingreso_manual la requieren.
-- Idempotente.
-- ===================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_log_ingresos'
           AND column_name = 'val_datos_origen'
    ) THEN
        ALTER TABLE public.tab_log_ingresos
            ADD COLUMN val_datos_origen JSONB;
    END IF;
END $$;
