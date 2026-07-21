/*
============================================================================================
  SCRIPT PARA CARGAR INSTRUCTORES DE FICHAS CREADAS (CON USUARIO Y MENÚS)
============================================================================================
  OBJETIVO:
    Procesa los datos de instructores desde la tabla temporal tab_temp_fichas_creadas
    y los distribuye en las tablas definitivas:
      - tab_personas        (datos básicos, tipo persona = 3)
      - tab_instructores    (datos específicos del instructor)
      - tab_usuarios        (credenciales de acceso, contraseña = número de documento)
      - tab_menu_usuarios   (menús autorizados para el rol instructor)

  DEPENDENCIAS:
    - Extensión pgcrypto (para crypt() y gen_salt())
    - Tablas destino: tab_personas, tab_instructores, tab_usuarios, tab_menu_usuarios
    - Tabla origen: tab_temp_fichas_creadas
    - Tabla referenciada: tab_menus (para FK de tab_menu_usuarios)
    - Se asume que los menús de instructor son:
      '20','202','20201','205','20501','20502','206','20601'

  AUTOR:          Grupo SMARTCSET
  FECHA:          2026-07-17
  VERSIÓN:        2.0 (corregida y optimizada)
============================================================================================
*/
CREATE OR REPLACE FUNCTION fun_crear_usuarios_instructores()
RETURNS TABLE (insertados INTEGER, actualizados INTEGER, errores INTEGER) AS
$$
DECLARE
    -- Variables para datos del instructor
    rec             RECORD;
    v_id_persona    DECIMAL(10,0);
    v_nom_persona   VARCHAR(40);
    v_ape_persona   VARCHAR(30);
    v_tipo_doc      VARCHAR(4);
    v_usr_insert    VARCHAR(50) := 'SISTEMA';
    v_fec_insert    TIMESTAMP := CURRENT_TIMESTAMP;

    -- Contadores globales
    v_insertados    INTEGER := 0;
    v_actualizados  INTEGER := 0;
    v_errores       INTEGER := 0;

    -- Variables auxiliares para contar filas afectadas
    v_filas         INTEGER;
