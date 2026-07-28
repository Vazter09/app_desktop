/*
============================================================================================
  SCRIPT PARA CARGAR APRENDICES CON FICHAS (PERSONAS, APRENDICES Y FICHAS HISTÓRICAS)
============================================================================================
  OBJETIVO:
    Procesa los datos de aprendices desde la tabla temporal tab_temp_aprendices
    y los distribuye en las tablas definitivas:
      - tab_personas           (datos básicos, tipo persona = 2)
      - tab_aprendices         (datos específicos del aprendiz, ficha actual y estado)
      - tab_aprendices_fichas  (historial de todas las fichas asociadas al aprendiz)

  DEPENDENCIAS:
    - Extensión unaccent (para normalizar tildes en los estados)
    - Tablas destino: tab_personas, tab_aprendices, tab_aprendices_fichas
    - Tabla origen: tab_temp_aprendices
    - Tabla referenciada: tab_fichas (para obtener id_jornada en el histórico)
    - Todas las tablas referenciadas por claves foráneas deben existir

  AUTOR:          Grupo SMARTCSET
  FECHA:          2026-07-17
  VERSIÓN:        2.0 (corregida y optimizada)
============================================================================================
*/
CREATE OR REPLACE FUNCTION fun_procesar_aprendices()
RETURNS TABLE (insertados INTEGER, actualizados INTEGER, errores INTEGER) AS
$$
DECLARE
    -- Variables para datos de la persona
    rec                RECORD;
    v_id_persona       DECIMAL(10,0);
    v_nom_persona      VARCHAR(40);
    v_ape_persona      VARCHAR(30);
    v_mail_persona     VARCHAR;
    v_tel_movil        DECIMAL(10,0);
    v_id_ficha_actual  DECIMAL(10,0);
    v_estado_aprendiz  VARCHAR;
    v_estado_num       DECIMAL(1,0);
    v_usr_insert       VARCHAR(50) := 'SISTEMA';
    v_fec_insert       TIMESTAMP := CURRENT_TIMESTAMP;

    -- Contadores globales
    v_insertados       INTEGER := 0;
    v_actualizados     INTEGER := 0;
    v_errores          INTEGER := 0;

    -- Variables auxiliares
    v_filas            INTEGER;
