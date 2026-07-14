/*
================================================================================
TRIGGER PARA CONTROLAR EL DATO DE fec_salida.
================================================================================
OBJETIVO: Validar que la fecha de salida (fec_salida) sea al menos 5 minutos
          posterior a la fecha de ingreso (fec_ingreso) cuando se actualiza.

AUTOR:       Grupo SMARTCSET
FECHA:       2026-07-14
VERSIÓN:     1.0
================================================================================
*/

-- =============================================================================
-- 1. FUNCIÓN DEL TRIGGER
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_validar_fec_salida()
RETURNS TRIGGER AS $$
DECLARE
    v_diferencia_minutos NUMERIC;
BEGIN
    /*
        Cálculo de la diferencia en minutos:
        - EXTRACT(EPOCH FROM ...) devuelve la diferencia en segundos.
        - Dividiendo entre 60 obtenemos minutos.
        - Se usa OLD.fec_ingreso porque es el valor almacenado.
        - NEW.fec_salida es el nuevo valor propuesto.
    */
    v_diferencia_minutos := EXTRACT(EPOCH FROM (NEW.fec_salida - OLD.fec_ingreso)) / 60;

    -- Validación estricta: la diferencia debe ser mayor a 5 minutos.
    IF v_diferencia_minutos <= 5 THEN
        RAISE EXCEPTION 'La fecha de salida (%) debe ser al menos 5 minutos posterior a la fecha de ingreso (%). Diferencia actual: % minutos.',
                        NEW.fec_salida, OLD.fec_ingreso, v_diferencia_minutos;
    END IF;

    -- Si la validación pasa, se permite la actualización.
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 2. CREACIÓN DEL TRIGGER
-- =============================================================================
CREATE TRIGGER trg_validar_fec_salida
    BEFORE UPDATE OF fec_salida ON tab_log_ingresos
    FOR EACH ROW
    EXECUTE FUNCTION fn_validar_fec_salida();

-- =============================================================================
-- 3. PRUEBAS DE VALIDACIÓN (ejemplos comentados)
-- =============================================================================
/*
-- Suponiendo un registro con fec_ingreso = '2026-07-14 10:00:00'

-- CASO VÁLIDO (diferencia 6 minutos)
UPDATE tab_log_ingresos SET fec_salida = '2026-07-14 10:06:00' WHERE id_ingreso = 1;
-- Resultado: Éxito (trigger permite el cambio)

-- CASO INVÁLIDO (diferencia 2 minutos exactos)
UPDATE tab_log_ingresos SET fec_salida = '2026-07-14 10:02:00' WHERE id_ingreso = 1;
-- Resultado: ERROR - "La fecha de salida (2026-07-14 10:02:00) debe ser al menos 5 minutos posterior..."

-- CASO INVÁLIDO (diferencia 1 minuto)
UPDATE tab_log_ingresos SET fec_salida = '2026-07-14 10:01:00' WHERE id_ingreso = 1;
-- Resultado: ERROR

-- CASO INVÁLIDO (fecha anterior al ingreso)
UPDATE tab_log_ingresos SET fec_salida = '2026-07-14 09:59:00' WHERE id_ingreso = 1;
-- Resultado: ERROR

-- Actualización de otra columna (NO dispara el trigger)
UPDATE tab_log_ingresos SET val_observaciones = 'Salida manual' WHERE id_ingreso = 1;
-- Resultado: Éxito (trigger no se ejecuta porque no se modifica fec_salida)
*/

-- =============================================================================
-- FIN DEL SCRIPT
-- =============================================================================