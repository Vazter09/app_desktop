-- Inserta o actualiza una persona en tab_personas (registro portería).
-- La auditoría (usr_insert/usr_update) la gestiona el trigger fun_act_tabla().
CREATE OR REPLACE FUNCTION fun_upsert_persona_visitante(
    wid_persona        tab_personas.id_persona%TYPE,
    wid_tipo_docum     tab_personas.id_tipo_docum%TYPE,
    wid_tipo_persona   tab_personas.id_tipo_persona%TYPE,
    wnom_persona       tab_personas.nom_persona%TYPE,
    wape_persona       tab_personas.ape_persona%TYPE
) RETURNS VOID AS $$
DECLARE
    w_exc_state    TEXT;
    w_exc_msg      TEXT;
    w_exc_detail   TEXT;
    w_exc_hint     TEXT;
BEGIN
    IF wid_persona IS NULL OR wid_persona < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El número de documento no es válido.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wid_tipo_docum IS NULL OR TRIM(wid_tipo_docum) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de documento.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_docum WHERE id_tipo_docum = wid_tipo_docum
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de documento no está registrado en el sistema.',
            'id_tipo_docum=' || wid_tipo_docum
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_persona
        WHERE id_tipo_persona = wid_tipo_persona AND id_tipo_persona <> 99
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de persona no es válido.',
            'id_tipo_persona=' || COALESCE(wid_tipo_persona::TEXT, 'NULL'),
            'Seleccione aprendiz, instructor, visitante u otro tipo habilitado.'
        );
    END IF;

    IF LENGTH(TRIM(wnom_persona)) < 2 OR LENGTH(TRIM(wape_persona)) < 2 THEN
        PERFORM smartcset_raise_validacion(
            'Nombres y apellidos son obligatorios (mínimo 2 caracteres).'
        );
    END IF;

    IF EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        UPDATE tab_personas
        SET id_tipo_docum   = wid_tipo_docum,
            id_tipo_persona = wid_tipo_persona,
            nom_persona     = TRIM(wnom_persona),
            ape_persona     = TRIM(wape_persona)
        WHERE id_persona = wid_persona;
    ELSE
        INSERT INTO tab_personas (
            id_persona, id_tipo_docum, id_tipo_persona,
            nom_persona, ape_persona
        ) VALUES (
            wid_persona, wid_tipo_docum, wid_tipo_persona,
            TRIM(wnom_persona), TRIM(wape_persona)
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