BEGIN
    /*
     ====================================================================
      BLOQUE PRINCIPAL: Recorrido de aprendices únicos con ficha prioritaria
     ====================================================================
      Se utiliza una CTE para obtener en una sola consulta:
        - Personas distintas (por tipo y número de documento)
        - Ficha prioritaria: estado '3' (en ejecución) o la más reciente
      Esto evita subconsultas correlacionadas y mejora el rendimiento.
     */
    FOR rec IN (
        WITH personas_distintas AS (
            SELECT DISTINCT ON (id_tipodoc, num_documento)
                id_tipodoc,
                num_documento,
                nom_aprendiz,
                ape_aprendiz,
                val_correo,
                nom_movil,
                ind_estado_aprendiz
            FROM tab_temp_aprendices
            ORDER BY id_tipodoc, num_documento, fecha_reporte DESC
        ),
        fichas_prioridad AS (
            SELECT
                t.id_tipodoc,
                t.num_documento,
                t.id_ficha,
                ROW_NUMBER() OVER (
                    PARTITION BY t.id_tipodoc, t.num_documento
                    ORDER BY
                        CASE WHEN t.ind_estado_ficha = '3' THEN 0 ELSE 1 END,
                        t.fecha_reporte DESC
                ) AS rn
            FROM tab_temp_aprendices t
        )
        SELECT
            p.id_tipodoc,
            p.num_documento,
            p.nom_aprendiz,
            p.ape_aprendiz,
            p.val_correo,
            p.nom_movil,
            p.ind_estado_aprendiz,
            f.id_ficha AS id_ficha_actual
        FROM personas_distintas p
        LEFT JOIN fichas_prioridad f
            ON p.id_tipodoc = f.id_tipodoc
            AND p.num_documento = f.num_documento
            AND f.rn = 1
        ORDER BY p.id_tipodoc, p.num_documento
    ) LOOP
        BEGIN
            -- -----------------------------------------------------------------
            -- 1. ASIGNACIÓN DE VARIABLES CON CONVERSIONES EXPLÍCITAS
            -- -----------------------------------------------------------------
            -- Se convierten campos VARCHAR a DECIMAL para evitar errores de tipo
            v_id_persona := rec.num_documento::DECIMAL(10,0);
            v_nom_persona := rec.nom_aprendiz;
            v_ape_persona := rec.ape_aprendiz;
            v_mail_persona := rec.val_correo;
            v_estado_aprendiz := rec.ind_estado_aprendiz;
            v_id_ficha_actual := rec.id_ficha_actual::DECIMAL(10,0);

            -- Validar que exista ficha actual
            IF v_id_ficha_actual IS NULL THEN
                RAISE EXCEPTION 'No se encontró ficha para persona %', v_id_persona;
            END IF;

            -- -----------------------------------------------------------------
            -- 2. PROCESAMIENTO DE TELÉFONO MÓVIL (con conversión segura)
            -- -----------------------------------------------------------------
            BEGIN
                v_tel_movil := COALESCE(rec.nom_movil::DECIMAL(10,0), 3000000000);
                IF v_tel_movil NOT BETWEEN 3000000000 AND 3519999999 THEN
                    v_tel_movil := 3000000000;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                v_tel_movil := 3000000000;
            END;

            -- -----------------------------------------------------------------
            -- 3. CONVERSIÓN DE ESTADO DE FORMACIÓN (usando unaccent)
            -- -----------------------------------------------------------------
            v_estado_num := CASE
                WHEN unaccent(lower(v_estado_aprendiz)) = 'en formacion' THEN 1
                WHEN unaccent(lower(v_estado_aprendiz)) = 'aplazado' THEN 2
                WHEN unaccent(lower(v_estado_aprendiz)) = 'retiro voluntario' THEN 3
                WHEN unaccent(lower(v_estado_aprendiz)) = 'cancelado' THEN 4
                WHEN unaccent(lower(v_estado_aprendiz)) = 'condicionado' THEN 5
                WHEN unaccent(lower(v_estado_aprendiz)) = 'por certificar' THEN 6
                WHEN unaccent(lower(v_estado_aprendiz)) = 'certificado' THEN 7
                WHEN unaccent(lower(v_estado_aprendiz)) = 'trasladado' THEN 8
                ELSE 9   -- Sin información
            END;

            -- -----------------------------------------------------------------
            -- 4. INSERTAR O ACTUALIZAR EN tab_personas
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
                    rec.id_tipodoc,
                    2,                                       -- Tipo persona: Aprendiz
                    v_nom_persona,
                    v_ape_persona,
                    COALESCE(v_mail_persona, 'sin_correo@correo.com'),
                    '1900-01-01'::DATE,
                    99,
                    NULL, NULL,
                    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0,
                    99, '00',
                    '68', '68001', 'Sin Dirección',
                    6010000000, v_tel_movil,
                    'Sin Contacto', 3000000000,
                    FALSE, TRUE,
                    v_usr_insert, v_fec_insert, NULL, NULL
                )
                ON CONFLICT (id_persona) DO UPDATE SET
                    nom_persona = EXCLUDED.nom_persona,
                    ape_persona = EXCLUDED.ape_persona,
                    mail_persona = EXCLUDED.mail_persona,
                    tel_persona_movil = EXCLUDED.tel_persona_movil,
                    usr_update = v_usr_insert,
                    fec_update = v_fec_insert;

                GET DIAGNOSTICS v_filas = ROW_COUNT;
                IF v_filas = 1 THEN
                    IF EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = v_id_persona AND fec_update IS NULL) THEN
                        v_insertados := v_insertados + 1;
                    ELSE
                        v_actualizados := v_actualizados + 1;
                    END IF;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error en tab_personas para aprendiz %: % (SQLSTATE %)',
                              v_id_persona, SQLERRM, SQLSTATE;
            END;

            -- -----------------------------------------------------------------
            -- 5. INSERTAR O ACTUALIZAR EN tab_aprendices
            -- -----------------------------------------------------------------
            BEGIN
                INSERT INTO tab_aprendices (
                    id_aprendiz, datos_aprendiz, id_ficha, num_llamados,
                    ind_etdo_formacion,
                    usr_insert, fec_insert, usr_update, fec_update
                ) VALUES (
                    v_id_persona,
                    NULL,
                    v_id_ficha_actual,
                    0,
                    v_estado_num,
                    v_usr_insert,
                    v_fec_insert,
                    NULL,
                    NULL
                )
                ON CONFLICT (id_aprendiz) DO UPDATE SET
                    id_ficha = EXCLUDED.id_ficha,
                    ind_etdo_formacion = EXCLUDED.ind_etdo_formacion,
                    usr_update = v_usr_insert,
                    fec_update = v_fec_insert;

                GET DIAGNOSTICS v_filas = ROW_COUNT;
                IF v_filas = 1 THEN
                    IF EXISTS (SELECT 1 FROM tab_aprendices WHERE id_aprendiz = v_id_persona AND fec_update IS NULL) THEN
                        v_insertados := v_insertados + 1;
                    ELSE
                        v_actualizados := v_actualizados + 1;
                    END IF;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error en tab_aprendices para aprendiz %: % (SQLSTATE %)',
                              v_id_persona, SQLERRM, SQLSTATE;
            END;

            -- -----------------------------------------------------------------
            -- 6. INSERTAR HISTÓRICO DE FICHAS (tab_aprendices_fichas)
            --    Se insertan todas las fichas asociadas a la persona
            --    IMPORTANTE: Conversión explícita para evitar error de tipos
            --                entre VARCHAR y DECIMAL
            -- -----------------------------------------------------------------
            BEGIN
                INSERT INTO tab_aprendices_fichas (id_ficha, id_aprendiz, id_jornada, usr_insert, fec_insert)
                SELECT DISTINCT
                    t.id_ficha::DECIMAL(10,0),                     -- Convertir VARCHAR a DECIMAL
                    v_id_persona,
                    f.id_jornada,
                    v_usr_insert,
                    v_fec_insert
                FROM tab_temp_aprendices t
                JOIN tab_fichas f ON t.id_ficha = f.id_ficha::text   -- Convertir DECIMAL a TEXT
                WHERE t.id_tipodoc = rec.id_tipodoc
                  AND t.num_documento = rec.num_documento
                ON CONFLICT (id_ficha, id_aprendiz) DO NOTHING;

                -- No contamos estas inserciones en los totales (son históricos)
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error en tab_aprendices_fichas para aprendiz %: % (SQLSTATE %)',
                              v_id_persona, SQLERRM, SQLSTATE;
            END;

        -- -----------------------------------------------------------------
        -- CAPTURA DE ERRORES GENERALES POR APRENDIZ
        -- -----------------------------------------------------------------
        EXCEPTION WHEN OTHERS THEN
            v_errores := v_errores + 1;
            RAISE WARNING 'Error general procesando aprendiz %: % (SQLSTATE %)',
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
-- 1. Antes de ejecutar, verificar que la extensión unaccent esté instalada:
--      CREATE EXTENSION IF NOT EXISTS unaccent;
--
-- 2. Esta función es idempotente: puede ejecutarse varias veces sin generar
--    duplicados (ON CONFLICT).
--
-- 3. Los errores se registran como WARNING; revisar el log de PostgreSQL
--    después de cada ejecución para corregir datos problemáticos.
--
-- 4. La ficha prioritaria se selecciona así:
--      - Primero: estado '3' (en ejecución)
--      - Segundo: la más reciente (fecha_reporte DESC)
--
-- 5. Para ejecutar:
--      SELECT * FROM fun_procesar_aprendices();
--    Ejemplo de salida:
--      insertados | actualizados | errores
--     ------------+--------------+---------
--              25 |            5 |       0
-- ===========================================================================