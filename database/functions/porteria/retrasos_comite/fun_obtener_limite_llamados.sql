-- Límite de llamados (val_max_llamados_aprendiz) para un centro.
CREATE OR REPLACE FUNCTION fun_obtener_limite_llamados(
    p_id_centro tab_pmtros_grales.id_centro%TYPE
) RETURNS SMALLINT AS $$
DECLARE
    v_limite tab_pmtros_grales.val_max_llamados_aprendiz%TYPE;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    SELECT p.val_max_llamados_aprendiz
      INTO v_limite
      FROM tab_pmtros_grales p
     WHERE p.id_centro = p_id_centro;

    IF v_limite IS NULL THEN
        SELECT p.val_max_llamados_aprendiz
          INTO v_limite
          FROM tab_pmtros_grales p
         LIMIT 1;
    END IF;

    RETURN v_limite::SMALLINT;
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
