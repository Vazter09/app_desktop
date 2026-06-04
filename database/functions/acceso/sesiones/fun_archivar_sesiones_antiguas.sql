CREATE OR REPLACE FUNCTION fun_archivar_sesiones_antiguas(
    p_dias INTEGER DEFAULT 7
) RETURNS TEXT AS $$
DECLARE
    w_eliminados INTEGER;
BEGIN
    IF p_dias IS NULL OR p_dias < 1 THEN
        PERFORM smartcset_raise_validacion('Los días de retención deben ser al menos 1.');
    END IF;

    INSERT INTO tab_sesiones_archivo (
        id_sesion, id_usuario, fec_inicio, fec_fin, ult_actividad,
        ult_ruta, ult_menu_id, cod_cierre, usr_cierre, ip_cliente
    )
    SELECT
        s.id_sesion, s.id_usuario, s.fec_inicio, s.fec_fin, s.ult_actividad,
        s.ult_ruta, s.ult_menu_id, s.cod_cierre, s.usr_cierre, s.ip_cliente
    FROM tab_sesiones s
    WHERE s.fec_fin IS NOT NULL
      AND s.fec_fin < (CURRENT_TIMESTAMP - (p_dias || ' days')::INTERVAL)
    ON CONFLICT (id_sesion) DO NOTHING;

    DELETE FROM tab_sesiones s
    WHERE s.fec_fin IS NOT NULL
      AND s.fec_fin < (CURRENT_TIMESTAMP - (p_dias || ' days')::INTERVAL)
      AND EXISTS (
          SELECT 1 FROM tab_sesiones_archivo a WHERE a.id_sesion = s.id_sesion
      );

    GET DIAGNOSTICS w_eliminados = ROW_COUNT;

    RETURN w_eliminados::TEXT;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
