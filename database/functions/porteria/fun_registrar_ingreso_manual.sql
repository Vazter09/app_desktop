-- Proceso atomico: visitante + ingreso. Opcional: facial y/o huella del evento.
-- wmotivo_novedad: texto del formulario Observacion/Novedad -> tab_novedades_diarias
-- (solo si LENGTH(TRIM(...)) >= 5).
DROP FUNCTION IF EXISTS fun_registrar_ingreso_manual(
    NUMERIC, VARCHAR, NUMERIC, VARCHAR, VARCHAR,
    NUMERIC, TEXT, DECIMAL, BOOLEAN
);
DROP FUNCTION IF EXISTS fun_registrar_ingreso_manual(
    NUMERIC, VARCHAR, NUMERIC, VARCHAR, VARCHAR,
    NUMERIC, TEXT, DECIMAL, BOOLEAN, VECTOR
);
DROP FUNCTION IF EXISTS fun_registrar_ingreso_manual(
    NUMERIC, VARCHAR, NUMERIC, VARCHAR, VARCHAR,
    NUMERIC, TEXT, DECIMAL, BOOLEAN, VECTOR, BYTEA
);
DROP FUNCTION IF EXISTS fun_registrar_ingreso_manual(
    NUMERIC, VARCHAR, NUMERIC, VARCHAR, VARCHAR,
    NUMERIC, TEXT, DECIMAL, BOOLEAN, VECTOR, BYTEA, VARCHAR
);
DROP FUNCTION IF EXISTS fun_registrar_ingreso_manual(
    NUMERIC, VARCHAR, NUMERIC, VARCHAR, VARCHAR,
    NUMERIC, TEXT, DECIMAL, BOOLEAN, VECTOR, BYTEA, BOOLEAN, VARCHAR
);

CREATE OR REPLACE FUNCTION fun_registrar_ingreso_manual(
    wid_persona         tab_personas.id_persona%TYPE,
    wid_tipo_docum      tab_personas.id_tipo_docum%TYPE,
    wid_tipo_persona    tab_personas.id_tipo_persona%TYPE,
    wnom_persona        tab_personas.nom_persona%TYPE,
    wape_persona        tab_personas.ape_persona%TYPE,
    wid_entrada_ingreso tab_log_ingresos.id_entrada_ingreso%TYPE,
    wmotivo_novedad     TEXT DEFAULT NULL,
    wid_metodo_ingreso  tab_log_ingresos.id_metodo_ingreso%TYPE DEFAULT 1,
    wcaptura_pdf417     BOOLEAN DEFAULT FALSE,
    wfacial_embedding   tab_log_ingresos.facial_embedding%TYPE DEFAULT NULL,
    whuella_template    tab_log_ingresos.huella_template%TYPE DEFAULT NULL,
    wid_equipo          tab_log_ingresos.id_equipo%TYPE DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
    wid_ingreso    BIGINT;
    wjson_origen   JSONB;
    worigen_txt    TEXT;
    wmotivo        TEXT;
    wserial        TEXT;
    w_exc_state    TEXT;
    w_exc_msg      TEXT;
    w_exc_detail   TEXT;
    w_exc_hint     TEXT;
BEGIN
    IF wid_metodo_ingreso IS NULL OR wid_metodo_ingreso < 1 THEN
        wid_metodo_ingreso := 1;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_metodos_aut WHERE id_metodo_aut = wid_metodo_ingreso
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El metodo de autenticacion no es valido.',
            'id_metodo_ingreso=' || wid_metodo_ingreso::TEXT
        );
    END IF;

    worigen_txt := CASE
        WHEN wid_metodo_ingreso = 5 THEN 'biometrico_huella'
        WHEN wid_metodo_ingreso = 4 THEN 'biometrico_facial'
        WHEN wid_metodo_ingreso = 3 THEN 'codigo_barras'
        WHEN wid_metodo_ingreso = 2 THEN 'codigo_qr'
        ELSE 'registro_manual'
    END;

    IF wid_entrada_ingreso IS NULL
       OR wid_entrada_ingreso < 1
       OR wid_entrada_ingreso > 9 THEN
        PERFORM smartcset_raise_validacion(
            'La puerta de ingreso debe estar entre 1 y 9.',
            'id_entrada_ingreso=' || COALESCE(wid_entrada_ingreso::TEXT, 'NULL')
        );
    END IF;

    PERFORM fun_upsert_persona_visitante(
        wid_persona, wid_tipo_docum, wid_tipo_persona, wnom_persona, wape_persona
    );

    wserial := LEFT(TRIM(COALESCE(wid_equipo, '')), 50);
    IF wserial <> '' AND wserial <> '111111' THEN
        -- descripcion 'Pendiente' hasta cablear detalle/tipo.
        PERFORM fun_upsert_equipo_persona(wserial, wid_persona, 'Pendiente');
    ELSE
        wserial := NULL;
    END IF;

    wjson_origen := jsonb_build_object(
        'origen', worigen_txt,
        'documento', wid_persona::TEXT,
        'tipo_doc', wid_tipo_docum,
        'tipo_persona', wid_tipo_persona
    );

    IF COALESCE(wcaptura_pdf417, FALSE) THEN
        wjson_origen := wjson_origen || jsonb_build_object('captura_pdf417', TRUE);
    END IF;

    IF wserial IS NOT NULL THEN
        wjson_origen := wjson_origen || jsonb_build_object('id_equipo', wserial);
    END IF;

    wid_ingreso := fun_insert_log_ingreso(
        wid_persona,
        wid_metodo_ingreso,
        wid_entrada_ingreso,
        wjson_origen,
        wfacial_embedding,
        whuella_template,
        wserial
    );

    wmotivo := LEFT(TRIM(COALESCE(wmotivo_novedad, '')), 100);
    IF LENGTH(wmotivo) >= 5 THEN
        PERFORM fun_insert_novedad_diaria(wid_ingreso, wmotivo);
    END IF;

    PERFORM fun_update_persona_tras_ingreso(wid_persona);

    IF wid_tipo_persona = 2 THEN
        BEGIN
            PERFORM fun_verify_retardo_aprendiz(
                wid_persona,
                CURRENT_TIMESTAMP
            );
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
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
