CREATE OR REPLACE FUNCTION fun_crear_usuarios_instructores()
RETURNS TABLE (insertados INTEGER, actualizados INTEGER, errores INTEGER) AS
$$
DECLARE
    v_total       INTEGER;
    v_insertados  INTEGER := 0;
    v_actualizados INTEGER := 0;
    v_errores     INTEGER := 0;
BEGIN
    -- Contar instructores válidos (id_tipo_persona = 3 con nombre y apellido no vacíos)
    SELECT COUNT(p.id_persona)
    INTO v_total
    FROM tab_personas p
    WHERE p.id_tipo_persona = 3
      AND p.nom_persona IS NOT NULL
      AND TRIM(p.nom_persona) != ''
      AND p.ape_persona IS NOT NULL
      AND TRIM(p.ape_persona) != '';

    -- Insertar en bloque solo los que no existan (los duplicados se ignoran)
    INSERT INTO tab_usuarios (
        id_usuario,
        nom_usuario,
        pass_usuario,
        mail_usuario,
        ind_usuario,
        ind_estado,
        usr_insert,
        fec_insert
    )
    SELECT
        p.id_persona::VARCHAR,
        SPLIT_PART(TRIM(p.nom_persona), ' ', 1) || ' ' || SPLIT_PART(TRIM(p.ape_persona), ' ', 1),
        crypt(p.id_persona::TEXT, gen_salt('bf')),
        COALESCE(p.mail_persona, 'sin_correo@correo.com'),
        TRUE,
        TRUE,
        'carga_automatica',
        CURRENT_TIMESTAMP
    FROM tab_personas p
    WHERE p.id_tipo_persona = 3
      AND p.nom_persona IS NOT NULL
      AND TRIM(p.nom_persona) != ''
      AND p.ape_persona IS NOT NULL
      AND TRIM(p.ape_persona) != ''
    ON CONFLICT (id_usuario) DO NOTHING;

    -- Obtener cuántos se insertaron realmente
    GET DIAGNOSTICS v_insertados = ROW_COUNT;

    -- No hay actualizaciones (solo insert u omisión)
    v_actualizados := 0;
    v_errores := v_total - v_insertados;  -- Duplicados o errores

    RETURN QUERY SELECT v_insertados, v_actualizados, v_errores;
END;
$$
LANGUAGE plpgsql;

SELECT fun_crear_usuarios_instructores();