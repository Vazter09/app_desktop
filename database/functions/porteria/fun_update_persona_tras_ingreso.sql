-- Actualiza estadísticas de visita tras registrar un ingreso.
CREATE OR REPLACE FUNCTION fun_update_persona_tras_ingreso(
    wid_persona tab_personas.id_persona%TYPE,
    wusr        tab_usuarios.id_usuario%TYPE
) RETURNS VOID AS $$
BEGIN
    UPDATE tab_personas
    SET fec_ultima_entrada = CURRENT_TIMESTAMP,
        num_visitas        = num_visitas + 1,
        usr_update         = wusr,
        fec_update         = CURRENT_TIMESTAMP
    WHERE id_persona = wid_persona;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'No se encontró el visitante para actualizar el ingreso.',
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
