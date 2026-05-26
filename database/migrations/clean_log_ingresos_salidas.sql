-- Limpia registros operativos de ingreso/salida (portería).
-- No elimina personas, puertas ni menús.

DELETE FROM tab_log_ingresos;

SELECT setval('seq_log_ingresos', 1, false);
