/*
===================================================================================
  SISTEMA DE AUDITORÍA AUTOMÁTICA PARA PostgreSQL
===================================================================================
  Objetivo:
    - Registrar automáticamente todos los INSERT y UPDATE en todas las tablas.
    - Asignar automáticamente las columnas de auditoría:
        usr_insert, fec_insert, usr_update, fec_update.
    - Si no se proporciona un usuario, se asigna 'SISTEMA' (para operaciones
        desde pgAdmin).
    - Validar que los usuarios reales existan en tab_usuarios (excepto 'SISTEMA').
    - Solo auditar en tab_audit_trail cuando haya cambios reales (OLD != NEW).
    - Manejar tablas de solo INSERT (no tienen usr_update) correctamente.
  
  Autor:   Grupo SMARTCSET
  Fecha:   2026-07-08
  Versión: 1.0
=====================================================================================
*/

-- ==================================================================================
-- 1. FUNCIÓN DE TRIGGER PRINCIPAL
-- ==================================================================================
-- Esta función se ejecuta antes de cada INSERT o UPDATE
-- Realiza las siguientes tareas:
--   1. Asigna automáticamente usr_insert/fec_insert en INSERT.
--   2. Asigna automáticamente usr_update/fec_update en UPDATE.
--   3. Si el usuario viene NULL o vacío, lo asigna como 'SISTEMA'.
--   4. Valida que el usuario exista en tab_usuarios (excepto 'SISTEMA').
--   5. Compara OLD y NEW (excluyendo columnas de auditoría) para decidir si auditar.
--   6. Si hay cambios reales, inserta un registro en tab_audit_trail.
-- ===================================================================================
CREATE OR REPLACE FUNCTION fun_audit_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_tiene_update BOOLEAN;                       -- Indica si la tabla tiene columna usr_update
    v_old_json JSONB;                             -- JSON del registro anterior
    v_new_json JSONB;                             -- JSON del registro nuevo
    v_campos_auditoria TEXT[] := ARRAY['usr_insert', 'fec_insert', 'usr_update', 'fec_update']; -- Columnas a excluir de la comparación
BEGIN
    -- ------------------------------------------------------------------------
    -- Determinar si la tabla tiene la columna usr_update.
    -- Esto permite que la misma función maneje tablas con y sin UPDATE.
    -- ------------------------------------------------------------------------
    SELECT COUNT(*) > 0 INTO v_tiene_update
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = TG_TABLE_NAME
      AND column_name = 'usr_update';

    -- ------------------------------------------------------------------------
    -- BLOQUE INSERT
    -- ------------------------------------------------------------------------
    IF TG_OP = 'INSERT' THEN
        -- Si no se proporcionó usr_insert o viene vacío, asignar 'SISTEMA'
        NEW.usr_insert := COALESCE(NULLIF(NEW.usr_insert, ''), 'SISTEMA');
        NEW.fec_insert := CURRENT_TIMESTAMP; -- Fecha y hora actual (zona Colombia)

        -- Validar SOLO si el usuario NO es 'SISTEMA'.
        -- Si la aplicación envía un usuario real, debe existir en tab_usuarios.
        IF NEW.usr_insert != 'SISTEMA' AND NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = NEW.usr_insert) THEN
            RAISE EXCEPTION 'El usuario "%" no existe en tab_usuarios', NEW.usr_insert;
        END IF;

        RETURN NEW; -- Importante: retornar NEW para que se ejecute el INSERT
    END IF;

    -- ------------------------------------------------------------------------
    -- BLOQUE UPDATE
    -- ------------------------------------------------------------------------
    IF TG_OP = 'UPDATE' THEN
        -- Si la tabla no tiene usr_update, lanzar error.
        -- Esto no debería ocurrir porque los triggers de UPDATE solo se crean
        -- en tablas que tienen usr_update.
        IF NOT v_tiene_update THEN
            RAISE EXCEPTION 'La tabla % no permite UPDATE porque no tiene usr_update', TG_TABLE_NAME;
        END IF;

        -- Asignar usr_update y fec_update (con 'SISTEMA' si no se proporcionó)
        NEW.usr_update := COALESCE(NULLIF(NEW.usr_update, ''), 'SISTEMA');
        NEW.fec_update := CURRENT_TIMESTAMP;

        -- Validar SOLO si el usuario NO es 'SISTEMA'
        IF NEW.usr_update != 'SISTEMA' AND NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = NEW.usr_update) THEN
            RAISE EXCEPTION 'El usuario "%" no existe en tab_usuarios', NEW.usr_update;
        END IF;

        -- Convertir OLD y NEW a JSONB y excluir las columnas de auditoría
        -- para que no se consideren como "cambios reales".
        v_old_json := to_jsonb(OLD) - v_campos_auditoria;
        v_new_json := to_jsonb(NEW) - v_campos_auditoria;

        -- Si hay diferencias, insertar en tab_audit_trail
        IF v_old_json <> v_new_json THEN
            INSERT INTO tab_audit_trail
                (id_usuario, nom_operacion, fec_operacion, reg_anterior, reg_nuevo, nom_tabla)
            VALUES
                (NEW.usr_update, 'UPDATE', CURRENT_TIMESTAMP, v_old_json, v_new_json, TG_TABLE_NAME);
        END IF;

        RETURN NEW; -- Importante: retornar NEW para que se ejecute el UPDATE
    END IF;

    -- Si llegamos aquí, significa que la operación no es INSERT ni UPDATE (no debería pasar).
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Comentarios de la función
COMMENT ON FUNCTION fun_audit_trigger() IS 'Función de trigger universal que maneja auditoría para INSERT y UPDATE en todas las tablas. Asigna automáticamente columnas de auditoría y registra cambios en tab_audit_trail.';

