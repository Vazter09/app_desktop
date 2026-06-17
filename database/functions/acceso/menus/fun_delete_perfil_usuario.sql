CREATE OR REPLACE FUNCTION fun_delete_perfil_usuario(wid_usuario tab_usuarios.id_usuario%TYPE) RETURNS VOID AS
$$
BEGIN
    DELETE FROM tab_menu_usuarios WHERE id_usuario = wid_usuario;
END;
$$ LANGUAGE plpgsql;