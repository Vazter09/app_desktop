-- Recuenta llamados de atención del aprendiz en tab_aprendices.num_llamados.
CREATE OR REPLACE FUNCTION fun_actualizar_num_llamados(
    p_id_aprendiz tab_aprendices.id_aprendiz%TYPE
) RETURNS VOID AS $$
DECLARE
    v_total      INTEGER;
    v_usr_update TEXT;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    v_usr_update := NULLIF(TRIM(current_setting('app.usuario', true)), '');
    IF v_usr_update IS NULL THEN
        RETURN;
    END IF;

    SELECT COUNT(*)::INTEGER
      INTO v_total
      FROM tab_llamados_atencion
     WHERE id_tercero = p_id_aprendiz
       AND ind_tipo_tercero = TRUE;

    UPDATE tab_aprendices
       SET num_llamados = v_total,
           usr_update = v_usr_update,
           fec_update = CURRENT_TIMESTAMP
     WHERE id_aprendiz = p_id_aprendiz;
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
