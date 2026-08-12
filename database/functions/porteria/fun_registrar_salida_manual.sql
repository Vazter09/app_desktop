-- Proceso atomico: salida porteria (actualiza ingreso abierto).
-- Persiste id_metodo_salida / id_entrada_salida sin alterar columnas de ingreso.
-- wmotivo_novedad opcional -> tab_novedades_diarias solo si LENGTH(TRIM) >= 5.
DROP FUNCTION IF EXISTS fun_registrar_salida_manual(
    tab_personas.id_persona%TYPE,
    tab_personas.id_tipo_docum%TYPE,
    TEXT
);
DROP FUNCTION IF EXISTS fun_registrar_salida_manual(NUMERIC, VARCHAR, TEXT);
DROP FUNCTION IF EXISTS fun_registrar_salida_manual(NUMERIC, VARCHAR);
DROP FUNCTION IF EXISTS fun_registrar_salida_manual(
    NUMERIC, VARCHAR, TEXT, NUMERIC, NUMERIC
);
DROP FUNCTION IF EXISTS fun_registrar_salida_manual(
    tab_personas.id_persona%TYPE,
    tab_personas.id_tipo_docum%TYPE,
    TEXT,
    tab_log_ingresos.id_metodo_salida%TYPE,
    tab_log_ingresos.id_entrada_salida%TYPE
);

CREATE OR REPLACE FUNCTION fun_registrar_salida_manual(
    wid_persona         tab_personas.id_persona%TYPE,
    wid_tipo_docum      tab_personas.id_tipo_docum%TYPE,
    wmotivo_novedad     TEXT DEFAULT NULL,
    wid_metodo_salida   tab_log_ingresos.id_metodo_salida%TYPE DEFAULT 1,
    wid_entrada_salida  tab_log_ingresos.id_entrada_salida%TYPE DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
    wid_ingreso  BIGINT;
    wmotivo      TEXT;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_persona IS NULL OR wid_persona < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El numero de documento no es valido.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wid_tipo_docum IS NULL OR TRIM(wid_tipo_docum) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de documento.');
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM tab_personas
         WHERE id_persona = wid_persona
    ) THEN
        PERFORM smartcset_raise_no_encontrado(
            'No hay visitante registrado con ese documento.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;

    wid_ingreso := fun_buscar_ingreso_abierto(wid_persona);

    IF wid_ingreso IS NULL THEN
        PERFORM smartcset_raise_negocio(
            'No tiene un ingreso activo para registrar salida.',
            'id_persona=' || wid_persona::TEXT,
            'Registre primero el ingreso o verifique documento y tipo.'
        );
    END IF;

    wid_ingreso := fun_update_log_salida(
        wid_ingreso,
        wid_metodo_salida,
        wid_entrada_salida
    );

    wmotivo := LEFT(TRIM(COALESCE(wmotivo_novedad, '')), 100);
    IF LENGTH(wmotivo) >= 5 THEN
        PERFORM fun_insert_novedad_diaria(wid_ingreso, wmotivo);
    END IF;

    PERFORM fun_update_persona_tras_salida(wid_persona);

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
