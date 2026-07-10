-- Proceso atómico: visitante + ingreso. Opcional: vector facial del evento.
DROP FUNCTION IF EXISTS fun_registrar_ingreso_manual(
    tab_personas.id_persona%TYPE,
    tab_personas.id_tipo_docum%TYPE,
    tab_personas.id_tipo_persona%TYPE,
    tab_personas.nom_persona%TYPE,
    tab_personas.ape_persona%TYPE,
    tab_log_ingresos.id_entrada_centro%TYPE,
    tab_log_ingresos.val_observaciones%TYPE,
    tab_log_ingresos.id_metodo_aut%TYPE,
    BOOLEAN
);
DROP FUNCTION IF EXISTS fun_registrar_ingreso_manual(
    NUMERIC, VARCHAR, NUMERIC, VARCHAR, VARCHAR,
    NUMERIC, TEXT, DECIMAL, BOOLEAN
);
DROP FUNCTION IF EXISTS fun_registrar_ingreso_manual(
    NUMERIC, VARCHAR, NUMERIC, VARCHAR, VARCHAR,
    NUMERIC, TEXT, DECIMAL, BOOLEAN, VECTOR
);

CREATE OR REPLACE FUNCTION fun_registrar_ingreso_manual(
    wid_persona        tab_personas.id_persona%TYPE,
    wid_tipo_docum     tab_personas.id_tipo_docum%TYPE,
    wid_tipo_persona   tab_personas.id_tipo_persona%TYPE,
    wnom_persona       tab_personas.nom_persona%TYPE,
    wape_persona       tab_personas.ape_persona%TYPE,
    wid_entrada_centro tab_log_ingresos.id_entrada_centro%TYPE,
    wval_observaciones tab_log_ingresos.val_observaciones%TYPE,
    wid_metodo_aut     tab_log_ingresos.id_metodo_aut%TYPE DEFAULT 1,
    wcaptura_pdf417    BOOLEAN DEFAULT FALSE,
    wfacial_embedding  tab_log_ingresos.facial_embedding%TYPE DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    wid_ingreso    INTEGER;
    wjson_origen   JSONB;
    worigen_txt    TEXT;
    w_exc_state    TEXT;
    w_exc_msg      TEXT;
    w_exc_detail   TEXT;
    w_exc_hint     TEXT;
BEGIN
    IF wid_metodo_aut IS NULL OR wid_metodo_aut < 1 THEN
        wid_metodo_aut := 1;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_metodos_aut WHERE id_metodo_aut = wid_metodo_aut) THEN
        PERFORM smartcset_raise_validacion(
            'El método de autenticación no es válido.',
            'id_metodo_aut=' || wid_metodo_aut::TEXT
        );
    END IF;

    worigen_txt := CASE
        WHEN wid_metodo_aut = 4 THEN 'biometrico_facial'
        WHEN wid_metodo_aut = 3 THEN 'codigo_barras'
        WHEN wid_metodo_aut = 2 THEN 'codigo_qr'
        ELSE 'registro_manual'
    END;
    IF wid_entrada_centro IS NULL OR wid_entrada_centro < 1 OR wid_entrada_centro > 9 THEN
        PERFORM smartcset_raise_validacion(
            'La puerta de ingreso debe estar entre 1 y 9.',
            'id_entrada_centro=' || COALESCE(wid_entrada_centro::TEXT, 'NULL')
        );
    END IF;

    PERFORM fun_upsert_persona_visitante(
        wid_persona, wid_tipo_docum, wid_tipo_persona, wnom_persona, wape_persona
    );

    wjson_origen := jsonb_build_object(
        'origen', worigen_txt,
        'documento', wid_persona::TEXT,
        'tipo_doc', wid_tipo_docum,
        'tipo_persona', wid_tipo_persona
    );

    IF COALESCE(wcaptura_pdf417, FALSE) THEN
        wjson_origen := wjson_origen || jsonb_build_object('captura_pdf417', TRUE);
    END IF;

    wid_ingreso := fun_insert_log_ingreso(
        wid_persona,
        wid_metodo_aut,
        wid_entrada_centro,
        wjson_origen,
        NULLIF(TRIM(wval_observaciones), ''),
        wfacial_embedding
    );

    PERFORM fun_update_persona_tras_ingreso(wid_persona);

    IF wid_tipo_persona = 2 THEN
        PERFORM fun_verify_retardo_aprendiz(
            wid_persona,
            CURRENT_TIMESTAMP
        );
    END IF;

    RETURN wid_ingreso;
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
