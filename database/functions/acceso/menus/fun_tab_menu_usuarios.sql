-- Función de Inserción Atómica (V.1.3: Sin nom_programa, se obtiene de tab_menus)
CREATE OR REPLACE FUNCTION fun_insert_menu_usuarios(wid_usuario tab_usuarios.id_usuario%TYPE,
                                                    wid_menu tab_menus.id_menu%TYPE) RETURNS VOID AS
$$
BEGIN
    INSERT INTO tab_menu_usuarios (id_usuario, id_menu)
    VALUES (wid_usuario, wid_menu);
    EXCEPTION
        WHEN unique_violation THEN
            RAISE EXCEPTION 'El menú % ya está asignado al usuario %', wid_menu, wid_usuario;
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Error en fun_insert_menu_usuarios: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función de Borrado Masivo (para sincronización)
CREATE OR REPLACE FUNCTION fun_delete_perfil_usuario(wid_usuario tab_usuarios.id_usuario%TYPE) RETURNS VOID AS
$$
BEGIN
    DELETE FROM tab_menu_usuarios WHERE id_usuario = wid_usuario;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Error al limpiar perfil: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;