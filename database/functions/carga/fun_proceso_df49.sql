/*
============================================================================================
  SCRIPT PARA ACTUALIZAR PROGRAMAS Y ESTADOS DE FICHAS DESDE DF49
============================================================================================
  OBJETIVO:
    Procesa los datos de la tabla temporal tab_temp_df49 para:
      - Insertar o actualizar programas en tab_programas (con su versión).
      - Insertar o actualizar programas especiales en tab_prog_especiales.
      - Actualizar el estado de las fichas en tab_fichas según el estado más reciente
        reportado en tab_temp_df49.

  DEPENDENCIAS:
    - Tablas destino: tab_programas, tab_prog_especiales, tab_fichas
    - Tabla origen: tab_temp_df49
    - Claves primarias: 
        - tab_programas(id_programa)
        - tab_prog_especiales(id_prog_especial)
        - tab_fichas(id_ficha)

  AUTOR:          Grupo SMARTCSET
  FECHA:          2026-07-17
  VERSIÓN:        1.0
============================================================================================
*/
CREATE OR REPLACE FUNCTION fun_procesar_df49()
RETURNS TABLE(
    insertados   BIGINT,
    actualizados BIGINT,
    errores      BIGINT
) AS $$
DECLARE
    -- Variables para datos de la fila actual
    v_id_ficha           tab_temp_df49.id_ficha%TYPE;
    v_id_programa        tab_temp_df49.id_programa%TYPE;
    v_nom_programa       tab_temp_df49.nom_programa%TYPE;
    v_id_version         tab_temp_df49.id_version%TYPE;
    v_ind_estado         tab_temp_df49.ind_estado%TYPE;
    v_id_prog_especial   tab_temp_df49.id_prog_especial%TYPE;
    v_nom_prog_especial  tab_temp_df49.nom_prog_especial%TYPE;
    v_num_version        tab_programas.num_version%TYPE;

    -- Contadores globales
    v_total_insertados   BIGINT := 0;
    v_total_actualizados BIGINT := 0;
    v_total_errores      BIGINT := 0;

    -- Variables auxiliares
    v_filas              BIGINT;
