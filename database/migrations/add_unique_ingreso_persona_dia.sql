-- Una persona no puede tener dos ingresos el mismo día calendario (validación en BD).
-- Ejecutar una vez en db_smartcset después de desplegar fun_insert_log_ingreso.sql

-- Conservar el ingreso más antiguo del día si ya hay duplicados históricos
DELETE FROM tab_log_ingresos a
USING tab_log_ingresos b
WHERE a.id_visitante = b.id_visitante
  AND a.fec_ingreso::date = b.fec_ingreso::date
  AND a.id_ingreso > b.id_ingreso;

CREATE UNIQUE INDEX IF NOT EXISTS idx_log_ingreso_persona_dia
    ON tab_log_ingresos (id_visitante, (fec_ingreso::date));

COMMENT ON INDEX idx_log_ingreso_persona_dia IS
    'Impide más de un ingreso por persona en la misma fecha (fec_ingreso).';
