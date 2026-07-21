-- Identifica persona por vector facial contra tab_personas.val_patron_facial
-- (distancia coseno pgvector). Retorna id_persona o NULL si no hay match.
DROP FUNCTION IF EXISTS fun_identificar_persona_por_rostro(VECTOR, NUMERIC);

CREATE OR REPLACE FUNCTION fun_identificar_persona_por_rostro(
    wfacial_embedding    tab_personas.val_patron_facial%TYPE,
    wumbral_distancia    NUMERIC DEFAULT 0.35
) RETURNS tab_personas.id_persona%TYPE AS $$
DECLARE
    wid_persona   tab_personas.id_persona%TYPE;
    wdistancia    NUMERIC;
    w_exc_state   TEXT;
    w_exc_msg     TEXT;
    w_exc_detail  TEXT;
    w_exc_hint    TEXT;
BEGIN
    IF wfacial_embedding IS NULL THEN
        PERFORM smartcset_raise_validacion('El vector facial es obligatorio.');
    END IF;

    SELECT p.id_persona, p.val_patron_facial <=> wfacial_embedding
      INTO wid_persona, wdistancia
      FROM tab_personas p
     WHERE p.val_patron_facial IS NOT NULL
       AND p.ind_estado = TRUE
     ORDER BY p.val_patron_facial <=> wfacial_embedding
     LIMIT 1;

    IF wid_persona IS NULL OR wdistancia > wumbral_distancia THEN
        RETURN NULL;
    END IF;

    RETURN wid_persona;
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
