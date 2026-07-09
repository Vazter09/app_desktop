CREATE OR REPLACE FUNCTION fun_actualizar_sesion_actividad(
    p_id_sesion tab_sesiones.id_sesion%TYPE,
    p_ult_ruta tab_sesiones.ult_ruta%TYPE DEFAULT NULL,
    p_ult_menu_id tab_sesiones.ult_menu_id%TYPE DEFAULT NULL
) RETURNS TEXT AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
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
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;
