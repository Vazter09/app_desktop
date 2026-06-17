-- ===================================================================
-- Función: fun_delete_perfil_usuarios
-- Descripción: Elimina todos los menús asignados a un usuario (borra su perfil)
-- Parámetros:
--   p_id_usuario: ID del usuario (VARCHAR)
-- Retorna: VOID
-- Autor: Sistema SistNomina V.1.3
-- ===================================================================

CREATE OR REPLACE FUNCTION fun_delete_perfil_usuarios(
    p_id_usuario tab_usuarios.id_usuario%TYPE
) RETURNS VOID AS
$$
DECLARE
    v_count INTEGER;
BEGIN
    -- Validar que el usuario existe
    IF NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_id_usuario) THEN
        RAISE EXCEPTION 'El usuario % no existe en tab_usuarios', p_id_usuario;
    END IF;

    -- Eliminar todos los menús del usuario
    DELETE FROM tab_menu_usuarios 
    WHERE id_usuario = p_id_usuario;

    -- Obtener el número de registros eliminados
    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Registrar la acción en auditoría si es necesario
    -- RAISE NOTICE 'Se eliminaron % registros de menú para el usuario %', v_count, p_id_usuario;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar perfil del usuario %: %', p_id_usuario, SQLERRM;
END;
$$ LANGUAGE plpgsql;
