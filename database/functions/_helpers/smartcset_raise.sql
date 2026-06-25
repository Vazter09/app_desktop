-- ===================================================================
-- Módulo: _helpers / smartcset_raise
-- Descripción: Helpers de excepciones para funciones SmartCSET.
--              Desplegar antes que el resto de database/functions/.
-- Nota: ERRCODE P0001 — mensaje visible en PHP vía ErrorHandler.
-- ===================================================================

DROP FUNCTION IF EXISTS smartcset_raise_validacion(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS smartcset_raise_negocio(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS smartcset_raise_no_encontrado(TEXT, TEXT);
DROP FUNCTION IF EXISTS smartcset_handle_sql_error(TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS smartcset_handle_sql_error();
DROP FUNCTION IF EXISTS smartcset_raise_core(TEXT, TEXT, TEXT);

-- -------------------------------------------------------------------
-- Función: smartcset_raise_core
-- Descripción: Lanza excepción de negocio/validación (P0001).
-- Parámetros:
--   wmensaje: Texto mostrado al usuario.
--   wdetalle: Detalle técnico opcional (PG EXCEPTION DETAIL).
--   whint:    Sugerencia opcional (PG EXCEPTION HINT).
-- Retorna: VOID
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION smartcset_raise_core(
    wmensaje TEXT,
    wdetalle TEXT DEFAULT NULL,
    whint    TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    RAISE EXCEPTION '%', wmensaje
        USING ERRCODE = 'P0001',
              DETAIL = COALESCE(wdetalle, ''),
              HINT = COALESCE(whint, '');
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------------
-- Función: smartcset_raise_validacion
-- Descripción: Datos inválidos, faltantes o referencia incorrecta.
-- Retorna: VOID
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION smartcset_raise_validacion(
    wmensaje TEXT,
    wdetalle TEXT DEFAULT NULL,
    whint    TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    PERFORM smartcset_raise_core(wmensaje, wdetalle, whint);
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------------
-- Función: smartcset_raise_negocio
-- Descripción: Regla de negocio no cumplida (ingreso activo, menú con hijos, etc.).
-- Retorna: VOID
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION smartcset_raise_negocio(
    wmensaje TEXT,
    wdetalle TEXT DEFAULT NULL,
    whint    TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    PERFORM smartcset_raise_core(wmensaje, wdetalle, whint);
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------------
-- Función: smartcset_raise_no_encontrado
-- Descripción: Registro o catálogo inexistente.
-- Retorna: VOID
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION smartcset_raise_no_encontrado(
    wmensaje TEXT,
    wdetalle TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    PERFORM smartcset_raise_core(
        wmensaje,
        wdetalle,
        'Verifique el identificador e intente de nuevo.'
    );
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------------
-- Función: smartcset_handle_sql_error
-- Descripción: Traduce SQLSTATE PostgreSQL a mensajes en español.
--              Re-lanza P0001 sin modificar. Usar en EXCEPTION ... OTHERS.
-- Retorna: VOID
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION smartcset_handle_sql_error(
    p_state  TEXT DEFAULT NULL,
    p_msg    TEXT DEFAULT NULL,
    p_detail TEXT DEFAULT NULL,
    p_hint   TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_state  TEXT;
    v_msg    TEXT;
    v_detail TEXT;
    v_hint   TEXT;
BEGIN
    -- GET STACKED DIAGNOSTICS solo es válido en el bloque EXCEPTION del mismo
    -- subprograma; al llamar esta función vía PERFORM hay que pasar los valores.
    IF p_state IS NULL THEN
        PERFORM smartcset_raise_negocio(
            'No se pudo completar la operación en base de datos.',
            COALESCE(p_msg, NULL),
            'Si persiste, contacte al administrador.'
        );
        RETURN;
    END IF;

    v_state  := p_state;
    v_msg    := COALESCE(p_msg, '');
    v_detail := COALESCE(p_detail, '');
    v_hint   := COALESCE(p_hint, '');

    IF v_state = 'P0001' THEN
        RAISE EXCEPTION '%', v_msg
            USING ERRCODE = v_state,
                  DETAIL = COALESCE(v_detail, ''),
                  HINT = COALESCE(v_hint, '');
    END IF;

    CASE v_state
        WHEN '23505' THEN
            PERFORM smartcset_raise_negocio(
                'El registro ya existe o hay un conflicto con datos activos.',
                v_detail,
                'Revise duplicados o cierre visitas/ingresos abiertos.'
            );
        WHEN '23503' THEN
            PERFORM smartcset_raise_validacion(
                'No se puede completar la operación: referencia inválida o dato en uso.',
                v_detail,
                'Verifique catálogos, usuarios y menús relacionados.'
            );
        WHEN '23502' THEN
            PERFORM smartcset_raise_validacion(
                'Faltan datos obligatorios.',
                v_detail,
                'Complete todos los campos requeridos.'
            );
        WHEN '23514' THEN
            PERFORM smartcset_raise_validacion(
                'Los datos no cumplen las reglas del sistema.',
                v_detail,
                'Revise longitudes, formatos y valores permitidos.'
            );
        WHEN '22001' THEN
            PERFORM smartcset_raise_validacion(
                'Uno de los valores es demasiado largo.',
                v_detail,
                NULL
            );
        WHEN '22P02' THEN
            PERFORM smartcset_raise_validacion(
                'Formato de dato inválido.',
                v_detail,
                NULL
            );
        ELSE
            PERFORM smartcset_raise_negocio(
                'No se pudo completar la operación en base de datos.',
                v_msg,
                'Si persiste, contacte al administrador.'
            );
    END CASE;
END;
$$ LANGUAGE plpgsql;
