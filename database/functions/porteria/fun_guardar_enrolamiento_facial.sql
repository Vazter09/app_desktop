-- Guarda el patrón facial de referencia en tab_personas.val_patron_facial
-- (un vector por persona). Reemplaza el INSERT en tab_enrolamiento_facial.
-- Firma: DROP explícito de firmas viejas (cambio de aridad / tipos).
-- No usar %TYPE de tab_enrolamiento_facial: esa tabla puede no existir.
DROP FUNCTION IF EXISTS fun_guardar_enrolamiento_facial(NUMERIC, VECTOR, NUMERIC);
DROP FUNCTION IF EXISTS fun_guardar_enrolamiento_facial(NUMERIC, VECTOR, NUMERIC, VARCHAR);

CREATE OR REPLACE FUNCTION fun_guardar_enrolamiento_facial(
    wid_persona            tab_personas.id_persona%TYPE,
    wfacial_embedding      tab_personas.val_patron_facial%TYPE,
    wcalidad_facial        NUMERIC DEFAULT NULL,
    wruta_foto_facial      VARCHAR(500) DEFAULT NULL
) RETURNS NUMERIC AS $$
DECLARE
    wusr        TEXT;
    w_exc_state TEXT;
    w_exc_msg   TEXT;
    w_exc_detail TEXT;
    w_exc_hint  TEXT;
BEGIN
    -- wcalidad_facial se acepta por compatibilidad de API; no hay columna
    -- de calidad en tab_personas (queda en el log de cada ingreso).
    IF NOT EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        PERFORM smartcset_raise_no_encontrado(
            'La persona no está registrada — no se puede enrolar.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;

    IF wfacial_embedding IS NULL THEN
        PERFORM smartcset_raise_validacion('El vector facial es obligatorio.');
    END IF;

    -- usr_update explícito: evita que el audit trigger rechace CURRENT_USER
    -- de PostgreSQL ("postgres") que no existe en tab_usuarios.
    wusr := NULLIF(TRIM(current_setting('app.usuario', true)), '');
    IF wusr IS NULL THEN
        PERFORM smartcset_raise_validacion(
            'No hay usuario de auditoría (app.usuario) para enrolar el rostro.'
        );
    END IF;

    UPDATE tab_personas
       SET val_patron_facial = wfacial_embedding,
           ruta_foto_facial = COALESCE(NULLIF(TRIM(wruta_foto_facial), ''), ruta_foto_facial),
           usr_update = wusr
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
