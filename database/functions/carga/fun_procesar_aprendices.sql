/*
================================================================================
  SCRIPT: FUNCIÓN PARA CARGAR APRENDICES DESDE TABLA TEMPORAL
================================================================================
  TÍTULO: 
    fun_procesar_aprendices()
  
  OBJETIVO:
    Procesar los registros de aprendices contenidos en la tabla temporal
    tab_temp_aprendices y distribuirlos en las tablas normalizadas del sistema:
      - tab_personas: datos básicos de la persona (identificación, nombres, 
                      contactos, ubicación, etc.)
      - tab_aprendices: datos específicos del aprendiz (ficha actual, estado 
                        de formación, llamados de atención, etc.)
      - tab_aprendices_fichas: historial de todas las fichas en las que ha 
                               estado el aprendiz (relación muchos a muchos).
  
  LÓGICA DE NEGOCIO:
    - Cada persona se identifica de forma única por (id_tipodoc, num_documento).
    - De todas las fichas asociadas a una persona, se selecciona como "ficha
      actual" aquella que tenga estado '3' (en ejecución), o en su defecto,
      la más reciente según fecha_reporte.
    - El estado de formación del aprendiz se normaliza mediante unaccent y
      se mapea a un código numérico (1-9).
  
  RETORNO:
    TEXT con un resumen en formato: "Procesados total: X | Errores: Y"
  
  DEPENDENCIAS:
    - Extensión PostgreSQL 'unaccent' (para eliminar tildes en los estados).
    - Tabla origen: tab_temp_aprendices.
    - Tablas destino: tab_personas, tab_aprendices, tab_aprendices_fichas.
    - Tabla auxiliar: tab_fichas (para obtener id_jornada en el histórico).
    - Las tablas referenciadas por claves foráneas deben existir y tener los
      datos necesarios (tab_tipos_docum, tab_tipos_persona, etc.).
  
  AUTOR:           Grupo SMARTCSET
  FECHA CREACIÓN:  2026-07-16
  VERSIÓN:         2.0
  ÚLTIMA REVISIÓN: 2026-07-17
================================================================================
*/

CREATE OR REPLACE FUNCTION fun_procesar_aprendices()
RETURNS TEXT AS $$
DECLARE
    -- Variables para almacenar los datos de la persona actual
    rec                 RECORD;                      -- Registro del cursor
    v_id_persona        DECIMAL(10,0);              -- Número de documento (PK de persona)
    v_nom_persona       VARCHAR(40);                -- Nombre del aprendiz
    v_ape_persona       VARCHAR(30);                -- Apellido del aprendiz
    v_mail_persona      VARCHAR;                    -- Correo electrónico
    v_tel_movil         DECIMAL(10,0);              -- Teléfono móvil normalizado
    v_id_ficha_actual   DECIMAL(10,0);              -- ID de la ficha prioritaria
    v_estado_aprendiz   VARCHAR;                    -- Estado de formación en texto
    v_estado_num        DECIMAL(1,0);               -- Estado de formación en código (1-9)
    v_usr_insert        VARCHAR(50) := 'SISTEMA';   -- Usuario que inserta (por defecto)
    v_fec_insert        TIMESTAMP := CURRENT_TIMESTAMP; -- Fecha y hora de inserción
    v_total             INT := 0;                   -- Contador de registros procesados
    v_errores           INT := 0;                   -- Contador de errores
