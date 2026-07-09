-- Identifica una persona por su vector facial: compara contra todos los
-- enrolamientos activos (distancia coseno, pgvector) y retorna
-- id_persona SOLO si la menor distancia está dentro del umbral. Si no
-- hay match dentro del umbral, retorna NULL (no lanza excepción — "no
-- encontrado" es una respuesta válida de este flujo, no un error).
CREATE OR REPLACE FUNCTION fun_identificar_persona_por_rostro(
    wfacial_embedding    tab_enrolamiento_facial.facial_embedding%TYPE,
    wumbral_distancia    NUMERIC DEFAULT 0.35
) RETURNS tab_enrolamiento_facial.id_persona%TYPE AS $$
DECLARE
    wid_persona   tab_enrolamiento_facial.id_persona%TYPE;
    wdistancia    NUMERIC;
    w_exc_state   TEXT;
    w_exc_msg     TEXT;
    w_exc_detail  TEXT;
    w_exc_hint    TEXT;
BEGIN
    IF wfacial_embedding IS NULL THEN
        PERFORM smartcset_raise_validacion('El vector facial es obligatorio.');
    END IF;

    SELECT id_persona, facial_embedding <=> wfacial_embedding
        INTO wid_persona, wdistancia
        FROM tab_enrolamiento_facial
        WHERE ind_activo = TRUE
        ORDER BY facial_embedding <=> wfacial_embedding
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
