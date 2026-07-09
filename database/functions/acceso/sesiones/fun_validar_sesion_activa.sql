DROP FUNCTION IF EXISTS fun_consultar_sesion_activa(INTEGER, VARCHAR);
DROP FUNCTION IF EXISTS fun_consultar_sesion_activa(INTEGER, TEXT);

CREATE OR REPLACE FUNCTION fun_validar_sesion_activa(
    p_id_sesion tab_sesiones.id_sesion%TYPE,
    p_id_usuario tab_usuarios.id_usuario%TYPE
) RETURNS TEXT AS $$
DECLARE
    w_ult_actividad  tab_sesiones.ult_actividad%TYPE;
    w_exc_state      TEXT;
    w_exc_msg        TEXT;
    w_exc_detail     TEXT;
    w_exc_hint       TEXT;
BEGIN
    IF p_id_sesion IS NULL OR p_id_sesion < 1 THEN
        RETURN NULL;
    END IF;

    IF p_id_usuario IS NULL OR TRIM(p_id_usuario) = '' THEN
        RETURN NULL;
    END IF;

    SELECT s.ult_actividad
    INTO w_ult_actividad
    FROM tab_sesiones s
    WHERE s.id_sesion = p_id_sesion
      AND s.id_usuario = p_id_usuario
      AND s.fec_fin IS NULL;

    IF NOT FOUND OR w_ult_actividad IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN w_ult_actividad::TEXT;
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