-- =======================================================================================
-- 2. AGREGAR COLUMNAS DE AUDITORÍA A TABLAS QUE NO LAS TIENEN
-- =======================================================================================
-- Este bloque agrega las columnas usr_update y fec_update a todas las tablas
-- que tienen usr_insert pero no usr_update, a excepción de:
--   - tab_audit_trail (no se audita a sí misma)
--   - tab_bitacoras, tab_novedades_academicas, tab_causa_novedad (tablas de solo INSERT)
-- =======================================================================================
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT table_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND column_name = 'usr_insert'
          AND table_name NOT IN ('tab_bitacoras', 'tab_novedades_academicas', 'tab_causa_novedad', 'tab_audit_trail')
          AND table_name NOT IN (
              SELECT table_name
              FROM information_schema.columns
              WHERE column_name = 'usr_update'
          )
        GROUP BY table_name
    LOOP
        -- Agregar columna usr_update si no existe
        EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS usr_update VARCHAR(50);', r.table_name);
        -- Agregar columna fec_update si no existe
        EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS fec_update TIMESTAMP WITHOUT TIME ZONE;', r.table_name);
        RAISE NOTICE 'Columnas usr_update y fec_update agregadas a %', r.table_name;
    END LOOP;
END;
$$;

-- ============================================================================
-- 3. ELIMINAR TRIGGERS ANTIGUOS (para empezar limpio)
-- ============================================================================
-- Esto evita duplicados y conflictos con triggers creados anteriormente.
-- ============================================================================
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT tgname, tgrelid::regclass AS table_name
        FROM pg_trigger
        WHERE tgname LIKE 'trg_audit_%' OR tgname LIKE 'tri_audit_%'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %s;', r.tgname, r.table_name);
        RAISE NOTICE 'Eliminado trigger % en %', r.tgname, r.table_name;
    END LOOP;
END;
$$;

-- ============================================================================
-- 4. CREAR TRIGGERS AUTOMÁTICAMENTE EN TODAS LAS TABLAS
-- ============================================================================
-- Este bloque crea triggers en todas las tablas que tienen usr_insert.
-- - Si la tabla tiene usr_update, el trigger escucha INSERT OR UPDATE.
-- - Si no tiene usr_update (tablas de solo INSERT), solo escucha INSERT.
-- ============================================================================
DO $$
DECLARE
    r RECORD;
    v_has_update BOOLEAN;
    v_trigger_events TEXT;
