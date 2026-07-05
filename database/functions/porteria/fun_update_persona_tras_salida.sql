-- Actualiza estadísticas de visita tras registrar una salida.
-- La auditoría (usr_update) la gestiona el trigger fun_act_tabla().
CREATE OR REPLACE FUNCTION fun_update_persona_tras_salida(
    wid_persona tab_personas.id_persona%TYPE
) RETURNS VOID AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    UPDATE tab_personas
    SET fec_ultima_salida = CURRENT_TIMESTAMP
    WHERE id_persona = wid_persona;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'No se encontró el visitante para actualizar la salida.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;
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
