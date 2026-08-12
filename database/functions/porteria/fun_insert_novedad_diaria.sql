-- Inserta novedad diaria ligada a un ingreso (motivo del operador).
-- Solo se llama cuando el texto tiene sentido (>= 5 chars, CHECK de tabla).
DROP FUNCTION IF EXISTS fun_insert_novedad_diaria(BIGINT, TEXT);
DROP FUNCTION IF EXISTS fun_insert_novedad_diaria(INTEGER, TEXT);
DROP FUNCTION IF EXISTS fun_insert_novedad_diaria(NUMERIC, TEXT);

CREATE OR REPLACE FUNCTION fun_insert_novedad_diaria(
    wid_ingreso     tab_log_ingresos.id_ingreso%TYPE,
    wmotivo_novedad TEXT
) RETURNS BIGINT AS $$
DECLARE
    wid_novedad  BIGINT;
    wmotivo      TEXT;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    wmotivo := LEFT(TRIM(COALESCE(wmotivo_novedad, '')), 100);

    IF LENGTH(wmotivo) < 5 THEN
        PERFORM smartcset_raise_validacion(
            'La novedad debe tener al menos 5 caracteres.'
        );
    END IF;

    IF wid_ingreso IS NULL OR wid_ingreso < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El ingreso de la novedad no es válido.',
            'id_ingreso=' || COALESCE(wid_ingreso::TEXT, 'NULL')
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_log_ingresos WHERE id_ingreso = wid_ingreso
    ) THEN
        PERFORM smartcset_raise_no_encontrado(
            'No existe el ingreso indicado para la novedad.',
            'id_ingreso=' || wid_ingreso::TEXT
        );
    END IF;

    INSERT INTO tab_novedades_diarias (
        id_ingreso, motivo_novedad, usr_insert, fec_insert
    ) VALUES (
        wid_ingreso,
        wmotivo,
        COALESCE(
            NULLIF(TRIM(current_setting('app.usuario', true)), ''),
            'sistema'
        ),
        smartcset_now_local()
    )
    RETURNING id_novedad_diaria INTO wid_novedad;

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
