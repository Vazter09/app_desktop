/*
============================================================================================
  SCRIPT PARA CONTROL DE INGRESOS Y SALIDAS DE PERSONAS EN EL CENTRO
============================================================================================
  OBJETIVO:
    Implementar la lógica de negocio para el registro de ingresos y salidas de personas
    en el centro, garantizando la integridad de los datos mediante:
      - Índices estratégicos para rendimiento
      - Funciones auxiliares
      - Procedimientos almacenados con manejo de concurrencia (FOR UPDATE)
      - Triggers de seguridad que previenen operaciones DML directas que violen las reglas

  DEPENDENCIAS:
    - Tablas: tab_personas, tab_log_ingresos, tab_novedades_ingreso
    - Extensiones: vector (para facial_embedding)
    - La función fn_diferencia_minutos() es requerida por los procedimientos y triggers

  AUTOR:          Grupo SMARTCSET
  FECHA:          2026-07-17
  VERSIÓN:        1.0
============================================================================================
*/

-- =============================================================================
-- 1. ÍNDICES ESTRATÉGICOS PARA RENDIMIENTO
-- =============================================================================

-- Índice parcial para encontrar rápidamente ingresos activos por persona
CREATE INDEX IF NOT EXISTS idx_log_activos_persona 
ON tab_log_ingresos (id_visitante) 
WHERE fec_salida = fec_ingreso;

-- Índice compuesto para obtener el historial de ingresos de una persona (ordenado)
CREATE INDEX IF NOT EXISTS idx_log_persona_fechas 
ON tab_log_ingresos (id_visitante, fec_ingreso DESC);

-- Índice parcial para obtener la última salida registrada de una persona
CREATE INDEX IF NOT EXISTS idx_log_ultima_salida 
ON tab_log_ingresos (id_visitante, fec_salida DESC) 
WHERE fec_salida > fec_ingreso;

-- Índice para búsquedas por número de documento en novedades
CREATE INDEX IF NOT EXISTS idx_novedades_documento 
ON tab_novedades_ingreso (num_documento);

COMMENT ON INDEX idx_log_activos_persona IS 
    'Índice para localizar rápidamente si una persona tiene un ingreso activo (sin salida).';
COMMENT ON INDEX idx_log_persona_fechas IS 
    'Índice para obtener el historial de ingresos de una persona de forma eficiente.';
COMMENT ON INDEX idx_log_ultima_salida IS 
    'Índice para obtener la última salida registrada de una persona.';
COMMENT ON INDEX idx_novedades_documento IS 
    'Índice para buscar rápidamente novedades por número de documento.';

-- =============================================================================
-- 2. FUNCIONES AUXILIARES
-- =============================================================================

-- Función para calcular la diferencia en minutos entre dos timestamps
CREATE OR REPLACE FUNCTION fn_diferencia_minutos(p_fecha1 TIMESTAMP, p_fecha2 TIMESTAMP)
RETURNS NUMERIC AS $$
BEGIN
    RETURN EXTRACT(EPOCH FROM (p_fecha1 - p_fecha2)) / 60;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION fn_diferencia_minutos IS 
    'Retorna la diferencia en minutos entre (p_fecha1 - p_fecha2).';

