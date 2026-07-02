-- Proceso atómico: salida manual portería (actualiza ingreso abierto).
-- La auditoría la gestiona el trigger fun_act_tabla() a través de app.usuario.
CREATE OR REPLACE FUNCTION fun_registrar_salida_manual(
    wid_persona        tab_personas.id_persona%TYPE,
    wid_tipo_docum     tab_personas.id_tipo_docum%TYPE,
    wval_observaciones tab_log_ingresos.val_observaciones%TYPE
) RETURNS INTEGER AS $$
DECLARE
    wid_ingreso  INTEGER;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
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
        NULLIF(TRIM(wval_observaciones), '')
    );

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
