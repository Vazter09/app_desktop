-- Actualiza la ultima captura biometrica del ingreso abierto (sin cerrar).
DROP FUNCTION IF EXISTS fun_actualizar_captura_ingreso_abierto(
    NUMERIC, VECTOR, BYTEA, NUMERIC, TEXT
);
DROP FUNCTION IF EXISTS fun_actualizar_captura_ingreso_abierto(
    NUMERIC, VECTOR, BYTEA, NUMERIC
);

CREATE OR REPLACE FUNCTION fun_actualizar_captura_ingreso_abierto(
    wid_persona         tab_personas.id_persona%TYPE,
    wfacial_embedding   tab_log_ingresos.facial_embedding%TYPE DEFAULT NULL,
    whuella_template    tab_log_ingresos.huella_template%TYPE DEFAULT NULL,
    wid_metodo_ingreso  tab_log_ingresos.id_metodo_ingreso%TYPE DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
    wid_ingreso    BIGINT;
    w_exc_state    TEXT;
    w_exc_msg      TEXT;
    w_exc_detail   TEXT;
    w_exc_hint     TEXT;
BEGIN
    IF wid_persona IS NULL OR wid_persona < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El numero de documento no es valido.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wfacial_embedding IS NULL AND whuella_template IS NULL THEN
        PERFORM smartcset_raise_validacion(
            'Debe enviar una captura facial o de huella para actualizar el ingreso.'
        );
    END IF;

    wid_ingreso := fun_buscar_ingreso_abierto(wid_persona);

    IF wid_ingreso IS NULL THEN
        PERFORM smartcset_raise_negocio(
            'No tiene un ingreso activo para actualizar la captura.',
            'id_persona=' || wid_persona::TEXT,
            'Registre primero el ingreso.'
        );
    END IF;

    UPDATE tab_log_ingresos
       SET facial_embedding = COALESCE(wfacial_embedding, facial_embedding),
           huella_template  = COALESCE(whuella_template, huella_template),
           id_metodo_ingreso = COALESCE(wid_metodo_ingreso, id_metodo_ingreso)
     WHERE id_ingreso = wid_ingreso
       AND fec_salida = fec_ingreso;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_negocio(
            'El ingreso abierto ya no esta disponible.',
            'id_ingreso=' || wid_ingreso::TEXT
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
