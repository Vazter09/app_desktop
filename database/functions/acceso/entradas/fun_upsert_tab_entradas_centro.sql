-- Alta o actualización de puerta/entrada del centro (tab_entradas_centro).
-- wid_entrada_centro NULL en alta: asigna el menor código libre entre 1 y 9.
-- Retorna el código asignado o actualizado (TEXT).
-- La auditoría (usr_insert/usr_update) la gestiona el trigger fun_act_tabla().
CREATE OR REPLACE FUNCTION fun_upsert_tab_entradas_centro(
    wid_entrada_centro tab_entradas_centro.id_entrada_centro%TYPE,
    wnom_entrada_centro tab_entradas_centro.nom_entrada_centro%TYPE,
    wid_centro          tab_entradas_centro.id_centro%TYPE,
    wid_sede            tab_entradas_centro.id_sede%TYPE
) RETURNS TEXT AS $$
DECLARE
    v_nom        VARCHAR(50);
    v_len        INTEGER;
    v_id         tab_entradas_centro.id_entrada_centro%TYPE;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    v_nom := UPPER(TRIM(wnom_entrada_centro));
    v_len := LENGTH(v_nom);
    IF v_len < 5 OR v_len > 50 THEN
        PERFORM smartcset_raise_validacion(
            format('El nombre de la entrada debe tener entre 5 y 50 caracteres (actual: %s).', v_len)
        );
    END IF;

    IF wid_centro IS NULL OR wid_sede IS NULL THEN
        PERFORM smartcset_raise_validacion('Seleccione la sede donde queda la entrada.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_sedes
        WHERE id_centro = wid_centro AND id_sede = wid_sede
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La sede seleccionada no existe en el sistema.',
            format('id_centro=%s id_sede=%s', wid_centro, wid_sede)
        );
    END IF;

    IF wid_entrada_centro IS NOT NULL
       AND EXISTS (
           SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro
       )
    THEN
        IF wid_entrada_centro < 1 OR wid_entrada_centro > 9 THEN
            PERFORM smartcset_raise_validacion('El código de entrada no es válido.');
        END IF;

        v_id := wid_entrada_centro;

        UPDATE tab_entradas_centro
        SET nom_entrada_centro = v_nom,
            id_centro          = wid_centro,
            id_sede            = wid_sede
        WHERE id_entrada_centro = v_id;
    ELSE
        IF wid_entrada_centro IS NOT NULL THEN
            IF wid_entrada_centro < 1 OR wid_entrada_centro > 9 THEN
                PERFORM smartcset_raise_validacion('El código de entrada debe ser un número entre 1 y 9.');
            END IF;
            IF EXISTS (
                SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro
            ) THEN
                PERFORM smartcset_raise_negocio(
                    format('El código de entrada %s ya está en uso.', wid_entrada_centro),
                    NULL,
                    'Edite la entrada existente o deje que el sistema asigne el código.'
                );
            END IF;
            v_id := wid_entrada_centro;
        ELSE
            SELECT MIN(s.codigo)::DECIMAL(1, 0)
              INTO v_id
              FROM generate_series(1, 9) AS s(codigo)
             WHERE NOT EXISTS (
                 SELECT 1
                   FROM tab_entradas_centro e
                  WHERE e.id_entrada_centro = s.codigo
             );

            IF v_id IS NULL THEN
                PERFORM smartcset_raise_negocio(
                    'Ya están registradas las 9 entradas permitidas en el sistema.',
                    NULL,
                    'Elimine una entrada existente para poder crear otra.'
                );
            END IF;
        END IF;

        INSERT INTO tab_entradas_centro (
            id_entrada_centro, nom_entrada_centro, id_centro, id_sede
        ) VALUES (
            v_id, v_nom, wid_centro, wid_sede
        );
    END IF;

    RETURN v_id::TEXT;
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