BEGIN
    /*
     ====================================================================
      BLOQUE PRINCIPAL: Recorrido de fichas distintas (más reciente)
     ====================================================================
      Se obtienen fichas distintas por id_ficha, tomando el registro con
      la fecha_reporte más reciente para tener el estado actualizado.
     */
    FOR v_id_ficha, v_id_programa, v_nom_programa, v_id_version, v_ind_estado, v_id_prog_especial, v_nom_prog_especial IN
        SELECT DISTINCT ON (id_ficha) 
            id_ficha,
            id_programa,
            nom_programa,
            id_version,
            ind_estado,
            id_prog_especial,
            nom_prog_especial
        FROM tab_temp_df49
        ORDER BY id_ficha, fecha_reporte DESC
    LOOP
        BEGIN
            -- -----------------------------------------------------------------
            -- 1. CALCULAR VERSIÓN DEL PROGRAMA
            -- -----------------------------------------------------------------
            -- Si la versión es mayor a 99, se asigna 1 (valor por defecto)
            v_num_version := CASE WHEN v_id_version > 99 THEN 1 ELSE v_id_version END;

            -- -----------------------------------------------------------------
            -- 2. INSERTAR O ACTUALIZAR EN tab_programas
            -- -----------------------------------------------------------------
            -- 2a. Intentar insertar el programa (si no existe)
            INSERT INTO tab_programas (id_programa, nom_programa, num_version)
            VALUES (v_id_programa, v_nom_programa, v_num_version)
            ON CONFLICT (id_programa) DO NOTHING;
            GET DIAGNOSTICS v_filas = ROW_COUNT;
            v_total_insertados := v_total_insertados + v_filas;

            -- 2b. Actualizar el programa si cambió nombre o versión
            UPDATE tab_programas
            SET nom_programa = v_nom_programa,
                num_version  = v_num_version
            WHERE id_programa = v_id_programa
              AND (nom_programa IS DISTINCT FROM v_nom_programa
                   OR num_version IS DISTINCT FROM v_num_version);
            GET DIAGNOSTICS v_filas = ROW_COUNT;
            v_total_actualizados := v_total_actualizados + v_filas;

            -- -----------------------------------------------------------------
            -- 3. INSERTAR O ACTUALIZAR EN tab_prog_especialES (si id es válido)
            -- -----------------------------------------------------------------
            -- Solo se procesa si el id_prog_especial es mayor que 0
            IF v_id_prog_especial IS NOT NULL AND v_id_prog_especial > 0 THEN
                -- 3a. Insertar programa especial (si no existe)
                INSERT INTO tab_prog_especiales (id_prog_especial, nom_prog_especial)
                VALUES (v_id_prog_especial, v_nom_prog_especial)
                ON CONFLICT (id_prog_especial) DO NOTHING;
                GET DIAGNOSTICS v_filas = ROW_COUNT;
                v_total_insertados := v_total_insertados + v_filas;

                -- 3b. Actualizar nombre del programa especial si cambió
                UPDATE tab_prog_especiales
                SET nom_prog_especial = v_nom_prog_especial
                WHERE id_prog_especial = v_id_prog_especial
                  AND nom_prog_especial IS DISTINCT FROM v_nom_prog_especial;
                GET DIAGNOSTICS v_filas = ROW_COUNT;
                v_total_actualizados := v_total_actualizados + v_filas;
            END IF;

            -- -----------------------------------------------------------------
            -- 4. ACTUALIZAR ESTADO DE LA FICHA EN tab_fichas
            -- -----------------------------------------------------------------
            -- Se convierte el estado en texto a código numérico según lógica
            UPDATE tab_fichas
            SET ind_estado = 
                CASE UPPER(TRIM(v_ind_estado))
                    WHEN 'INSCRIPCION' THEN 1
                    WHEN 'MATRICULA'   THEN 2
                    WHEN 'EJECUCION'   THEN 3
                    WHEN 'TERMINADA'   THEN 7
                    WHEN 'CERRADA'     THEN 8
                    ELSE 9
                END
            WHERE id_ficha = v_id_ficha;

            GET DIAGNOSTICS v_filas = ROW_COUNT;
            v_total_actualizados := v_total_actualizados + v_filas;

            -- Si no se actualizó ninguna fila, la ficha no existe en tab_fichas
            IF v_filas = 0 THEN
                v_total_errores := v_total_errores + 1;
                RAISE WARNING 'Ficha % no encontrada en tab_fichas', v_id_ficha;
            END IF;

        -- -----------------------------------------------------------------
        -- CAPTURA DE ERRORES POR FICHA
        -- -----------------------------------------------------------------
        EXCEPTION WHEN OTHERS THEN
            v_total_errores := v_total_errores + 1;
            RAISE WARNING 'Error al procesar ficha %: % (SQLSTATE %)', 
                          v_id_ficha, SQLERRM, SQLSTATE;
        END;
    END LOOP;

    -- Retornar resumen consolidado de todas las operaciones
    RETURN QUERY SELECT v_total_insertados, v_total_actualizados, v_total_errores;
END;
$$ LANGUAGE plpgsql;

-- ===========================================================================
-- NOTAS ADICIONALES PARA EL ADMINISTRADOR:
-- ===========================================================================
-- 1. Esta función procesa registros de la tabla temporal tab_temp_df49
--    y actualiza las tablas maestras de programas y programas especiales,
--    así como el estado de las fichas.
--
-- 2. La función es idempotente: puede ejecutarse varias veces sin generar
--    duplicados gracias a ON CONFLICT y a las actualizaciones condicionales.
--
-- 3. Los errores se registran como WARNING; revisar el log de PostgreSQL
--    después de cada ejecución para corregir datos problemáticos.
--
-- 4. Para ejecutar:
--      SELECT * FROM fun_procesar_df49();
--    Ejemplo de salida:
--      insertados | actualizados | errores
--     ------------+--------------+---------
--              15 |           42 |       2
--
-- 5. Si una ficha no existe en tab_fichas, se incrementa el contador de
--    errores y se emite una advertencia.
-- ===========================================================================
