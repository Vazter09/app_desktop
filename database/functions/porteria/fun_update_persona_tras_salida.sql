-- Actualiza estadísticas de visita tras registrar una salida.
CREATE OR REPLACE FUNCTION fun_update_persona_tras_salida(
    wid_persona tab_personas.id_persona%TYPE,
    wusr        tab_usuarios.id_usuario%TYPE
) RETURNS VOID AS $$
BEGIN
    UPDATE tab_personas
    SET fec_ultima_salida = CURRENT_TIMESTAMP,
        usr_update        = wusr,
        fec_update        = CURRENT_TIMESTAMP
    WHERE id_persona = wid_persona;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'No se encontró el visitante para actualizar la salida.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
