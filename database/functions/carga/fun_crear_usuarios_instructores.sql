CREATE OR REPLACE FUNCTION fun_crear_usuarios_instructores()
RETURNS TABLE (insertados INTEGER, actualizados INTEGER, errores INTEGER) AS
$$
DECLARE
    v_insertados   INTEGER := 0;
    v_actualizados INTEGER := 0;
    v_errores      INTEGER := 0;
BEGIN
    -- 1. Insertar instructores que aún no son usuarios (nunca como administrador)
    WITH nuevos AS (
        INSERT INTO tab_usuarios (id_usuario, nom_usuario, pass_usuario, mail_usuario,
                                  ind_usuario, ind_estado, usr_insert, fec_insert)
        SELECT p.id_persona::VARCHAR,
               SPLIT_PART(TRIM(p.nom_persona), ' ', 1) || ' ' || SPLIT_PART(TRIM(p.ape_persona), ' ', 1),
               crypt(p.id_persona::TEXT, gen_salt('bf')),
               COALESCE(p.mail_persona, 'sin_correo@correo.com'),
               FALSE,
               TRUE,
               'carga_automatica',
               CURRENT_TIMESTAMP
        FROM tab_personas p
        WHERE p.id_tipo_persona = 3
          AND p.nom_persona IS NOT NULL AND TRIM(p.nom_persona) != ''
          AND p.ape_persona IS NOT NULL AND TRIM(p.ape_persona) != ''
        ON CONFLICT (id_usuario) DO NOTHING
        RETURNING id_usuario
    )
    SELECT COUNT(id_usuario) INTO v_insertados FROM nuevos;

    v_actualizados := 0;

    -- 2. Menús Instructor (solo usuarios NO administradores)
    INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
    SELECT u.id_usuario, m.id_menu, 'carga_automatica', CURRENT_TIMESTAMP
    FROM tab_personas p
    JOIN tab_usuarios u ON u.id_usuario = p.id_persona::VARCHAR
    CROSS JOIN (VALUES ('06'), ('0601')) AS m(id_menu)
    WHERE p.id_tipo_persona = 3
      AND p.nom_persona IS NOT NULL AND TRIM(p.nom_persona) != ''
      AND p.ape_persona IS NOT NULL AND TRIM(p.ape_persona) != ''
      AND u.ind_usuario = FALSE
    ON CONFLICT (id_usuario, id_menu) DO NOTHING;

    -- 3. Revocar menús ajenos al rol instructor (nunca tocar administradores)
    DELETE FROM tab_menu_usuarios mu
    USING tab_personas p
    JOIN tab_usuarios u ON u.id_usuario = p.id_persona::VARCHAR
    WHERE mu.id_usuario = p.id_persona::VARCHAR
      AND p.id_tipo_persona = 3
      AND p.nom_persona IS NOT NULL AND TRIM(p.nom_persona) != ''
      AND p.ape_persona IS NOT NULL AND TRIM(p.ape_persona) != ''
      AND u.ind_usuario = FALSE
      AND mu.id_menu NOT IN ('06', '0601');

    -- 4. Contar instructores elegibles que no tienen usuario
    SELECT COUNT(p.id_persona)
    INTO v_errores
    FROM tab_personas p
    LEFT JOIN tab_usuarios u ON u.id_usuario = p.id_persona::VARCHAR
    WHERE p.id_tipo_persona = 3
      AND p.nom_persona IS NOT NULL AND TRIM(p.nom_persona) != ''
      AND p.ape_persona IS NOT NULL AND TRIM(p.ape_persona) != ''
      AND u.id_usuario IS NULL;

    RETURN QUERY SELECT v_insertados, v_actualizados, v_errores;
END;
$$ LANGUAGE plpgsql;
