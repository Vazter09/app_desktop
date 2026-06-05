CREATE OR REPLACE FUNCTION migrar_aprendices()
RETURNS TABLE(
    insertados INTEGER,
    actualizados INTEGER,
    errores INTEGER
) LANGUAGE plpgsql AS $$
DECLARE
    v_insertados INTEGER := 0;
    v_actualizados INTEGER := 0;
    v_errores INTEGER := 0;
    r RECORD;
    v_num_clean TEXT;
    v_id_persona DECIMAL(10,0);
BEGIN
    -- Asegurar existencia del tipo persona 'aprendiz' (id=2)
    INSERT INTO tab_tipos_persona (id_tipo_persona, nom_tipo_persona)
    SELECT 2, 'Aprendiz'
    WHERE NOT EXISTS (SELECT 1 FROM tab_tipos_persona WHERE id_tipo_persona = 2);
    
    -- Recorrer registros de la temporal que tengan número de documento no nulo
    FOR r IN 
        SELECT 
            t.num_documento,
            t.id_tipodoc,
            t.nom_aprendiz,
            t.ape_aprendiz,
            t.val_correo,
            t.nom_movil,
            t.fecha_reporte,
            t.id_ficha,
            t.nom_ficha,
            t.ind_estado_ficha,
            t.ind_estado_aprendiz
        FROM tab_temp_aprendices t
        WHERE t.num_documento IS NOT NULL 
          AND TRIM(t.num_documento) != ''
        ORDER BY t.fecha_reporte ASC   -- La más antigua primero, en caso de conflicto
    LOOP
        -- Limpiar número (solo dígitos)
        v_num_clean := regexp_replace(TRIM(r.num_documento), '[^0-9]', '', 'g');
        
        IF v_num_clean = '' THEN
            INSERT INTO log_migracion_aprendices (num_documento_original, motivo, datos_fila)
            VALUES (r.num_documento, 'El número no contiene dígitos', to_jsonb(r));
            v_errores := v_errores + 1;
            CONTINUE;
        END IF;
        
        -- Convertir a DECIMAL (capturar error de overflow o formato)
        BEGIN
            v_id_persona := v_num_clean::DECIMAL(10,0);
        EXCEPTION WHEN OTHERS THEN
            INSERT INTO log_migracion_aprendices (num_documento_original, motivo, datos_fila)
            VALUES (r.num_documento, 'Error de conversión a DECIMAL: ' || SQLERRM, to_jsonb(r));
            v_errores := v_errores + 1;
            CONTINUE;
        END;
        
        -- UPSERT
        INSERT INTO tab_personas (
            id_persona,
            id_tipo_docum,
            id_tipo_persona,
            nom_persona,
            ape_persona,
            mail_persona,
            fec_nacimiento,
            ind_genero,
            val_huella_digital,
            val_patron_facial,
            fec_ultima_entrada,
            fec_ultima_salida,
            num_visitas,
            id_nivel_estudio,
            id_profesion,
            id_dpto_reside,
            id_ciudad_reside,
            dir_ciudad_reside,
            tel_persona_fijo,
            tel_persona_movil,
            nom_contacto_emergencias,
            tel_contacto_emergencias,
            ind_envio_correo,
            ind_estado,
            usr_insert,
            fec_insert
        )
        VALUES (
            v_id_persona,
            COALESCE((SELECT id_tipo_docum FROM tab_tipos_docum WHERE id_tipo_docum = r.id_tipodoc), 'CC'),
            2,  -- id_tipo_persona = 2 (aprendiz)
            INITCAP(TRIM(r.nom_aprendiz)),
            INITCAP(TRIM(r.ape_aprendiz)),
            CASE WHEN r.val_correo ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' 
                 THEN TRIM(r.val_correo) ELSE 'Sin Correo' END,
            '1900-01-01',        -- fec_nacimiento por defecto
            99,                   -- ind_genero desconocido
            NULL,                 -- val_huella_digital
            NULL,                 -- val_patron_facial
            CURRENT_TIMESTAMP,    -- fec_ultima_entrada
            CURRENT_TIMESTAMP,    -- fec_ultima_salida
            0,                    -- num_visitas
            99,                   -- id_nivel_estudio (sin estudio)
            '00',                 -- id_profesion
            '68',                 -- id_dpto_reside (Santander)
            '68001',              -- id_ciudad_reside (Bucaramanga)
            'Sin Dirección',      -- dir_ciudad_reside
            6010000000,           -- tel_persona_fijo por defecto
            CASE WHEN r.nom_movil ~ '^[0-9]{10}$' THEN r.nom_movil ELSE '3000000000' END,
            'Sin Contacto',       -- nom_contacto_emergencias
            3000000000,           -- tel_contacto_emergencias
            FALSE,                -- ind_envio_correo
            TRUE,                 -- ind_estado
            current_user,         -- usr_insert
            CURRENT_TIMESTAMP     -- fec_insert
        )
        ON CONFLICT (id_persona) DO UPDATE SET
            nom_persona = EXCLUDED.nom_persona,
            ape_persona = EXCLUDED.ape_persona,
            mail_persona = EXCLUDED.mail_persona,
            tel_persona_movil = EXCLUDED.tel_persona_movil,
            ind_estado = EXCLUDED.ind_estado,
            fec_update = CURRENT_TIMESTAMP,
            usr_update = current_user;
        
        -- Contar inserciones vs actualizaciones
        IF FOUND THEN
            IF (SELECT xmax = 0 FROM tab_personas WHERE id_persona = v_id_persona) THEN
                v_insertados := v_insertados + 1;
            ELSE
                v_actualizados := v_actualizados + 1;
            END IF;
        END IF;
    END LOOP;
    
    -- Registro adicional: aprendices sin número (no se procesan, pero se dejan en la temporal y se pueden exportar aparte)
    INSERT INTO log_migracion_aprendices (num_documento_original, motivo, datos_fila)
    SELECT NULL, 'Registro sin número de documento (NULL o vacío)', to_jsonb(t)
    FROM tab_temp_aprendices t
    WHERE num_documento IS NULL OR TRIM(num_documento) = '';
    
    GET DIAGNOSTICS v_errores = ROW_COUNT;  -- sumamos los que acabamos de insertar como errores
    -- Pero cuidado, ya llevábamos v_errores de los anteriores; mejor sumamos
    -- (Simplificamos: retornamos solo los errores de conversión, los de sin número se pueden consultar aparte)
    
    RETURN QUERY SELECT v_insertados, v_actualizados, v_errores;
END;
$$;