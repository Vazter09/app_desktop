-- Proceso atómico: salida manual portería (actualiza ingreso abierto).
CREATE OR REPLACE FUNCTION fun_registrar_salida_manual(
    wid_persona        tab_personas.id_persona%TYPE,
    wid_tipo_docum     tab_personas.id_tipo_docum%TYPE,
    wval_observaciones tab_log_ingresos.val_observaciones%TYPE,
    wusr               tab_usuarios.id_usuario%TYPE
) RETURNS INTEGER AS $$
DECLARE
    wid_ingreso INTEGER;
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
        NULLIF(TRIM(wval_observaciones), ''),
        wusr
    );

    PERFORM fun_update_persona_tras_salida(wid_persona, wusr);

    RETURN wid_ingreso;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
