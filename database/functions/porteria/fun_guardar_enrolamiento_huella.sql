-- Guarda plantilla maestra de huella en tab_personas.val_huella_digital.
DROP FUNCTION IF EXISTS fun_guardar_enrolamiento_huella(NUMERIC, BYTEA, NUMERIC);

CREATE OR REPLACE FUNCTION fun_guardar_enrolamiento_huella(
    wid_persona         tab_personas.id_persona%TYPE,
    whuella_template    tab_personas.val_huella_digital%TYPE,
    wcalidad_huella     NUMERIC DEFAULT NULL
) RETURNS NUMERIC AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    -- wcalidad_huella: compat API; calidad por evento vive en tab_log_ingresos.
    IF NOT EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        PERFORM smartcset_raise_no_encontrado(
            'La persona no está registrada — no se puede enrolar la huella.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;

    IF whuella_template IS NULL OR octet_length(whuella_template) < 16 THEN
        PERFORM smartcset_raise_validacion(
            'La plantilla de huella es obligatoria (mín. 16 bytes).'
        );
    END IF;

    UPDATE tab_personas
       SET val_huella_digital = whuella_template
     WHERE id_persona = wid_persona;

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
