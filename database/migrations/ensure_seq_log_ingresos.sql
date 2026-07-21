-- Secuencia para id_ingreso en tab_log_ingresos (portería).
-- Idempotente: crea si falta y alinea setval al máximo existente.
CREATE SEQUENCE IF NOT EXISTS seq_log_ingresos START WITH 1 INCREMENT BY 1;

DO $$
DECLARE
    v_max BIGINT;
BEGIN
    IF to_regclass('public.tab_log_ingresos') IS NOT NULL THEN
        SELECT COALESCE(MAX(id_ingreso), 0) INTO v_max FROM public.tab_log_ingresos;
        PERFORM setval('public.seq_log_ingresos', GREATEST(v_max, 1), v_max > 0);

        BEGIN
            ALTER SEQUENCE public.seq_log_ingresos
                OWNED BY public.tab_log_ingresos.id_ingreso;
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- ya owned u otra relación
        END;
    END IF;
END $$;
