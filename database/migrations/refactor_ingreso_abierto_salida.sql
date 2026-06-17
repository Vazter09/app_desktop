-- Ingreso abierto: fec_salida = fec_ingreso. Permite varios ciclos ingreso/salida el mismo día.
DROP INDEX IF EXISTS idx_log_ingreso_persona_dia;

CREATE UNIQUE INDEX IF NOT EXISTS idx_log_ingreso_persona_abierto
    ON tab_log_ingresos (id_visitante)
    WHERE (fec_salida = fec_ingreso);

COMMENT ON INDEX idx_log_ingreso_persona_abierto IS
    'Una sola visita abierta por persona (salida pendiente).';
