CREATE OR REPLACE FUNCTION fun_insert_tab_usuarios(
    wid_usuario   tab_usuarios.id_usuario%TYPE,
    wnom_usuario  tab_usuarios.nom_usuario%TYPE,
    wpass_usuario tab_usuarios.pass_usuario%TYPE,
    wmail_usuario tab_usuarios.mail_usuario%TYPE,
    wind_usuario  tab_usuarios.ind_usuario%TYPE,
    wind_estado   tab_usuarios.ind_estado%TYPE
) RETURNS TEXT AS $$
BEGIN
    IF wid_usuario IS NULL OR LENGTH(TRIM(wid_usuario)) < 5 THEN
        PERFORM smartcset_raise_validacion(
            'El ID de usuario debe tener al menos 5 caracteres.',
            'id_usuario=' || COALESCE(wid_usuario, 'NULL')
        );
    END IF;

    IF EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = wid_usuario) THEN
        PERFORM smartcset_raise_negocio(
            'Ya existe un usuario con ese identificador.',
            'id_usuario=' || wid_usuario
        );
    END IF;

    INSERT INTO tab_usuarios (
        id_usuario, nom_usuario, pass_usuario, mail_usuario, ind_usuario, ind_estado
    ) VALUES (
        wid_usuario, wnom_usuario, wpass_usuario, wmail_usuario, wind_usuario, wind_estado
    );

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN unique_violation THEN
        PERFORM smartcset_raise_negocio('El usuario ya está registrado.');
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