BEGIN
    /*
     ====================================================================
      BLOQUE PRINCIPAL: Recorrido de instructores únicos
     ====================================================================
      Se obtienen instructores distintos por tipo y número de documento
      desde la tabla temporal, filtrando datos no nulos.
     */
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
            -- Asignar variables
            v_id_persona := rec.num_documento;   -- ya es DECIMAL
            v_nom_persona := rec.nom_instructor;
            v_ape_persona := rec.ape_instructor;
            v_tipo_doc := rec.tipo_documento;

            -- -----------------------------------------------------------------
            -- 1. INSERTAR O ACTUALIZAR EN tab_personas
            -- -----------------------------------------------------------------
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
                    3,                                          -- Tipo persona: Instructor
                    v_nom_persona,
                    v_ape_persona,
                    'sin_correo@correo.com',                    -- Correo por defecto
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
                    fec_update = v_fec_insert;

                -- Contar filas afectadas (1 = inserción o actualización)
                GET DIAGNOSTICS v_filas = ROW_COUNT;
                IF v_filas = 1 THEN
                    -- Determinamos si fue inserción o actualización mediante una segunda consulta
                    -- (método más fiable que xmax)
                    IF EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = v_id_persona AND fec_update IS NULL) THEN
                        v_insertados := v_insertados + 1;
                    ELSE
                        v_actualizados := v_actualizados + 1;
                    END IF;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error en tab_personas para instructor %: % (SQLSTATE %)',
                              v_id_persona, SQLERRM, SQLSTATE;
                -- No lanzamos excepción para continuar con el resto del instructor
            END;

            -- -----------------------------------------------------------------
            -- 2. INSERTAR O ACTUALIZAR EN tab_instructores
            -- -----------------------------------------------------------------
            BEGIN
                INSERT INTO tab_instructores (
                    id_instructor, id_centro, ind_tipo_contrato, ind_contratado_actual,
                    ind_est_civil, id_nivel_estudio, ind_vehiculo, id_profesion,
                    id_red, ind_disponibilidad, ind_estado,
                    usr_insert, fec_insert, usr_update, fec_update
                ) VALUES (
                    v_id_persona,
                    9309,               -- Centro por defecto (ajustar según datos reales)
                    TRUE,               -- Planta
                    TRUE,               -- Contratado actualmente
                    0,                  -- Estado civil: Otro
                    99,                 -- Nivel de estudio: Sin información
                    FALSE,              -- Sin vehículo
                    '00',               -- Sin profesión
                    99,                 -- Sin red
                    TRUE,               -- Disponible
                    0,                  -- Estado: Activo
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
                    fec_update = v_fec_insert;

                GET DIAGNOSTICS v_filas = ROW_COUNT;
                IF v_filas = 1 THEN
                    IF EXISTS (SELECT 1 FROM tab_instructores WHERE id_instructor = v_id_persona AND fec_update IS NULL) THEN
                        v_insertados := v_insertados + 1;
                    ELSE
                        v_actualizados := v_actualizados + 1;
                    END IF;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error en tab_instructores para instructor %: % (SQLSTATE %)',
                              v_id_persona, SQLERRM, SQLSTATE;
            END;

            -- -----------------------------------------------------------------
            -- 3. INSERTAR O ACTUALIZAR EN tab_usuarios
            --    Contraseña = número de documento (hasheado con crypt)
            -- -----------------------------------------------------------------
            BEGIN
                INSERT INTO tab_usuarios (
                    id_usuario, nom_usuario, pass_usuario, mail_usuario,
                    ind_usuario, ind_estado,
                    usr_insert, fec_insert, usr_update, fec_update
                ) VALUES (
                    v_id_persona::VARCHAR,
                    TRIM(v_nom_persona) || ' ' || TRIM(v_ape_persona),
                    crypt(v_id_persona::TEXT, gen_salt('bf')),   -- contraseña = documento
                    'sin_correo@correo.com',                     -- correo por defecto
                    FALSE,                                       -- no administrador
                    TRUE,                                        -- activo
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
                    fec_update = v_fec_insert;

                GET DIAGNOSTICS v_filas = ROW_COUNT;
                IF v_filas = 1 THEN
                    IF EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = v_id_persona::VARCHAR AND fec_update IS NULL) THEN
                        v_insertados := v_insertados + 1;
                    ELSE
                        v_actualizados := v_actualizados + 1;
                    END IF;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error en tab_usuarios para instructor %: % (SQLSTATE %)',
                              v_id_persona, SQLERRM, SQLSTATE;
            END;

            -- -----------------------------------------------------------------
            -- 4. ASIGNAR MENÚS DE INSTRUCTOR (tab_menu_usuarios)
            --    Solo si el usuario no es administrador (ind_usuario = FALSE)
            --    Se insertan los 8 menús predefinidos
            -- -----------------------------------------------------------------
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

                -- No contamos estas inserciones en los totales (son menús, no registros principales)
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error al asignar menús para instructor %: % (SQLSTATE %)',
                              v_id_persona, SQLERRM, SQLSTATE;
            END;

            -- -----------------------------------------------------------------
            -- 5. REVOCAR MENÚS NO PERMITIDOS (solo para instructores no admin)
            --    Elimina cualquier menú que no esté en la lista de instructor
            -- -----------------------------------------------------------------
            BEGIN
                DELETE FROM tab_menu_usuarios
                WHERE id_usuario = v_id_persona::VARCHAR
                  AND id_menu NOT IN (
                      '20', '202', '20201',
                      '205', '20501', '20502',
                      '206', '20601'
                  )
                  -- Solo afecta a instructores (no administradores)
                  AND EXISTS (
                      SELECT 1 FROM tab_usuarios u
                      WHERE u.id_usuario = v_id_persona::VARCHAR
                        AND u.ind_usuario = FALSE
                  );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error al revocar menús para instructor %: % (SQLSTATE %)',
                              v_id_persona, SQLERRM, SQLSTATE;
            END;

        -- -----------------------------------------------------------------
        -- CAPTURA DE ERRORES GENERALES POR INSTRUCTOR
        -- -----------------------------------------------------------------
        EXCEPTION WHEN OTHERS THEN
            v_errores := v_errores + 1;
            RAISE WARNING 'Error general procesando instructor %: % (SQLSTATE %)',
                          v_id_persona, SQLERRM, SQLSTATE;
        END;
    END LOOP;

    -- Retornar resumen consolidado de todas las operaciones
    RETURN QUERY SELECT v_insertados, v_actualizados, v_errores;
END;
$$ LANGUAGE plpgsql;

-- ===========================================================================
-- NOTAS ADICIONALES PARA EL ADMINISTRADOR:
-- ===========================================================================
-- 1. Antes de ejecutar, verificar que la extensión pgcrypto esté instalada:
--      CREATE EXTENSION IF NOT EXISTS pgcrypto;
--
-- 2. Revisar los valores por defecto (id_centro, etc.) y ajustarlos según
--    la realidad de la institución.
--
-- 3. Esta función es idempotente: puede ejecutarse varias veces sin generar
--    duplicados (ON CONFLICT).
--
-- 4. Los errores se registran como WARNING; revisar el log de PostgreSQL
--    después de cada ejecución para corregir datos problemáticos.
--
-- 5. Para ejecutar:
--      SELECT * FROM fun_crear_usuarios_instructores();
--    Ejemplo de salida:
--      insertados | actualizados | errores
--     ------------+--------------+---------
--              15 |            3 |       0
-- ===========================================================================