BEGIN
    FOR r IN
        SELECT table_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND column_name = 'usr_insert'
          AND table_name != 'tab_audit_trail'
        GROUP BY table_name
    LOOP
        -- Verificar si la tabla tiene usr_update
        SELECT COUNT(*) > 0 INTO v_has_update
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = r.table_name
          AND column_name = 'usr_update';

        -- Definir eventos según presencia de usr_update
        IF v_has_update THEN
            v_trigger_events := 'INSERT OR UPDATE';
        ELSE
            v_trigger_events := 'INSERT';
        END IF;

        -- Crear el trigger
        EXECUTE format('
            CREATE TRIGGER trg_audit_%I
            BEFORE %s ON %I
            FOR EACH ROW
            EXECUTE FUNCTION fun_audit_trigger();
        ', r.table_name, v_trigger_events, r.table_name);

        RAISE NOTICE 'Trigger trg_audit_% creado en % con eventos %', r.table_name, r.table_name, v_trigger_events;
    END LOOP;
END;
$$;

-- ============================================================================
-- 5. VERIFICACIÓN FINAL (consultas de control)
-- ============================================================================
-- Estas consultas te permiten verificar que todo se haya creado correctamente.
-- ============================================================================

-- 5.1. Listar todos los triggers creados
SELECT 
    tgname AS trigger_name,
    tgrelid::regclass AS table_name,
    CASE 
        WHEN tgtype & 2 = 2 THEN 'INSERT'
        WHEN tgtype & 8 = 8 THEN 'UPDATE'
        WHEN tgtype & 16 = 16 THEN 'DELETE'
    END AS event,
    CASE 
        WHEN tgtype & 2 = 2 AND tgtype & 8 = 8 THEN 'INSERT OR UPDATE'
        ELSE ''
    END AS combined_events
FROM pg_trigger
WHERE tgname LIKE 'trg_audit_%'
ORDER BY table_name, trigger_name;

-- 5.2. Listar tablas con usr_insert y usr_update (para confirmar que no falten)
SELECT 
    table_name,
    EXISTS (SELECT 1 FROM information_schema.columns c2 WHERE c2.table_name = c1.table_name AND c2.column_name = 'usr_update') AS has_usr_update,
    EXISTS (SELECT 1 FROM information_schema.columns c2 WHERE c2.table_name = c1.table_name AND c2.column_name = 'fec_update') AS has_fec_update
FROM information_schema.columns c1
WHERE table_schema = 'public'
  AND column_name = 'usr_insert'
  AND table_name != 'tab_audit_trail'
GROUP BY table_name
ORDER BY table_name;

-- ============================================================================
-- 8. PRUEBAS DE FUNCIONAMIENTO (ejemplos)
-- ============================================================================

/*
-- PRUEBA 1: INSERT en una tabla con usr_update (ej. tab_tipos_docum)
INSERT INTO tab_tipos_docum (id_tipo, descripcion) VALUES ('T01', 'Documento de prueba');
-- Verificar que se asignó usr_insert = 'SISTEMA' y fec_insert = NOW()

-- PRUEBA 2: UPDATE en la misma tabla (cambio real)
UPDATE tab_tipos_docum SET descripcion = 'Documento actualizado' WHERE id_tipo = 'T01';
-- Verificar que se asignó usr_update = 'SISTEMA', fec_update = NOW(),
-- y que hay un registro en tab_audit_trail con OLD y NEW.

-- PRUEBA 3: UPDATE sin cambios reales (solo tocar fec_update)
UPDATE tab_tipos_docum SET fec_update = CURRENT_TIMESTAMP WHERE id_tipo = 'T01';
-- No debe generar registro en tab_audit_trail.

-- PRUEBA 4: INSERT con usuario real (debe existir en tab_usuarios)
INSERT INTO tab_tipos_docum (id_tipo, descripcion, usr_insert) 
VALUES ('T02', 'Con usuario real', 'admin.smart');
-- Si 'admin.smart' no existe en tab_usuarios, debe lanzar error.

-- PRUEBA 5: Tabla de solo INSERT (ej. tab_bitacoras)
INSERT INTO tab_bitacoras (descripcion) VALUES ('Prueba bitácora');
-- Solo debe tener usr_insert, sin usr_update.
-- No debe permitir UPDATE.
*/

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================