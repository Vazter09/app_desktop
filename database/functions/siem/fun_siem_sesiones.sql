-- Función: sesiones activas actuales

CREATE OR REPLACE FUNCTION fun_siem_sesiones_activas()
RETURNS TABLE(
    id_sesion    TEXT,
    id_usuario   VARCHAR,
    nom_usuario  VARCHAR,
    ip_cliente   VARCHAR,
    fec_ingreso  TIMESTAMP,
    fec_actividad TIMESTAMP,
    minutos_activo INT
) AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        s.id_sesion::TEXT,
        s.id_usuario,
        u.nom_usuario,
        s.ip_cliente,
        s.fec_inicio      AS fec_ingreso,
        s.ult_actividad   AS fec_actividad,
        EXTRACT(EPOCH FROM (NOW() - s.fec_inicio))::INT / 60 AS minutos_activo
    FROM tab_sesiones s
    JOIN tab_usuarios u ON u.id_usuario = s.id_usuario
    WHERE s.fec_fin IS NULL
    ORDER BY s.fec_inicio DESC;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;


-- Función: forzar cierre de sesión (invalida la sesión en BD)
CREATE OR REPLACE FUNCTION fun_siem_forzar_cierre_sesion(
    wid_sesion   TEXT,
    wid_operador TEXT
) RETURNS TEXT AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_sesion IS NULL OR TRIM(wid_sesion) = '' THEN
        PERFORM smartcset_raise_validacion('El ID de sesión es obligatorio.');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_sesiones WHERE id_sesion = wid_sesion::INTEGER) THEN
        PERFORM smartcset_raise_negocio('La sesión no existe.');
    END IF;

    UPDATE tab_sesiones
    SET fec_fin    = NOW(),
        usr_cierre = wid_operador,
        cod_cierre = 'ADMIN'
    WHERE id_sesion = wid_sesion::INTEGER
      AND fec_fin IS NULL;

    RETURN 'OK';

EXCEPTION
    WHEN SQLSTATE 'P0001' THEN RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;
