-- Centro de formación del aprendiz (vía ficha vigente).
CREATE OR REPLACE FUNCTION fun_obtener_centro_aprendiz(
    p_id_aprendiz tab_aprendices.id_aprendiz%TYPE
) RETURNS tab_fichas.id_centro%TYPE AS $$
DECLARE
    v_id_centro tab_fichas.id_centro%TYPE;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    SELECT f.id_centro
      INTO v_id_centro
      FROM tab_aprendices a
      JOIN tab_fichas f ON f.id_ficha = a.id_ficha
     WHERE a.id_aprendiz = p_id_aprendiz;

    RETURN v_id_centro;
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
