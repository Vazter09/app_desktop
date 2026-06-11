-- Corrige índice erróneo que impedía más de un ingreso por día aunque la salida estuviera cerrada.
-- Debe ejecutarse después de add_unique_ingreso_persona_dia.sql en instalaciones antiguas.

DROP INDEX IF EXISTS idx_log_ingreso_persona_dia;

CREATE UNIQUE INDEX IF NOT EXISTS idx_log_ingreso_persona_abierto
    ON tab_log_ingresos (id_visitante)
    WHERE (fec_salida = fec_ingreso);

COMMENT ON INDEX idx_log_ingreso_persona_abierto IS
    'Una sola visita abierta por persona (salida pendiente).';
