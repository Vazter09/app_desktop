-- Corrige ingresos que quedaron "abiertos" tras registrar salida porque
-- fec_salida quedó igual (o anterior) a fec_ingreso en la misma transacción o tick de reloj.
-- Criterio: hubo UPDATE (fec_update) pero la visita sigue con fec_salida = fec_ingreso.

UPDATE tab_log_ingresos
   SET fec_salida = GREATEST(
           COALESCE(fec_update, fec_ingreso) + interval '1 microsecond',
           fec_ingreso + interval '1 microsecond'
       )
 WHERE fec_salida <= fec_ingreso
   AND fec_update IS NOT NULL;
