CREATE OR REPLACE FUNCTION fun_actualizar_sesion_actividad(
    p_id_sesion tab_sesiones.id_sesion%TYPE,
    p_ult_ruta tab_sesiones.ult_ruta%TYPE DEFAULT NULL,
    p_ult_menu_id tab_sesiones.ult_menu_id%TYPE DEFAULT NULL
) RETURNS TEXT AS $$
BEGIN
    IF p_id_sesion IS NULL OR p_id_sesion < 1 THEN
        RETURN 'OK';
    END IF;

    UPDATE tab_sesiones
    SET ult_actividad = CURRENT_TIMESTAMP,
        ult_ruta = COALESCE(NULLIF(TRIM(p_ult_ruta), ''), ult_ruta),
        ult_menu_id = COALESCE(NULLIF(TRIM(p_ult_menu_id), ''), ult_menu_id)
    WHERE id_sesion = p_id_sesion
      AND fec_fin IS NULL;

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