BEGIN
    /*
     ========================================================================
      BLOQUE PRINCIPAL: RECORRIDO DE PERSONAS DISTINTAS
     ========================================================================
      Se utiliza una CTE con ROW_NUMBER() para obtener, en una sola consulta,
      la lista de personas únicas y su ficha prioritaria. Esto elimina
      subconsultas correlacionadas y mejora el rendimiento.
     */
    FOR rec IN (
        WITH personas_distintas AS (
            -- Obtener una fila por persona (la más reciente por fecha_reporte)
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
            -- Asignar prioridad (rn=1) a la ficha con estado '3' o la más reciente
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
        -- Combinar personas con su ficha prioritaria (rn = 1)
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
        -- Incrementar el contador de registros procesados
        v_total := v_total + 1;

        /*
         ====================================================================
          SUB-BLOQUE POR PERSONA: MANEJO DE EXCEPCIONES
         ====================================================================
          Cada persona se procesa en un bloque BEGIN...EXCEPTION para que
          un error en una persona no detenga el procesamiento de las demás.
         */
        BEGIN
            -- ------------------------------------------------------------------
            -- 1. ASIGNACIÓN DE VARIABLES CON CONVERSIONES EXPLÍCITAS
            -- ------------------------------------------------------------------
            -- Se convierten los campos VARCHAR a los tipos esperados (DECIMAL).
            -- Esto permite capturar errores de formato (ej. documentos no numéricos).
            v_id_persona := rec.num_documento::DECIMAL(10,0);
            v_nom_persona := rec.nom_aprendiz;
            v_ape_persona := rec.ape_aprendiz;
            v_mail_persona := rec.val_correo;
            v_estado_aprendiz := rec.ind_estado_aprendiz;
            -- Conversión explícita de la ficha (puede ser NULL si no se encontró)
            v_id_ficha_actual := rec.id_ficha_actual::DECIMAL(10,0);

            -- Validar que la ficha actual exista
            IF v_id_ficha_actual IS NULL THEN
                RAISE EXCEPTION 'No se encontró ficha para persona %', v_id_persona;
            END IF;

            -- ------------------------------------------------------------------
            -- 2. PROCESAMIENTO DE TELÉFONO MÓVIL
            -- ------------------------------------------------------------------
            -- Se intenta convertir nom_movil a DECIMAL. Si falla, se asigna 3000000000.
            -- Luego se valida que esté en el rango permitido: [3000000000, 3519999999].
            BEGIN
                v_tel_movil := COALESCE(rec.nom_movil::DECIMAL(10,0), 3000000000);
                IF v_tel_movil NOT BETWEEN 3000000000 AND 3519999999 THEN
                    v_tel_movil := 3000000000;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                -- Si la conversión falla, se asigna el valor por defecto
                v_tel_movil := 3000000000;
            END;

            -- ------------------------------------------------------------------
            -- 3. CONVERSIÓN DE ESTADO DE FORMACIÓN
            -- ------------------------------------------------------------------
            -- Se normaliza el texto (eliminando tildes y convirtiendo a minúsculas)
            -- y se mapea a un código numérico según la lógica de negocio.
            v_estado_num := CASE
                WHEN unaccent(lower(v_estado_aprendiz)) = 'en formacion' THEN 1
                WHEN unaccent(lower(v_estado_aprendiz)) = 'aplazado' THEN 2
                WHEN unaccent(lower(v_estado_aprendiz)) = 'retiro voluntario' THEN 3
                WHEN unaccent(lower(v_estado_aprendiz)) = 'cancelado' THEN 4
                WHEN unaccent(lower(v_estado_aprendiz)) = 'condicionado' THEN 5
                WHEN unaccent(lower(v_estado_aprendiz)) = 'por certificar' THEN 6
                WHEN unaccent(lower(v_estado_aprendiz)) = 'certificado' THEN 7
                WHEN unaccent(lower(v_estado_aprendiz)) = 'trasladado' THEN 8
                ELSE 9 -- Sin información
            END;

            -- ------------------------------------------------------------------
            -- 4. INSERCIÓN / ACTUALIZACIÓN EN tab_personas
            -- ------------------------------------------------------------------
            -- Usamos ON CONFLICT (id_persona) para manejar duplicados.
            -- Si la persona ya existe, se actualizan solo los campos que pueden
            -- cambiar (nombre, apellido, correo, teléfono móvil).
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
                2,                                  -- id_tipo_persona: Aprendiz
                v_nom_persona,
                v_ape_persona,
                COALESCE(v_mail_persona, 'sin_correo@correo.com'),
                '1900-01-01'::DATE,                 -- Fecha nacimiento por defecto
                99,                                 -- ind_genero: No definido
                NULL,                               -- val_huella_digital (biométrica)
                NULL,                               -- val_patron_facial (biométrico)
                CURRENT_TIMESTAMP,                  -- fec_ultima_entrada
                CURRENT_TIMESTAMP,                  -- fec_ultima_salida
                0,                                  -- num_visitas inicial
                99,                                 -- id_nivel_estudio: Sin estudio
                '00',                               -- id_profesion: Sin profesión
                '68',                               -- id_dpto_reside: Santander (ejemplo)
                '68001',                            -- id_ciudad_reside: Bucaramanga (ejemplo)
                'Sin Dirección',                    -- dir_ciudad_reside por defecto
                6010000000,                         -- tel_persona_fijo por defecto
                v_tel_movil,                        -- tel_persona_movil normalizado
                'Sin Contacto',                     -- nom_contacto_emergencias por defecto
                3000000000,                         -- tel_contacto_emergencias por defecto
                FALSE,                              -- ind_envio_correo: No enviar por defecto
                TRUE,                               -- ind_estado: Activo
                v_usr_insert,
                v_fec_insert,
                NULL::VARCHAR,
                NULL::TIMESTAMP
            )
            ON CONFLICT (id_persona) DO UPDATE SET
                nom_persona = EXCLUDED.nom_persona,
                ape_persona = EXCLUDED.ape_persona,
                mail_persona = EXCLUDED.mail_persona,
                tel_persona_movil = EXCLUDED.tel_persona_movil,
                usr_update = v_usr_insert,
                fec_update = v_fec_insert;

            -- ------------------------------------------------------------------
            -- 5. INSERCIÓN / ACTUALIZACIÓN EN tab_aprendices
            -- ------------------------------------------------------------------
            -- Se vincula al aprendiz con su ficha actual. Si ya existe, se actualiza
            -- la ficha y el estado de formación.
            INSERT INTO tab_aprendices (
                id_aprendiz, datos_aprendiz, id_ficha, num_llamados,
                ind_etdo_formacion,
                usr_insert, fec_insert, usr_update, fec_update
            ) VALUES (
                v_id_persona,
                NULL,                               -- datos_aprendiz no se utiliza
                v_id_ficha_actual,
                0,                                  -- num_llamados inicial
                v_estado_num,
                v_usr_insert,
                v_fec_insert,
                NULL::VARCHAR,
                NULL::TIMESTAMP
            )
            ON CONFLICT (id_aprendiz) DO UPDATE SET
                id_ficha = EXCLUDED.id_ficha,
                ind_etdo_formacion = EXCLUDED.ind_etdo_formacion,
                usr_update = v_usr_insert,
                fec_update = v_fec_insert;

            -- ------------------------------------------------------------------
            -- 6. INSERCIÓN DE HISTÓRICO DE FICHAS (tab_aprendices_fichas)
            -- ------------------------------------------------------------------
            -- Se insertan todas las fichas asociadas a la persona (sin duplicados).
            -- IMPORTANTE: Se convierte f.id_ficha (DECIMAL) a texto para igualar
            -- con t.id_ficha (VARCHAR), evitando el error de operador entre tipos.
            -- Luego, al insertar, se convierte t.id_ficha a DECIMAL para que
            -- coincida con el tipo de la columna destino.
            INSERT INTO tab_aprendices_fichas (id_ficha, id_aprendiz, id_jornada, usr_insert, fec_insert)
            SELECT DISTINCT
                t.id_ficha::DECIMAL(10,0),           -- Convertir VARCHAR a DECIMAL
                v_id_persona,
                f.id_jornada,
                v_usr_insert,
                v_fec_insert
            FROM tab_temp_aprendices t
            JOIN tab_fichas f ON t.id_ficha = f.id_ficha::text   -- Conversión clave: DECIMAL a TEXT
            WHERE t.id_tipodoc = rec.id_tipodoc
              AND t.num_documento = rec.num_documento
            ON CONFLICT (id_ficha, id_aprendiz) DO NOTHING;      -- Evita duplicados

        -- ------------------------------------------------------------------
        -- MANEJO DE EXCEPCIONES POR PERSONA
        -- ------------------------------------------------------------------
        EXCEPTION WHEN OTHERS THEN
            v_errores := v_errores + 1;
            -- Se registra el error en el log de PostgreSQL con detalle
            RAISE WARNING 'Error en persona %: % (SQLSTATE %)', 
                v_id_persona, SQLERRM, SQLSTATE;
        END;
    END LOOP;

    -- Retorno del resumen de ejecución
    RETURN format('Procesados total: %s | Errores: %s', v_total, v_errores);
END;
$$ LANGUAGE plpgsql;

/*
================================================================================
  NOTAS ADICIONALES Y RECOMENDACIONES
================================================================================

  1. INSTALACIÓN DE EXTENSIONES:
     - La función utiliza la extensión 'unaccent'. Si no está instalada,
       ejecutar: CREATE EXTENSION IF NOT EXISTS unaccent;

  2. VERIFICACIÓN DE DATOS PREVIOS:
     - Antes de ejecutar la función, verifique que los datos en
       tab_temp_aprendices sean válidos:
         - num_documento: debe ser convertible a DECIMAL.
         - id_ficha: debe existir en tab_fichas (para el JOIN).
         - ind_estado_ficha: valores esperados '3' u otros.

  3. RENDIMIENTO:
     - Se recomienda crear índices en tab_temp_aprendices sobre
       (id_tipodoc, num_documento, fecha_reporte) e ind_estado_ficha
       para acelerar la consulta principal.

  4. PRUEBAS:
     - Ejecutar la función en un entorno de pruebas antes de producción.
     - Monitorear los WARNING para identificar registros problemáticos.

  5. MANTENIMIENTO:
     - Si se agregan nuevos estados de formación, actualizar el CASE
       en la sección 3.
     - Si cambia el rango de teléfonos móviles, modificar las constantes
       3000000000 y 3519999999 en la sección 2.

  6. EJECUCIÓN:
     SELECT fun_procesar_aprendices();

================================================================================
  HISTORIAL DE VERSIONES
================================================================================
  Versión | Fecha       | Descripción de cambios
  --------|-------------|--------------------------------------------------------
  1.0     | 2026-07-16  | Versión inicial.
  2.0     | 2026-07-17  | Corrección de errores de tipo (VARCHAR vs DECIMAL).
          |             | Optimización con CTE y ROW_NUMBER().
          |             | Documentación completa y detallada.
================================================================================
*/