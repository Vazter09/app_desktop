-- Identifica persona por plantilla de huella (match exacto BYTEA)
-- contra tab_personas.val_huella_digital. Match fuzzy del vendor = fase SDK.
DROP FUNCTION IF EXISTS fun_identificar_persona_por_huella(BYTEA);

CREATE OR REPLACE FUNCTION fun_identificar_persona_por_huella(
    whuella_template tab_personas.val_huella_digital%TYPE
) RETURNS tab_personas.id_persona%TYPE AS $$
DECLARE
    wid_persona  tab_personas.id_persona%TYPE;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF whuella_template IS NULL OR octet_length(whuella_template) < 16 THEN
        PERFORM smartcset_raise_validacion(
            'La plantilla de huella es obligatoria (mín. 16 bytes).'
        );
    END IF;

    SELECT p.id_persona
      INTO wid_persona
      FROM tab_personas p
     WHERE p.val_huella_digital IS NOT NULL
       AND p.ind_estado = TRUE
       AND p.val_huella_digital = whuella_template
     LIMIT 1;

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
