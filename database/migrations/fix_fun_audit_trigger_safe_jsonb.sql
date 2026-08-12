-- ===================================================================
-- Migración: fun_audit_trigger seguro con VECTOR/BYTEA + app.usuario
--
-- Problema: to_jsonb(ROW) falla si hay facial_embedding VECTOR /
--           huella_template BYTEA → tumba UPDATE de salida en
--           tab_log_ingresos (mensaje genérico de BD).
--
-- Fix: convertir a JSONB excluyendo columnas no serializables;
--      si aun así falla, auditar evento mínimo SIN abortar el DML.
-- Idempotente (CREATE OR REPLACE).
-- ===================================================================

CREATE OR REPLACE FUNCTION fun_audit_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_tiene_update BOOLEAN;
    v_old_json JSONB;
    v_new_json JSONB;
    v_excluir TEXT[] := ARRAY[
        'usr_insert', 'fec_insert', 'usr_update', 'fec_update',
        'facial_embedding', 'huella_template', 'val_patron_facial'
    ];
    v_usuario TEXT;
    v_json_ok BOOLEAN := FALSE;
BEGIN
    SELECT COUNT(*) > 0 INTO v_tiene_update
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = TG_TABLE_NAME
      AND column_name = 'usr_update';

    v_usuario := NULLIF(TRIM(current_setting('app.usuario', TRUE)), '');

    IF TG_OP = 'INSERT' THEN
        IF v_usuario IS NULL THEN
            v_usuario := NULLIF(TRIM(COALESCE(NEW.usr_insert, '')), '');
        END IF;
        NEW.usr_insert := COALESCE(v_usuario, 'SISTEMA');
        NEW.fec_insert := CURRENT_TIMESTAMP;

        IF NEW.usr_insert <> 'SISTEMA'
           AND NOT EXISTS (
               SELECT 1 FROM tab_usuarios WHERE id_usuario = NEW.usr_insert
           ) THEN
            RAISE EXCEPTION 'El usuario "%" no existe en tab_usuarios', NEW.usr_insert;
        END IF;

        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF NOT v_tiene_update THEN
            RAISE EXCEPTION
                'La tabla % no permite UPDATE porque no tiene usr_update',
                TG_TABLE_NAME;
        END IF;

        IF v_usuario IS NULL THEN
            v_usuario := NULLIF(TRIM(COALESCE(NEW.usr_update, '')), '');
        END IF;
        NEW.usr_update := COALESCE(v_usuario, 'SISTEMA');
        NEW.fec_update := CURRENT_TIMESTAMP;

        IF NEW.usr_update <> 'SISTEMA'
           AND NOT EXISTS (
               SELECT 1 FROM tab_usuarios WHERE id_usuario = NEW.usr_update
           ) THEN
            RAISE EXCEPTION 'El usuario "%" no existe en tab_usuarios', NEW.usr_update;
        END IF;

        -- Snapshot para tab_audit_trail: NUNCA tumbar el DML operativo.
        BEGIN
            v_old_json := to_jsonb(OLD) - v_excluir;
            v_new_json := to_jsonb(NEW) - v_excluir;
            v_json_ok := TRUE;
        EXCEPTION
            WHEN OTHERS THEN
                v_old_json := jsonb_build_object(
                    '_omit', 'columnas_no_json',
                    '_table', TG_TABLE_NAME
                );
                v_new_json := jsonb_build_object(
                    '_omit', 'columnas_no_json',
                    '_table', TG_TABLE_NAME,
                    '_op', 'UPDATE'
                );
                v_json_ok := FALSE;
        END;

        IF (NOT v_json_ok) OR (v_old_json IS DISTINCT FROM v_new_json) THEN
            INSERT INTO tab_audit_trail
                (id_usuario, nom_operacion, fec_operacion,
                 reg_anterior, reg_nuevo, nom_tabla)
            VALUES
                (NEW.usr_update, 'UPDATE', CURRENT_TIMESTAMP,
                 v_old_json, v_new_json, TG_TABLE_NAME);
        END IF;

        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION fun_audit_trigger() IS
'Auditoría INSERT/UPDATE: app.usuario; JSONB seguro (omite vector/bytea); no bloquea DML.';
