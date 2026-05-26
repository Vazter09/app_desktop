CREATE OR REPLACE FUNCTION fun_validar_correo(
    wuser  tab_usuarios.id_usuario%TYPE,
    wmail  tab_usuarios.mail_usuario%TYPE
) RETURNS TEXT AS $$
DECLARE
    v_existe INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_existe 
    FROM tab_usuarios 
    WHERE id_usuario = wuser AND mail_usuario = wmail;

    IF v_existe > 0 THEN
        RETURN 'OK';
    ELSE
        RETURN 'ERROR: Los datos no coinciden con nuestros registros.';
    END IF;
END;
$$ LANGUAGE plpgsql;