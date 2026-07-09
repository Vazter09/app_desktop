CREATE OR REPLACE FUNCTION fun_salida_sesion(
    p_id_sesion tab_sesiones.id_sesion%TYPE,
    p_cod_cierre tab_sesiones.cod_cierre%TYPE,
    p_usr_cierre tab_sesiones.usr_cierre%TYPE DEFAULT NULL
) RETURNS TEXT AS $$
DECLARE
    w_cod        tab_sesiones.cod_cierre%TYPE;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF p_id_sesion IS NULL OR p_id_sesion < 1 THEN
        PERFORM smartcset_raise_validacion('El identificador de sesión es obligatorio.');
    END IF;

    w_cod := UPPER(NULLIF(TRIM(p_cod_cierre), ''));
    IF w_cod IS NULL OR w_cod NOT IN ('LOGOUT', 'ADMIN', 'TIMEOUT', 'IP_MISMATCH') THEN
        PERFORM smartcset_raise_validacion('Código de cierre de sesión no válido.');
    END IF;

    UPDATE tab_sesiones
    SET fec_fin = CURRENT_TIMESTAMP,
        cod_cierre = w_cod,
        usr_cierre = NULLIF(TRIM(p_usr_cierre), '')
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
