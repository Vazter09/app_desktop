-- Enrola/actualiza el registro biométrico facial de una persona (upsert por id_persona).
-- Llamado desde backend/services/porteria/biometria_service.php.
CREATE OR REPLACE PROCEDURE fun_guardar_biometria_facial(
    wid_persona      tab_personas.id_persona%TYPE,
    wvector_facial   TEXT,
    wuri_foto        TEXT,
    wcalidad_facial  NUMERIC
) LANGUAGE plpgsql AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        PERFORM smartcset_raise_validacion(
            'La persona no existe en el sistema. Debe estar registrada antes de enrolar su biometría.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    INSERT INTO tab_biometria_facial (
        id_persona, vector_facial, uri_foto, calidad_facial
    ) VALUES (
        wid_persona, wvector_facial::vector, wuri_foto, wcalidad_facial
    )
    ON CONFLICT (id_persona) DO UPDATE SET
        vector_facial  = EXCLUDED.vector_facial,
        uri_foto       = EXCLUDED.uri_foto,
        calidad_facial = EXCLUDED.calidad_facial;
    -- usr_insert/usr_update/fec_* los gestiona el trigger tri_act_tabla (fun_act_tabla).
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
$$;
