-- ===================================================================
-- Migración: asegurar fun_act_tabla + trigger en tab_log_ingresos
-- Idempotente. Sin dependencia de tab_borrados (puede no existir).
-- ===================================================================

CREATE OR REPLACE FUNCTION public.fun_act_tabla() RETURNS trigger
    LANGUAGE plpgsql AS $$
DECLARE
    w_usuario TEXT;
BEGIN
    w_usuario := NULLIF(TRIM(current_setting('app.usuario', TRUE)), '');

    IF w_usuario IS NULL THEN
        w_usuario := CURRENT_USER;
    END IF;

    IF TG_OP = 'INSERT' THEN
        NEW.usr_insert = w_usuario;
        NEW.fec_insert = CURRENT_TIMESTAMP;
        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        NEW.usr_update = w_usuario;
        NEW.fec_update = CURRENT_TIMESTAMP;
        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS tri_act_tabla ON public.tab_log_ingresos;
CREATE TRIGGER tri_act_tabla
    BEFORE INSERT OR UPDATE ON public.tab_log_ingresos
    FOR EACH ROW
    EXECUTE FUNCTION public.fun_act_tabla();

DROP TRIGGER IF EXISTS tri_act_tabla ON public.tab_personas;
CREATE TRIGGER tri_act_tabla
    BEFORE INSERT OR UPDATE ON public.tab_personas
    FOR EACH ROW
    EXECUTE FUNCTION public.fun_act_tabla();
