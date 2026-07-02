-- Borrado de puerta/entrada del centro.
CREATE OR REPLACE FUNCTION fun_delete_tab_entradas_centro(
    wid_entrada_centro tab_entradas_centro.id_entrada_centro%TYPE
) RETURNS TEXT AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_entrada_centro IS NULL OR wid_entrada_centro < 1 OR wid_entrada_centro > 9 THEN
        PERFORM smartcset_raise_validacion(
            'El código de entrada no es válido.',
            'id_entrada_centro=' || COALESCE(wid_entrada_centro::TEXT, 'NULL')
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro
    ) THEN
        PERFORM smartcset_raise_no_encontrado(
            'La entrada no existe.',
            'id_entrada_centro=' || wid_entrada_centro::TEXT
        );
    END IF;

    DELETE FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro;

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN foreign_key_violation THEN
        PERFORM smartcset_raise_negocio(
            'No se puede eliminar: la entrada está en uso en registros de ingreso.',
            NULL,
            'Cierre o reasigne los ingresos asociados antes de eliminar la puerta.'
        );
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;
