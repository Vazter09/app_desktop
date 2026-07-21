-- Registra la salida en un ingreso abierto (fec_salida = fec_ingreso).
-- Cierra con fec_salida estrictamente posterior a fec_ingreso para no dejar visitas fantasma.
-- La auditoría (usr_update) la gestiona el trigger fun_act_tabla().
CREATE OR REPLACE FUNCTION fun_update_log_salida(
    wid_ingreso         tab_log_ingresos.id_ingreso%TYPE,
    wval_observaciones  tab_log_ingresos.val_observaciones%TYPE
) RETURNS INTEGER AS $$
DECLARE
    wts_salida   TIMESTAMP WITHOUT TIME ZONE;
    wts_ingreso  TIMESTAMP WITHOUT TIME ZONE;
    wrows        INTEGER;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    SELECT fec_ingreso
      INTO wts_ingreso
      FROM tab_log_ingresos
     WHERE id_ingreso = wid_ingreso;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'No existe el registro de ingreso indicado.',
            'id_ingreso=' || wid_ingreso::TEXT
        );
    END IF;

    wts_salida := CURRENT_TIMESTAMP;
    IF wts_salida <= wts_ingreso THEN
        wts_salida := wts_ingreso + interval '1 microsecond';
    END IF;

    -- Mínimo 5 minutos entre ingreso y salida.
    -- Re-capturas (< 5 min) actualizan el ingreso abierto; no crean otro ni cierran.
    IF EXTRACT(EPOCH FROM (wts_salida - wts_ingreso)) < 300 THEN
        PERFORM smartcset_raise_negocio(
            format(
                'Debe esperar al menos 5 minutos desde el ingreso (%s) para registrar la salida. Tiempo transcurrido: %s min.',
                to_char(wts_ingreso, 'HH24:MI:SS'),
                ROUND(EXTRACT(EPOCH FROM (wts_salida - wts_ingreso)) / 60.0, 1)::TEXT
            ),
            'id_ingreso=' || wid_ingreso::TEXT,
            'Espere a completar el tiempo mínimo e intente de nuevo.'
        );
    END IF;

    UPDATE tab_log_ingresos
    SET fec_salida = wts_salida,
        val_observaciones = CASE
            WHEN wval_observaciones IS NOT NULL AND TRIM(wval_observaciones) <> '' THEN
                CASE
                    WHEN val_observaciones IS NULL OR TRIM(val_observaciones) = '' THEN TRIM(wval_observaciones)
                    ELSE TRIM(val_observaciones) || ' | Salida: ' || TRIM(wval_observaciones)
                END
            ELSE val_observaciones
        END
    WHERE id_ingreso = wid_ingreso
      AND fec_salida = fec_ingreso;

    GET DIAGNOSTICS wrows = ROW_COUNT;

    IF wrows = 0 THEN
        IF EXISTS (SELECT 1 FROM tab_log_ingresos WHERE id_ingreso = wid_ingreso) THEN
            PERFORM smartcset_raise_negocio(
                format('La salida del ingreso #%s ya fue registrada.', wid_ingreso),
                NULL,
                'Verifique el listado de salidas del día.'
            );
        ELSE
            PERFORM smartcset_raise_no_encontrado(
                'No existe el registro de ingreso indicado.',
                'id_ingreso=' || wid_ingreso::TEXT
            );
        END IF;
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
