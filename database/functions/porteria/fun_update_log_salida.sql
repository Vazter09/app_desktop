-- Registra la salida en un ingreso abierto (fec_salida = fec_ingreso).
-- Escribe id_metodo_salida / id_entrada_salida sin tocar las columnas de ingreso.
-- Las novedades del operador van a tab_novedades_diarias (no aqui).
DROP FUNCTION IF EXISTS fun_update_log_salida(
    tab_log_ingresos.id_ingreso%TYPE,
    TEXT
);
DROP FUNCTION IF EXISTS fun_update_log_salida(INTEGER, TEXT);
DROP FUNCTION IF EXISTS fun_update_log_salida(BIGINT, TEXT);
DROP FUNCTION IF EXISTS fun_update_log_salida(BIGINT, VARCHAR);
DROP FUNCTION IF EXISTS fun_update_log_salida(BIGINT, CHARACTER VARYING);
DROP FUNCTION IF EXISTS fun_update_log_salida(BIGINT);
DROP FUNCTION IF EXISTS fun_update_log_salida(INTEGER);
DROP FUNCTION IF EXISTS fun_update_log_salida(BIGINT, NUMERIC, NUMERIC);
DROP FUNCTION IF EXISTS fun_update_log_salida(
    tab_log_ingresos.id_ingreso%TYPE,
    tab_log_ingresos.id_metodo_salida%TYPE,
    tab_log_ingresos.id_entrada_salida%TYPE
);

CREATE OR REPLACE FUNCTION fun_update_log_salida(
    wid_ingreso         tab_log_ingresos.id_ingreso%TYPE,
    wid_metodo_salida   tab_log_ingresos.id_metodo_salida%TYPE DEFAULT 1,
    wid_entrada_salida  tab_log_ingresos.id_entrada_salida%TYPE DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
    wts_salida          TIMESTAMP WITHOUT TIME ZONE;
    wts_ingreso         TIMESTAMP WITHOUT TIME ZONE;
    wid_entrada_eff     tab_log_ingresos.id_entrada_salida%TYPE;
    wid_metodo_eff      tab_log_ingresos.id_metodo_salida%TYPE;
    wrows               INTEGER;
    w_exc_state         TEXT;
    w_exc_msg           TEXT;
    w_exc_detail        TEXT;
    w_exc_hint          TEXT;
BEGIN
    SELECT fec_ingreso, id_entrada_ingreso
      INTO wts_ingreso, wid_entrada_eff
      FROM tab_log_ingresos
     WHERE id_ingreso = wid_ingreso;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'No existe el registro de ingreso indicado.',
            'id_ingreso=' || wid_ingreso::TEXT
        );
    END IF;

    wid_metodo_eff := COALESCE(wid_metodo_salida, 1);
    IF wid_metodo_eff < 1 THEN
        wid_metodo_eff := 1;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_metodos_aut WHERE id_metodo_aut = wid_metodo_eff
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El metodo de autenticacion de salida no es valido.',
            'id_metodo_salida=' || wid_metodo_eff::TEXT
        );
    END IF;

    -- Si no envian puerta de salida, reutilizar la del ingreso.
    IF wid_entrada_salida IS NOT NULL AND wid_entrada_salida >= 1 THEN
        wid_entrada_eff := wid_entrada_salida;
    END IF;

    IF wid_entrada_eff IS NULL
       OR wid_entrada_eff < 1
       OR wid_entrada_eff > 9 THEN
        PERFORM smartcset_raise_validacion(
            'La puerta de salida no es valida.',
            'id_entrada_salida=' || COALESCE(wid_entrada_eff::TEXT, 'NULL')
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM tab_entradas_centro
         WHERE id_entrada_centro = wid_entrada_eff
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La puerta de salida no existe en el catalogo.',
            'id_entrada_salida=' || wid_entrada_eff::TEXT
        );
    END IF;

    -- Hora civil Bogotá (no UTC de sesión del servidor).
    wts_salida := smartcset_now_local();

    -- Filas antiguas con reloj UTC naive: fec_ingreso queda "en el futuro"
    -- respecto a Bogotá. Normalizar solo para la regla de 5 min (no reescribe
    -- fec_ingreso aquí; la migración convert_log_ingresos_utc_to_bogota lo hace).
    IF wts_ingreso > wts_salida + interval '2 minutes' THEN
        wts_ingreso := (wts_ingreso AT TIME ZONE 'UTC')
                       AT TIME ZONE 'America/Bogota';
    END IF;

    IF wts_salida <= wts_ingreso THEN
        wts_salida := wts_ingreso + interval '1 second';
    END IF;

    IF EXTRACT(EPOCH FROM (wts_salida - wts_ingreso)) < 300 THEN
        PERFORM smartcset_raise_negocio(
            format(
                'Debe esperar al menos 5 minutos desde el ingreso (%s) para registrar la salida. Tiempo transcurrido: %s min.',
                to_char(wts_ingreso, 'HH24:MI:SS'),
                ROUND(EXTRACT(EPOCH FROM (wts_salida - wts_ingreso)) / 60.0, 1)::TEXT
            ),
            'id_ingreso=' || wid_ingreso::TEXT,
            'Espere a completar el tiempo minimo e intente de nuevo.'
        );
    END IF;

    -- Solo fec_salida (+ método/puerta de salida). Nunca toca fec_ingreso.
    UPDATE tab_log_ingresos
       SET fec_salida = wts_salida,
           id_metodo_salida = wid_metodo_eff,
           id_entrada_salida = wid_entrada_eff
     WHERE id_ingreso = wid_ingreso
       AND fec_salida = fec_ingreso;

    GET DIAGNOSTICS wrows = ROW_COUNT;

    IF wrows = 0 THEN
        IF EXISTS (SELECT 1 FROM tab_log_ingresos WHERE id_ingreso = wid_ingreso) THEN
            PERFORM smartcset_raise_negocio(
                format('La salida del ingreso #%s ya fue registrada.', wid_ingreso),
                NULL,
                'Verifique el listado de salidas del dia.'
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
