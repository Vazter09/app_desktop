-- Guarda un nuevo enrolamiento facial para una persona ya registrada.
-- No reemplaza enrolamientos previos (se permiten varias tomas activas
-- por persona — REGLAS_APP_ESCRITORIO_SGI.md sección 10.4 — la
-- identificación compara contra todas y toma la de menor distancia).
-- 2026-07-09: Agregado parámetro ruta_foto_enrolamiento para auditoría.
-- Firma vieja de 3 args (sin ruta_foto) eliminada explícitamente: un
-- CREATE OR REPLACE con distinta aridad NO reemplaza, crea una función
-- sobrecargada nueva y dos quedan viviendo a la vez (lección ya
-- documentada en CLAUDE.md — Bug/E3: alineación de firmas PL/pgSQL).
DROP FUNCTION IF EXISTS fun_guardar_enrolamiento_facial(
    tab_enrolamiento_facial.id_persona%TYPE,
    tab_enrolamiento_facial.facial_embedding%TYPE,
    tab_enrolamiento_facial.calidad_facial%TYPE
);

CREATE OR REPLACE FUNCTION fun_guardar_enrolamiento_facial(
    wid_persona            tab_enrolamiento_facial.id_persona%TYPE,
    wfacial_embedding      tab_enrolamiento_facial.facial_embedding%TYPE,
    wcalidad_facial        tab_enrolamiento_facial.calidad_facial%TYPE DEFAULT NULL,
    wruta_foto_enrolamiento VARCHAR(500) DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    wid_enrolamiento  INTEGER;
    w_exc_state       TEXT;
    w_exc_msg         TEXT;
    w_exc_detail      TEXT;
    w_exc_hint        TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        PERFORM smartcset_raise_no_encontrado(
            'La persona no está registrada — no se puede enrolar.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;

    IF wfacial_embedding IS NULL THEN
        PERFORM smartcset_raise_validacion('El vector facial es obligatorio.');
    END IF;

    INSERT INTO tab_enrolamiento_facial (
        id_persona,
        facial_embedding,
        calidad_facial,
        ruta_foto_enrolamiento,
        ind_activo
    ) VALUES (
        wid_persona,
        wfacial_embedding,
        wcalidad_facial,
        wruta_foto_enrolamiento,
        TRUE
    ) RETURNING id_enrolamiento INTO wid_enrolamiento;

    RETURN wid_enrolamiento;
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