-- =============================================================================
-- 3. PROCEDIMIENTO: sp_registrar_ingreso
-- =============================================================================
/*
  sp_registrar_ingreso
  ====================
  Propósito:
    Registra un nuevo ingreso de una persona en el centro.
    - Si la persona no existe en tab_personas, se crea una novedad en 
      tab_novedades_ingreso con los datos proporcionados y finaliza.
    - Si existe, valida que no tenga ingreso activo y que hayan pasado 
      al menos 5 minutos desde su última salida.
    - Inserta en tab_log_ingresos y actualiza fec_ultima_entrada y 
      num_visitas en tab_personas.
    - Usa FOR UPDATE para manejo de concurrencia.

  Parámetros:
    - p_num_documento     DECIMAL(10,0)   : Número de documento de la persona
    - p_nom_tercero       VARCHAR(40)     : Nombre de la persona (para novedades)
    - p_ape_tercero       VARCHAR(30)     : Apellido de la persona (para novedades)
    - p_id_entrada_centro DECIMAL(1,0)    : ID de la entrada utilizada (1-4)
    - p_id_metodo_aut     DECIMAL(2,0)    : Método de autenticación (1:Huella,2:Facial,3:Ambos)
    - p_ind_dispositivo   BOOLEAN         : ¿Usó dispositivo móvil?
    - p_facial_embedding  VECTOR(128)     : Vector facial para autenticación
    - p_huella_template   BYTEA           : Template de huella digital
    - p_url_foto_facial   VARCHAR(500)    : URL de la foto facial capturada
    - p_url_imagen_huella VARCHAR(500)    : URL de la imagen de huella
    - p_calidad_facial    NUMERIC(5,2)    : Calidad del vector facial (0-100)
    - p_calidad_huella    NUMERIC(5,2)    : Calidad del template de huella
    - p_ind_vehiculo      BOOLEAN         : ¿Ingresó con vehículo?
    - p_id_vehiculo       VARCHAR(6)      : Placa del vehículo
    - p_val_observaciones TEXT            : Observaciones adicionales
    - p_usr_insert        VARCHAR(50)     : Usuario que registra el ingreso

  Excepciones:
    - Si la persona tiene ingreso activo: RAISE EXCEPTION
    - Si no han pasado 5 minutos desde la última salida: RAISE EXCEPTION
    - Si la persona no existe: Se crea novedad (no se lanza excepción)

  Ejemplo de uso:
    CALL sp_registrar_ingreso(
        p_num_documento     => 123456789,
        p_nom_tercero       => 'Juan',
        p_ape_tercero       => 'Pérez',
        p_id_entrada_centro => 1,
        p_id_metodo_aut     => 2,
        p_ind_dispositivo   => TRUE,
        p_facial_embedding  => NULL,
        p_huella_template   => NULL,
        p_url_foto_facial   => 'https://...',
        p_url_imagen_huella => NULL,
        p_calidad_facial    => 85.5,
        p_calidad_huella    => NULL,
        p_ind_vehiculo      => FALSE,
        p_id_vehiculo       => 'AAA000',
        p_val_observaciones => 'Ingreso por puerta principal',
        p_usr_insert        => 'admin'
    );
*/
CREATE OR REPLACE PROCEDURE sp_registrar_ingreso(
    -- Datos básicos de la persona (siempre proporcionados)
    p_num_documento     DECIMAL(10,0),
    p_nom_tercero       VARCHAR(40),
    p_ape_tercero       VARCHAR(30),
    p_id_entrada_centro DECIMAL(1,0),
    -- Datos del ingreso
    p_id_metodo_aut     DECIMAL(2,0) DEFAULT 1,
    p_ind_dispositivo   BOOLEAN      DEFAULT FALSE,
    p_facial_embedding  VECTOR(128)  DEFAULT NULL,
    p_huella_template   BYTEA        DEFAULT NULL,
    p_url_foto_facial   VARCHAR(500) DEFAULT NULL,
    p_url_imagen_huella VARCHAR(500) DEFAULT NULL,
    p_calidad_facial    NUMERIC(5,2) DEFAULT NULL,
    p_calidad_huella    NUMERIC(5,2) DEFAULT NULL,
    p_ind_vehiculo      BOOLEAN      DEFAULT FALSE,
    p_id_vehiculo       VARCHAR(6)   DEFAULT 'AAA000',
    p_val_observaciones TEXT         DEFAULT NULL,
    -- Auditoría
    p_usr_insert        VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_persona        DECIMAL(10,0);
    v_activo_existe     BOOLEAN;
    v_ultima_salida     TIMESTAMP;
    v_diff_min          NUMERIC;
    v_fec_ingreso       TIMESTAMP := CURRENT_TIMESTAMP;
    v_nuevo_id_ingreso  INTEGER;
BEGIN
    -- 1. Verificar si la persona existe en tab_personas (bloqueo para concurrencia)
    SELECT id_persona INTO v_id_persona
    FROM tab_personas
    WHERE id_persona = p_num_documento
    FOR UPDATE;

    IF v_id_persona IS NULL THEN
        -- La persona NO existe → registrar intento en tab_novedades_ingreso
        INSERT INTO tab_novedades_ingreso (
            num_documento, nom_tercero, ape_tercero, id_entrada_centro,
            val_huella_digital, val_patron_facial, url_imagen_huella, url_foto_facial,
            fec_ingreso, fec_salida, usr_insert, fec_insert
        ) VALUES (
            p_num_documento,
            p_nom_tercero,
            p_ape_tercero,
            p_id_entrada_centro,
            p_huella_template,     -- val_huella_digital
            p_facial_embedding,    -- val_patron_facial
            p_url_imagen_huella,
            p_url_foto_facial,
            v_fec_ingreso,
            v_fec_ingreso,
            p_usr_insert,
            v_fec_ingreso
        );
        RAISE NOTICE 'La persona con documento % no está registrada. Se ha creado una novedad en tab_novedades_ingreso.', p_num_documento;
        RETURN;
    END IF;

    -- 2. Verificar si la persona tiene un ingreso activo (sin salida)
    SELECT EXISTS (
        SELECT 1 FROM tab_log_ingresos
        WHERE id_visitante = v_id_persona
          AND fec_salida = fec_ingreso
    ) INTO v_activo_existe;

    IF v_activo_existe THEN
        RAISE EXCEPTION 'La persona con documento % ya tiene un ingreso activo. Debe registrar su salida primero.', p_num_documento;
    END IF;

    -- 3. Obtener la última salida registrada (si existe)
    SELECT fec_salida INTO v_ultima_salida
    FROM tab_log_ingresos
    WHERE id_visitante = v_id_persona
      AND fec_salida > fec_ingreso
    ORDER BY fec_salida DESC
    LIMIT 1;

    -- 4. Validar diferencia de 5 minutos desde la última salida
    IF v_ultima_salida IS NOT NULL THEN
        v_diff_min := fn_diferencia_minutos(v_fec_ingreso, v_ultima_salida);
        IF v_diff_min < 5 THEN
            RAISE EXCEPTION 'Deben pasar al menos 5 minutos desde la última salida (%). Diferencia actual: % minutos.',
                            v_ultima_salida, v_diff_min;
        END IF;
    END IF;

    -- 5. Insertar el nuevo ingreso
    INSERT INTO tab_log_ingresos (
        id_visitante, fec_ingreso, fec_salida, id_metodo_aut, id_entrada_centro,
        ind_dispositivo, facial_embedding, huella_template, url_foto_facial, url_imagen_huella,
        calidad_facial, calidad_huella, ind_vehiculo, id_vehiculo, val_observaciones,
        usr_insert, fec_insert
    ) VALUES (
        v_id_persona,
        v_fec_ingreso,
        v_fec_ingreso,  -- inicialmente igual a fec_ingreso (activo)
        p_id_metodo_aut,
        p_id_entrada_centro,
        p_ind_dispositivo,
        p_facial_embedding,
        p_huella_template,
        p_url_foto_facial,
        p_url_imagen_huella,
        p_calidad_facial,
        p_calidad_huella,
        p_ind_vehiculo,
        p_id_vehiculo,
        p_val_observaciones,
        p_usr_insert,
        v_fec_ingreso
    )
    RETURNING id_ingreso INTO v_nuevo_id_ingreso;

    -- 6. Actualizar fec_ultima_entrada y contador de visitas en tab_personas
    UPDATE tab_personas
    SET fec_ultima_entrada = v_fec_ingreso,
        num_visitas = num_visitas + 1,
        usr_update = p_usr_insert,
        fec_update = v_fec_ingreso
    WHERE id_persona = v_id_persona;

    RAISE NOTICE 'Ingreso registrado exitosamente para la persona %. ID_ingreso: %', p_num_documento, v_nuevo_id_ingreso;
END;
$$;

COMMENT ON PROCEDURE sp_registrar_ingreso IS
    'Registra un nuevo ingreso de una persona.
     - Si la persona no existe en tab_personas, se crea una novedad en tab_novedades_ingreso con los datos proporcionados y se finaliza.
     - Si existe, valida que no tenga ingreso activo y que hayan pasado al menos 5 minutos desde su última salida.
     - Inserta en tab_log_ingresos y actualiza fec_ultima_entrada y num_visitas en tab_personas.
     - Usa FOR UPDATE para manejo de concurrencia.';

-- =============================================================================
-- 4. PROCEDIMIENTO: sp_registrar_salida
-- =============================================================================
/*
  sp_registrar_salida
  ===================
  Propósito:
    Registra la salida de una persona a partir del ID de ingreso.
    - Verifica que el ingreso esté activo (sin salida previa).
    - Exige que hayan pasado al menos 5 minutos desde el ingreso.
    - Actualiza fec_salida en tab_log_ingresos y fec_ultima_salida en tab_personas.
    - Usa FOR UPDATE para manejo de concurrencia.

  Parámetros:
    - p_id_ingreso  INTEGER      : ID del ingreso a cerrar
    - p_usr_update  VARCHAR(50)  : Usuario que registra la salida

  Excepciones:
    - Si el ID de ingreso no existe: RAISE EXCEPTION
    - Si el ingreso ya tiene salida: RAISE EXCEPTION
    - Si no han pasado 5 minutos desde el ingreso: RAISE EXCEPTION

  Ejemplo de uso:
    CALL sp_registrar_salida(
        p_id_ingreso => 1,
        p_usr_update => 'admin'
    );
*/
CREATE OR REPLACE PROCEDURE sp_registrar_salida(
    p_id_ingreso        INTEGER,
    p_usr_update        VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_persona        DECIMAL(10,0);
    v_fec_ingreso       TIMESTAMP;
    v_fec_salida_actual TIMESTAMP;
    v_diff_min          NUMERIC;
    v_nueva_salida      TIMESTAMP := CURRENT_TIMESTAMP;
BEGIN
    -- 1. Bloquear el registro de ingreso para actualización (concurrencia)
    SELECT id_visitante, fec_ingreso, fec_salida
    INTO v_id_persona, v_fec_ingreso, v_fec_salida_actual
    FROM tab_log_ingresos
    WHERE id_ingreso = p_id_ingreso
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe un ingreso con ID %', p_id_ingreso;
    END IF;

    -- 2. Verificar que el ingreso esté activo (sin salida registrada)
    IF v_fec_salida_actual <> v_fec_ingreso THEN
        RAISE EXCEPTION 'El ingreso con ID % ya tiene una salida registrada (%). No se puede modificar.', 
                        p_id_ingreso, v_fec_salida_actual;
    END IF;

    -- 3. Validar que hayan pasado al menos 5 minutos desde el ingreso
    v_diff_min := fn_diferencia_minutos(v_nueva_salida, v_fec_ingreso);
    IF v_diff_min < 5 THEN
        RAISE EXCEPTION 'La salida debe registrarse al menos 5 minutos después del ingreso (%). Diferencia actual: % minutos.',
                        v_fec_ingreso, v_diff_min;
    END IF;

    -- 4. Actualizar fec_salida en tab_log_ingresos
    UPDATE tab_log_ingresos
    SET fec_salida = v_nueva_salida,
        usr_update = p_usr_update,
        fec_update = v_nueva_salida
    WHERE id_ingreso = p_id_ingreso;

    -- 5. Actualizar fec_ultima_salida en tab_personas
    UPDATE tab_personas
    SET fec_ultima_salida = v_nueva_salida,
        usr_update = p_usr_update,
        fec_update = v_nueva_salida
    WHERE id_persona = v_id_persona;

    RAISE NOTICE 'Salida registrada exitosamente para el ingreso ID % a las %', p_id_ingreso, v_nueva_salida;
END;
$$;

COMMENT ON PROCEDURE sp_registrar_salida IS
    'Registra la salida de una persona a partir del ID de ingreso.
     - Verifica que el ingreso esté activo (sin salida previa).
     - Exige que hayan pasado al menos 5 minutos desde el ingreso.
     - Actualiza fec_salida en tab_log_ingresos y fec_ultima_salida en tab_personas.
     - Usa FOR UPDATE para manejo de concurrencia.';

-- =============================================================================
-- 5. TRIGGERS DE SEGURIDAD (para DML directo)
-- =============================================================================

-- 5.1. Trigger para INSERT en tab_log_ingresos
/*
  fn_trg_validar_ingreso_directo
  ==============================
  Propósito:
    Trigger de seguridad que impide INSERTS directos en tab_log_ingresos
    que violen las reglas de negocio:
      - La persona debe existir en tab_personas
      - No debe tener un ingreso activo
      - Deben haber pasado 5 minutos desde la última salida

  Usado en:
    BEFORE INSERT ON tab_log_ingresos
*/
CREATE OR REPLACE FUNCTION fn_trg_validar_ingreso_directo()
RETURNS TRIGGER AS $$
DECLARE
    v_existe_persona BOOLEAN;
    v_activo         BOOLEAN;
    v_ult_salida     TIMESTAMP;
    v_diff           NUMERIC;
BEGIN
    -- 1. Validar existencia en tab_personas
    SELECT EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = NEW.id_visitante)
    INTO v_existe_persona;

    IF NOT v_existe_persona THEN
        RAISE EXCEPTION 'La persona con ID % no existe en tab_personas. Use sp_registrar_ingreso.', NEW.id_visitante;
    END IF;

    -- 2. Validar que no tenga ingreso activo (excluyendo el propio registro en caso de UPDATE)
    SELECT EXISTS (
        SELECT 1 FROM tab_log_ingresos
        WHERE id_visitante = NEW.id_visitante
          AND fec_salida = fec_ingreso
          AND id_ingreso <> COALESCE(NEW.id_ingreso, -1)
    ) INTO v_activo;

    IF v_activo THEN
        RAISE EXCEPTION 'La persona ya tiene un ingreso activo.';
    END IF;

    -- 3. Validar diferencia de 5 minutos desde última salida (si existe)
    SELECT fec_salida INTO v_ult_salida
    FROM tab_log_ingresos
    WHERE id_visitante = NEW.id_visitante
      AND fec_salida > fec_ingreso
    ORDER BY fec_salida DESC
    LIMIT 1;

    IF v_ult_salida IS NOT NULL THEN
        v_diff := fn_diferencia_minutos(NEW.fec_ingreso, v_ult_salida);
        IF v_diff < 5 THEN
            RAISE EXCEPTION 'Deben pasar 5 minutos desde la última salida (%). Diferencia: % min.', v_ult_salida, v_diff;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_ingreso_directo ON tab_log_ingresos;
CREATE TRIGGER trg_validar_ingreso_directo
BEFORE INSERT ON tab_log_ingresos
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validar_ingreso_directo();

COMMENT ON TRIGGER trg_validar_ingreso_directo ON tab_log_ingresos IS
    'Trigger de seguridad que impide INSERTS directos que violen las reglas de ingreso.';

-- 5.2. Trigger para UPDATE de fec_salida
/*
  fn_trg_validar_salida_directa
  =============================
  Propósito:
    Trigger de seguridad que impide actualizaciones directas de fec_salida
    en tab_log_ingresos que violen las reglas:
      - El ingreso debe estar activo (sin salida previa)
      - Deben haber pasado 5 minutos desde el ingreso

  Usado en:
    BEFORE UPDATE OF fec_salida ON tab_log_ingresos
*/
CREATE OR REPLACE FUNCTION fn_trg_validar_salida_directa()
RETURNS TRIGGER AS $$
DECLARE
    v_diff NUMERIC;
BEGIN
    -- Solo validar si se está modificando fec_salida
    IF NEW.fec_salida IS DISTINCT FROM OLD.fec_salida THEN
        -- Verificar que el registro esté activo
        IF OLD.fec_salida <> OLD.fec_ingreso THEN
            RAISE EXCEPTION 'El ingreso ID % ya tiene salida registrada (%).', OLD.id_ingreso, OLD.fec_salida;
        END IF;

        -- Calcular diferencia
        v_diff := fn_diferencia_minutos(NEW.fec_salida, OLD.fec_ingreso);
        IF v_diff < 5 THEN
            RAISE EXCEPTION 'La salida debe ser al menos 5 minutos después del ingreso (%). Diferencia: % min.', 
                            OLD.fec_ingreso, v_diff;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_salida_directa ON tab_log_ingresos;
CREATE TRIGGER trg_validar_salida_directa
BEFORE UPDATE OF fec_salida ON tab_log_ingresos
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validar_salida_directa();

COMMENT ON TRIGGER trg_validar_salida_directa ON tab_log_ingresos IS
    'Trigger de seguridad que impide actualizaciones directas de fec_salida que violen las reglas.';

-- =============================================================================
-- 6. PRUEBAS DE VALIDACIÓN (ejemplos comentados)
-- =============================================================================
/*
-- Registrar un ingreso (persona existente)
CALL sp_registrar_ingreso(
    p_num_documento     => 123456789,
    p_nom_tercero       => 'Juan',
    p_ape_tercero       => 'Pérez',
    p_id_entrada_centro => 1,
    p_id_metodo_aut     => 2,
    p_ind_dispositivo   => TRUE,
    p_facial_embedding  => NULL,
    p_huella_template   => NULL,
    p_url_foto_facial   => 'https://...',
    p_url_imagen_huella => NULL,
    p_calidad_facial    => 85.5,
    p_calidad_huella    => NULL,
    p_ind_vehiculo      => FALSE,
    p_id_vehiculo       => 'AAA000',
    p_val_observaciones => 'Ingreso por puerta principal',
    p_usr_insert        => 'admin'
);

-- Registrar una salida (con ID de ingreso)
CALL sp_registrar_salida(
    p_id_ingreso => 1,
    p_usr_update => 'admin'
);

-- Si la persona no existe en tab_personas, se crea una novedad con los datos proporcionados.
CALL sp_registrar_ingreso(
    p_num_documento     => 987654321,
    p_nom_tercero       => 'María',
    p_ape_tercero       => 'González',
    p_id_entrada_centro => 1,
    p_usr_insert        => 'admin'
);
-- NOTICE: La persona con documento 987654321 no está registrada. Se ha creado una novedad en tab_novedades_ingreso.
*/

-- =============================================================================
-- NOTAS ADICIONALES PARA EL ADMINISTRADOR:
-- =============================================================================
-- 1. Los procedimientos sp_registrar_ingreso y sp_registrar_salida son la
--    interfaz recomendada para interactuar con el sistema de control de acceso.
--
-- 2. Los triggers de seguridad previenen operaciones DML directas que puedan
--    violar la integridad de los datos. Siempre use los procedimientos.
--
-- 3. Los índices están diseñados para optimizar las consultas más frecuentes:
--    - Búsqueda de ingresos activos
--    - Historial de ingresos por persona
--    - Última salida registrada
--    - Búsqueda en novedades por documento
--
-- 4. La función fn_diferencia_minutos es inmutable (IMMUTABLE), lo que permite
--    su uso en índices y optimizaciones.
--
-- 5. El manejo de concurrencia con FOR UPDATE previene condiciones de carrera
--    cuando múltiples procesos intentan registrar ingresos/salidas simultáneamente.
--
-- 6. Para ejecutar las pruebas, descomentar los CALLs y ajustar los valores
--    según los datos reales del entorno.
--
-- =============================================================================
-- HISTORIAL DE VERSIONES
-- =============================================================================
-- Versión | Fecha       | Descripción de cambios
-- --------|-------------|--------------------------------------------------------
-- 1.0     | 2026-07-17  | Versión inicial. Implementación de procedimientos,
--         |             | triggers de seguridad, índices estratégicos y
--         |             | documentación completa.
-- =============================================================================