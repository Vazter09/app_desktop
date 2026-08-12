-- Ingreso de persona NO registrada → tab_novedades_ingreso.
-- Acepta vector facial y/o plantilla de huella de la captura.
DROP FUNCTION IF EXISTS fun_insert_novedad_ingreso(
    VARCHAR, VARCHAR, NUMERIC, VECTOR, VARCHAR
);
DROP FUNCTION IF EXISTS fun_insert_novedad_ingreso(
    VARCHAR, VARCHAR, NUMERIC, VECTOR, VARCHAR, BYTEA, VARCHAR
);

CREATE OR REPLACE FUNCTION fun_insert_novedad_ingreso(
    wnom_tercero         tab_novedades_ingreso.nom_tercero%TYPE,
    wape_tercero         tab_novedades_ingreso.ape_tercero%TYPE,
    wid_entrada_centro   tab_novedades_ingreso.id_entrada_centro%TYPE,
    wfacial_embedding    tab_novedades_ingreso.val_patron_facial%TYPE DEFAULT NULL,
    wurl_foto_facial     tab_novedades_ingreso.url_foto_facial%TYPE DEFAULT NULL,
    wval_huella_digital  tab_novedades_ingreso.val_huella_digital%TYPE DEFAULT NULL,
    wurl_imagen_huella   tab_novedades_ingreso.url_imagen_huella%TYPE DEFAULT NULL
) RETURNS NUMERIC AS $$
DECLARE
    wid_novedad    NUMERIC;
    wts            TIMESTAMP WITHOUT TIME ZONE;
    wusr           TEXT;
    w_exc_state    TEXT;
    w_exc_msg      TEXT;
    w_exc_detail   TEXT;
    w_exc_hint     TEXT;
BEGIN
    IF LENGTH(TRIM(wnom_tercero)) < 3 THEN
        PERFORM smartcset_raise_validacion('Indique el nombre del tercero (mín. 3 caracteres).');
    END IF;
    IF LENGTH(TRIM(wape_tercero)) < 2 THEN
        PERFORM smartcset_raise_validacion('Indique el apellido del tercero (mín. 2 caracteres).');
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La puerta de ingreso no existe en el catálogo.',
            'id_entrada_centro=' || wid_entrada_centro::TEXT
        );
    END IF;

    IF wfacial_embedding IS NULL
       AND (wval_huella_digital IS NULL OR octet_length(wval_huella_digital) < 16) THEN
        PERFORM smartcset_raise_validacion(
            'Indique al menos un biométrico (facial o huella) para la novedad.'
        );
    END IF;

    wusr := NULLIF(TRIM(current_setting('app.usuario', true)), '');
    IF wusr IS NULL OR LENGTH(wusr) < 3 THEN
        wusr := 'sistema';
    END IF;

    wts := smartcset_now_local();
    wid_novedad := nextval('seq_novedades_ingreso');

    INSERT INTO tab_novedades_ingreso (
        id_novedad, nom_tercero, ape_tercero, id_entrada_centro,
        val_patron_facial, url_foto_facial,
        val_huella_digital, url_imagen_huella,
        fec_ingreso, fec_salida, usr_insert, fec_insert
    ) VALUES (
        wid_novedad, TRIM(wnom_tercero), TRIM(wape_tercero), wid_entrada_centro,
        wfacial_embedding, NULLIF(TRIM(wurl_foto_facial), ''),
        wval_huella_digital, NULLIF(TRIM(wurl_imagen_huella), ''),
        wts, wts, wusr, wts
    );

    RETURN wid_novedad;
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
