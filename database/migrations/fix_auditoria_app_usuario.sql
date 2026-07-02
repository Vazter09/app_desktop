-- ===================================================================
-- Migración: fix_auditoria_app_usuario
-- Descripción: Corrige fun_act_tabla() para que las columnas de
--              auditoría (usr_insert, usr_update) registren el usuario
--              real de la aplicación SmartCSET en lugar del usuario de
--              conexión PostgreSQL ('postgres').
--
-- Mecanismo: PostgreSQL permite guardar variables de sesión propias
--            mediante SET app.variable = 'valor'. PHP las setea al
--            inicio de cada request. El trigger las lee con
--            current_setting('app.usuario', TRUE).
--
-- Impacto: Cubre automáticamente las 53 tablas que ya tienen el
--          trigger tri_act_tabla — sin tocar ninguna de ellas.
--
-- Fallback: Si la variable no está seteada (conexión directa desde
--           pgAdmin, scripts de mantenimiento, etc.), el trigger cae
--           en CURRENT_USER = 'postgres'. No hay degradación.
-- ===================================================================

CREATE OR REPLACE FUNCTION public.fun_act_tabla() RETURNS trigger
    LANGUAGE plpgsql AS $$
DECLARE
    w_usuario   TEXT;
    wid_consec  tab_borrados.id_consec%TYPE;
BEGIN
    -- Intenta leer el usuario SmartCSET seteado por PHP en esta sesión.
    -- El segundo argumento TRUE evita error si la variable no existe.
    w_usuario := NULLIF(TRIM(current_setting('app.usuario', TRUE)), '');

    -- Si no hay usuario de app (conexión directa a la BD), usa el
    -- usuario de conexión PostgreSQL como fallback.
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

    IF TG_OP = 'INSERT OR UPDATE' THEN
        SELECT MAX(a.id_consec) INTO wid_consec FROM tab_borrados a;
        IF wid_consec IS NULL THEN
            wid_consec = 1;
        ELSE
            wid_consec = wid_consec + 1;
        END IF;
        INSERT INTO tab_borrados
        VALUES (wid_consec, TG_RELNAME, w_usuario, CURRENT_TIMESTAMP);
        RETURN OLD;
    END IF;
END;
$$;
