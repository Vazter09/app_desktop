-- OBSOLETO: este índice impedía varios ciclos ingreso/salida el mismo día.
-- Se conserva el archivo solo como referencia histórica; el setup ejecuta fix_idx_log_ingreso_abierto.sql.

DROP INDEX IF EXISTS idx_log_ingreso_persona_dia;
