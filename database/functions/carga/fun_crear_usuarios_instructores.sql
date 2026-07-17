/*
============================================================================================
SCRIPT PARA CARGAR INSTRUCTORES DE FICHAS CREADAS (CON USUARIO)
============================================================================================
    OBJETIVO:
        Procesa los datos de instructores desde la tabla temporal tab_temp_fichas_creadas
        y los distribuye en las tablas definitivas:

    Dependencias:
        - Extensiones: pgcrypto (crypt, gen_salt)
        - Tablas: tab_temp_fichas_creadas, tab_personas, tab_instructores,
          tab_usuarios, tab_menu_usuarios, tab_menus (para FK)
        - Se asume que los menús de instructor están definidos como:
          '20','202','20201','205','20501','20502','206','20601'

    Autor:    Grupo SMARTCSET
    Fecha:    2026-07-16
    Versión:  1.0
============================================================================================
*/
CREATE OR REPLACE FUNCTION fun_crear_usuarios_instructores()
RETURNS TABLE (insertados INTEGER, actualizados INTEGER, errores INTEGER) AS
$$
  DECLARE
    rec RECORD;
    v_id_persona DECIMAL(10,0);
    v_nom_persona VARCHAR(40);
    v_ape_persona VARCHAR(30);
    v_tipo_doc VARCHAR(4);
    v_usr_insert VARCHAR(50) := 'SISTEMA';
    v_fec_insert TIMESTAMP := CURRENT_TIMESTAMP;
    
    -- Contadores
    v_insert_personas INTEGER := 0;
    v_update_personas INTEGER := 0;
    v_insert_instructores INTEGER := 0;
    v_update_instructores INTEGER := 0;
    v_insert_usuarios INTEGER := 0;
    v_update_usuarios INTEGER := 0;
    v_errores INTEGER := 0;
    
    -- Variables para control de operaciones dentro del loop
    v_persona_insert BOOLEAN;
    v_instructor_insert BOOLEAN;
    v_usuario_insert BOOLEAN;
