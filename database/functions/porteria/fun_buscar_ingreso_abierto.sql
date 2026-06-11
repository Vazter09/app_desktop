-- Devuelve el id del ingreso abierto (fec_salida = fec_ingreso) de una persona, o NULL.
CREATE OR REPLACE FUNCTION fun_buscar_ingreso_abierto(
    wid_visitante tab_log_ingresos.id_visitante%TYPE
) RETURNS INTEGER AS $$
DECLARE
    wid_ingreso INTEGER;
BEGIN
    IF wid_visitante IS NULL OR wid_visitante < 1 THEN
        RETURN NULL;
    END IF;

    SELECT l.id_ingreso
      INTO wid_ingreso
      FROM tab_log_ingresos l
     WHERE l.id_visitante = wid_visitante
       AND l.fec_salida = l.fec_ingreso
     ORDER BY l.fec_ingreso DESC
     LIMIT 1;

    RETURN wid_ingreso;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;
