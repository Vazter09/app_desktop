-- Identifica a la persona más parecida a un vector facial (vecino más cercano
-- por distancia coseno). Llamado desde backend/services/porteria/biometria_service.php.
CREATE OR REPLACE FUNCTION fun_identificar_persona_por_rostro(
    wvector_facial TEXT
) RETURNS TABLE (
    id_persona_encontrado tab_personas.id_persona%TYPE,
    distancia_calculada    DOUBLE PRECISION
) AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT b.id_persona,
           (b.vector_facial <=> wvector_facial::vector)::DOUBLE PRECISION
    FROM tab_biometria_facial b
    ORDER BY b.vector_facial <=> wvector_facial::vector
    LIMIT 1;
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