BEGIN
    -- Recorremos instructores únicos (por tipo y número de documento)
    FOR rec IN (
        SELECT DISTINCT ON (tipo_documento, num_documento)
            tipo_documento,
            num_documento,
            nom_instructor,
            ape_instructor
        FROM tab_temp_fichas_creadas
        WHERE num_documento IS NOT NULL
          AND nom_instructor IS NOT NULL AND TRIM(nom_instructor) != ''
          AND ape_instructor IS NOT NULL AND TRIM(ape_instructor) != ''
        ORDER BY tipo_documento, num_documento
    ) LOOP
        BEGIN
            -- Reiniciar banderas de operación para este registro
            v_persona_insert := FALSE;
            v_instructor_insert := FALSE;
            v_usuario_insert := FALSE;
            
            -- Asignar variables
            v_id_persona := rec.num_documento; -- ya es DECIMAL
            v_nom_persona := rec.nom_instructor;
            v_ape_persona := rec.ape_instructor;
            v_tipo_doc := rec.tipo_documento;
            
            -- 1. Insertar o actualizar tab_personas (tipo persona = 3: Instructor)
            BEGIN
                INSERT INTO tab_personas (
                    id_persona, id_tipo_docum, id_tipo_persona, nom_persona, ape_persona,
                    mail_persona, fec_nacimiento, ind_genero,
                    val_huella_digital, val_patron_facial,
                    fec_ultima_entrada, fec_ultima_salida, num_visitas,
                    id_nivel_estudio, id_profesion,
                    id_dpto_reside, id_ciudad_reside, dir_ciudad_reside,
                    tel_persona_fijo, tel_persona_movil,
                    nom_contacto_emergencias, tel_contacto_emergencias,
                    ind_envio_correo, ind_estado,
                    usr_insert, fec_insert, usr_update, fec_update
                ) VALUES (
                    v_id_persona,
                    v_tipo_doc,
                    3, -- Instructor
                    v_nom_persona,
                    v_ape_persona,
                    'sin_correo@correo.com', -- por defecto, se podría mejorar
                    '1900-01-01'::DATE,
                    99,
                    NULL, NULL,
                    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0,
                    99, '00',
                    '68', '68001', 'Sin Dirección',
                    6010000000, 3000000000,
                    'Sin Contacto', 3000000000,
                    FALSE, TRUE,
                    v_usr_insert, v_fec_insert, NULL, NULL
                )
                ON CONFLICT (id_persona) DO UPDATE SET
                    nom_persona = EXCLUDED.nom_persona,
                    ape_persona = EXCLUDED.ape_persona,
                    id_tipo_docum = EXCLUDED.id_tipo_docum,
                    usr_update = v_usr_insert,
                    fec_update = v_fec_insert
                RETURNING (xmax = 0) AS inserted INTO v_persona_insert;
                
                IF v_persona_insert THEN
                    v_insert_personas := v_insert_personas + 1;
                ELSE
                    v_update_personas := v_update_personas + 1;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error al insertar/actualizar tab_personas para instructor %: % (SQLSTATE %)', 
                              v_id_persona, SQLERRM, SQLSTATE;
                -- No lanzamos excepción para continuar con el resto de operaciones de este instructor
            END;
            
            -- 2. Insertar o actualizar tab_instructores
            BEGIN
                INSERT INTO tab_instructores (
                    id_instructor, id_centro, ind_tipo_contrato, ind_contratado_actual,
                    ind_est_civil, id_nivel_estudio, ind_vehiculo, id_profesion,
                    id_red, ind_disponibilidad, ind_estado,
                    usr_insert, fec_insert, usr_update, fec_update
                ) VALUES (
                    v_id_persona,
                    9309,               -- id_centro por defecto (ajustar según datos)
                    TRUE,               -- ind_tipo_contrato: Planta por defecto
                    TRUE,               -- ind_contratado_actual: Contratado actualmente
                    0,                  -- ind_est_civil: Otro
                    99,                 -- id_nivel_estudio
                    FALSE,              -- ind_vehiculo
                    '00',               -- id_profesion
                    99,                 -- id_red
                    TRUE,               -- ind_disponibilidad
                    0,                  -- ind_estado: Activo
                    v_usr_insert,
                    v_fec_insert,
                    NULL,
                    NULL
                )
                ON CONFLICT (id_instructor) DO UPDATE SET
                    id_centro = EXCLUDED.id_centro,
                    ind_tipo_contrato = EXCLUDED.ind_tipo_contrato,
                    ind_contratado_actual = EXCLUDED.ind_contratado_actual,
                    ind_estado = EXCLUDED.ind_estado,
                    usr_update = v_usr_insert,
                    fec_update = v_fec_insert
                RETURNING (xmax = 0) AS inserted INTO v_instructor_insert;
                
                IF v_instructor_insert THEN
                    v_insert_instructores := v_insert_instructores + 1;
                ELSE
                    v_update_instructores := v_update_instructores + 1;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error al insertar/actualizar tab_instructores para instructor %: % (SQLSTATE %)', 
                              v_id_persona, SQLERRM, SQLSTATE;
            END;
            
            -- 3. Insertar o actualizar tab_usuarios (contraseña = num_documento)
            BEGIN
                INSERT INTO tab_usuarios (
                    id_usuario, nom_usuario, pass_usuario, mail_usuario,
                    ind_usuario, ind_estado,
                    usr_insert, fec_insert, usr_update, fec_update
                ) VALUES (
                    v_id_persona::VARCHAR,
                    v_nom_persona || ' ' || v_ape_persona,
                    crypt(v_id_persona::TEXT, gen_salt('bf')),  -- contraseña = número de documento
                    'sin_correo@correo.com',  -- por defecto, se podría mejorar
                    FALSE,  -- no administrador
                    TRUE,   -- activo
                    v_usr_insert,
                    v_fec_insert,
                    NULL,
                    NULL
                )
                ON CONFLICT (id_usuario) DO UPDATE SET
                    nom_usuario = EXCLUDED.nom_usuario,
                    pass_usuario = EXCLUDED.pass_usuario,
                    mail_usuario = EXCLUDED.mail_usuario,
                    ind_estado = EXCLUDED.ind_estado,
                    usr_update = v_usr_insert,
                    fec_update = v_fec_insert
                RETURNING (xmax = 0) AS inserted INTO v_usuario_insert;
                
                IF v_usuario_insert THEN
                    v_insert_usuarios := v_insert_usuarios + 1;
                ELSE
                    v_update_usuarios := v_update_usuarios + 1;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error al insertar/actualizar tab_usuarios para instructor %: % (SQLSTATE %)', 
                              v_id_persona, SQLERRM, SQLSTATE;
            END;
            
            -- 4. Asignar menús de instructor (solo si el usuario no es administrador)
            -- Se asume que los instructores nunca son administradores (ind_usuario = FALSE)
            BEGIN
                INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
                SELECT 
                    v_id_persona::VARCHAR,
                    m.id_menu,
                    v_usr_insert,
                    v_fec_insert
                FROM (VALUES 
                    ('20'), ('202'), ('20201'),
                    ('205'), ('20501'), ('20502'),
                    ('206'), ('20601')
                ) AS m(id_menu)
                ON CONFLICT (id_usuario, id_menu) DO NOTHING;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error al asignar menús para instructor %: % (SQLSTATE %)', 
                              v_id_persona, SQLERRM, SQLSTATE;
            END;
            
            -- 5. Revocar menús que no correspondan a instructor (solo para no administradores)
            BEGIN
                DELETE FROM tab_menu_usuarios
                WHERE id_usuario = v_id_persona::VARCHAR
                  AND id_menu NOT IN (
                      '20', '202', '20201',
                      '205', '20501', '20502',
                      '206', '20601'
                  )
                  -- Aseguramos que solo afecta a instructores y no a administradores
                  AND EXISTS (
                      SELECT 1 FROM tab_usuarios u
                      WHERE u.id_usuario = v_id_persona::VARCHAR
                        AND u.ind_usuario = FALSE
                  );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error al revocar menús para instructor %: % (SQLSTATE %)', 
                              v_id_persona, SQLERRM, SQLSTATE;
            END;
            
        EXCEPTION WHEN OTHERS THEN
            v_errores := v_errores + 1;
            RAISE WARNING 'Error general procesando instructor %: % (SQLSTATE %)', 
                          v_id_persona, SQLERRM, SQLSTATE;
        END;
    END LOOP;
    
    -- Retornar estadísticas
    RETURN QUERY SELECT 
        v_insert_personas, v_update_personas,
        v_insert_instructores, v_update_instructores,
        v_insert_usuarios, v_update_usuarios,
        v_errores;
END;
$$ LANGUAGE plpgsql;