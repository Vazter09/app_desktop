-- Cataloga o anexa un equipo (serial) al propietario del ingreso.
-- Estructura real en prod/lab: id_equipo, descripcion, id_propietario (+ auditoría).
-- descripcion queda 'Pendiente' hasta cablear tipo/detalle.
-- Auditoría via trigger fun_act_tabla() / app.usuario.
DROP FUNCTION IF EXISTS fun_upsert_equipo_persona(VARCHAR, NUMERIC, NUMERIC);
DROP FUNCTION IF EXISTS fun_upsert_equipo_persona(VARCHAR, NUMERIC);
DROP FUNCTION IF EXISTS fun_upsert_equipo_persona(VARCHAR, NUMERIC, VARCHAR);

CREATE OR REPLACE FUNCTION fun_upsert_equipo_persona(
    wid_equipo       tab_equipos.id_equipo%TYPE,
    wid_propietario  tab_equipos.id_propietario%TYPE,
    wdescripcion     tab_equipos.descripcion%TYPE DEFAULT 'Pendiente'
) RETURNS VOID AS $$
DECLARE
    wserial        TEXT;
    wdesc          TEXT;
    w_exc_state    TEXT;
    w_exc_msg      TEXT;
    w_exc_detail   TEXT;
    w_exc_hint     TEXT;
BEGIN
    wserial := LEFT(TRIM(COALESCE(wid_equipo, '')), 50);
    IF wserial = '' OR wserial = '111111' THEN
        PERFORM smartcset_raise_validacion(
            'Indique el número de serie del equipo.',
            'id_equipo=' || COALESCE(wid_equipo, 'NULL')
        );
    END IF;

    IF wid_propietario IS NULL OR wid_propietario < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El propietario del equipo no es válido.',
            'id_propietario=' || COALESCE(wid_propietario::TEXT, 'NULL')
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_personas WHERE id_persona = wid_propietario
    ) THEN
        PERFORM smartcset_raise_no_encontrado(
            'El propietario del equipo no está registrado.',
            'id_persona=' || wid_propietario::TEXT
        );
    END IF;

    wdesc := LEFT(TRIM(COALESCE(wdescripcion, '')), 50);
    IF wdesc = '' THEN
        wdesc := 'Pendiente';
    END IF;

    INSERT INTO tab_equipos (
        id_equipo, descripcion, id_propietario
    ) VALUES (
        wserial, wdesc, wid_propietario
    )
    ON CONFLICT (id_equipo) DO UPDATE
    SET id_propietario = EXCLUDED.id_propietario,
        descripcion = CASE
            WHEN tab_equipos.descripcion IS DISTINCT FROM 'Pendiente'
             AND EXCLUDED.descripcion = 'Pendiente'
            THEN tab_equipos.descripcion
            ELSE EXCLUDED.descripcion
        END;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(
            w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint
        );
END;
$$ LANGUAGE plpgsql;
