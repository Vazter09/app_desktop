-- Registra un ingreso en tab_log_ingresos. Retorna el id_ingreso generado.
CREATE OR REPLACE FUNCTION fun_insert_log_ingreso(
    wid_visitante       tab_log_ingresos.id_visitante%TYPE,
    wid_metodo_aut      tab_log_ingresos.id_metodo_aut%TYPE,
    wid_entrada_centro  tab_log_ingresos.id_entrada_centro%TYPE,
    wval_datos_origen   tab_log_ingresos.val_datos_origen%TYPE,
    wval_observaciones  tab_log_ingresos.val_observaciones%TYPE,
    wusr                tab_usuarios.id_usuario%TYPE
) RETURNS INTEGER AS $$
DECLARE
    wid_ingreso    INTEGER;
    wts_ingreso    TIMESTAMP WITHOUT TIME ZONE;
    wid_existente  INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_visitante) THEN
        PERFORM smartcset_raise_no_encontrado(
            'El visitante no está registrado.',
            'id_persona=' || wid_visitante::TEXT
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_metodos_aut WHERE id_metodo_aut = wid_metodo_aut) THEN
        PERFORM smartcset_raise_validacion(
            'El método de autenticación no es válido.',
            'id_metodo_aut=' || wid_metodo_aut::TEXT
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La puerta de ingreso no existe en el catálogo.',
            'id_entrada_centro=' || wid_entrada_centro::TEXT
        );
    END IF;

    wid_existente := fun_buscar_ingreso_abierto(wid_visitante);

    IF wid_existente IS NOT NULL THEN
        PERFORM smartcset_raise_negocio(
            format(
                'Esta persona ya tiene un ingreso activo (ingreso #%s). Registre la salida antes de un nuevo ingreso.',
                wid_existente
            ),
            'id_visitante=' || wid_visitante::TEXT,
            'Use el módulo Registro salida.'
        );
    END IF;

    wts_ingreso := CURRENT_TIMESTAMP;
    wid_ingreso := nextval('seq_log_ingresos');

    INSERT INTO tab_log_ingresos (
        id_ingreso, id_visitante, fec_ingreso, fec_salida,
        id_metodo_aut, id_entrada_centro, val_datos_origen, val_observaciones,
        usr_insert, fec_insert
    ) VALUES (
        wid_ingreso, wid_visitante, wts_ingreso, wts_ingreso,
        wid_metodo_aut, wid_entrada_centro, wval_datos_origen, wval_observaciones,
        wusr, wts_ingreso
    );

    RETURN wid_ingreso;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN unique_violation THEN
        PERFORM smartcset_raise_negocio(
            'Esta persona ya tiene un ingreso activo. Registre la salida antes de un nuevo ingreso.',
            NULL,
            'Use el módulo Registro salida.'
        );
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
