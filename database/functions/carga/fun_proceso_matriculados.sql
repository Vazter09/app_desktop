-- Ejecutar la función.
-- SELECT fun_procesar_aprendices();

CREATE OR REPLACE FUNCTION fun_procesar_aprendices()
RETURNS TEXT AS $$
DECLARE
    rec RECORD;
    v_id_persona DECIMAL(10,0);
    v_nom_persona VARCHAR(40);
    v_ape_persona VARCHAR(30);
    v_mail_persona VARCHAR;
    v_tel_movil DECIMAL(10,0);
    v_id_ficha_actual DECIMAL(10,0);
    v_usr_insert VARCHAR(50) := 'SISTEMA';
    v_fec_insert TIMESTAMP := CURRENT_TIMESTAMP;
    v_fila_temp RECORD;
    
    -- Variables de estadísticas
    v_total INT := 0;
    v_insertados INT := 0;
    v_actualizados INT := 0;
    v_errores INT := 0;
    v_contador_actualizados_personas INT := 0; -- Para contar actualizaciones en personas
BEGIN
    -- Recorrer cada persona distinta (identificada por tipo y número de documento)
    FOR rec IN (
        SELECT DISTINCT id_tipodoc, num_documento
        FROM tab_temp_aprendices
    ) LOOP
        v_total := v_total + 1;
        BEGIN
            -- Obtener el registro más reciente (por fecha_reporte) para esta persona
            SELECT id_tipodoc, num_documento, nom_aprendiz, ape_aprendiz, val_correo, nom_movil, fecha_reporte
            INTO v_fila_temp
            FROM tab_temp_aprendices
            WHERE id_tipodoc = rec.id_tipodoc AND num_documento = rec.num_documento
            ORDER BY fecha_reporte DESC
            LIMIT 1;

            -- Asignar variables
            v_id_persona := v_fila_temp.num_documento::DECIMAL(10,0);
            v_nom_persona := v_fila_temp.nom_aprendiz;
            v_ape_persona := v_fila_temp.ape_aprendiz;
            v_mail_persona := v_fila_temp.val_correo;

            -- Obtener y validar teléfono móvil (nunca debe quedar NULL)
            BEGIN
                -- Primero, intentar convertir y usar COALESCE para NULL
                v_tel_movil := COALESCE(v_fila_temp.nom_movil::DECIMAL(10,0), 3000000000);
                -- Validar rango
                IF v_tel_movil NOT BETWEEN 3000000000 AND 3519999999 THEN
                    v_tel_movil := 3000000000;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                -- Si el CAST falla (formato inválido), usar el default
                v_tel_movil := 3000000000;
            END;

            -- 1. Insertar o actualizar tab_personas
            IF EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = v_id_persona) THEN
                -- Actualizar solo si hay cambios (incluyendo teléfono)
                UPDATE tab_personas
                SET nom_persona = v_nom_persona,
                    ape_persona = v_ape_persona,
                    mail_persona = COALESCE(v_mail_persona, 'sin_correo@correo.com'),
                    tel_persona_movil = v_tel_movil,
                    usr_update = v_usr_insert,
                    fec_update = v_fec_insert
                WHERE id_persona = v_id_persona
                  AND (nom_persona IS DISTINCT FROM v_nom_persona
                       OR ape_persona IS DISTINCT FROM v_ape_persona
                       OR mail_persona IS DISTINCT FROM COALESCE(v_mail_persona, 'sin_correo@correo.com')
                       OR tel_persona_movil IS DISTINCT FROM v_tel_movil);
                
                IF FOUND THEN
                    v_actualizados := v_actualizados + 1;
                    v_contador_actualizados_personas := v_contador_actualizados_personas + 1;
                END IF;
            ELSE
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
                    1,
                    v_nom_persona,
                    v_ape_persona,
                    COALESCE(v_mail_persona, 'sin_correo@correo.com'),
                    '1900-01-01'::DATE,
                    99,
                    NULL,
                    NULL,
                    CURRENT_TIMESTAMP,
                    CURRENT_TIMESTAMP,
                    0,
                    99,
                    '00',
                    '68',
                    '68001',
                    'Sin Dirección',
                    6010000000,
                    v_tel_movil,
                    'Sin Contacto',
                    3000000000,
                    FALSE,
                    TRUE,
                    v_usr_insert,
                    v_fec_insert,
                    NULL::VARCHAR,
                    NULL::TIMESTAMP
                );
                v_insertados := v_insertados + 1;
            END IF;

            -- 2. Determinar la ficha actual: priorizar estado '3' y luego la más reciente
            SELECT id_ficha
            INTO v_id_ficha_actual
            FROM tab_temp_aprendices
            WHERE id_tipodoc = rec.id_tipodoc AND num_documento = rec.num_documento
              AND ind_estado_ficha = '3'
            ORDER BY fecha_reporte DESC
            LIMIT 1;

            IF v_id_ficha_actual IS NULL THEN
                SELECT id_ficha
                INTO v_id_ficha_actual
                FROM tab_temp_aprendices
                WHERE id_tipodoc = rec.id_tipodoc AND num_documento = rec.num_documento
                ORDER BY fecha_reporte DESC
                LIMIT 1;
            END IF;

            IF v_id_ficha_actual IS NULL THEN
                RAISE EXCEPTION 'No se encontró ninguna ficha para la persona %', v_id_persona;
            END IF;

            -- 3. Insertar o actualizar tab_aprendices
            IF EXISTS (SELECT 1 FROM tab_aprendices WHERE id_aprendiz = v_id_persona) THEN
                -- Actualizar id_ficha solo si cambia
                UPDATE tab_aprendices
                SET id_ficha = v_id_ficha_actual,
                    usr_update = v_usr_insert,
                    fec_update = v_fec_insert
                WHERE id_aprendiz = v_id_persona
                  AND id_ficha IS DISTINCT FROM v_id_ficha_actual;
                
                IF FOUND THEN
                    v_actualizados := v_actualizados + 1;
                END IF;
            ELSE
                INSERT INTO tab_aprendices (
                    id_aprendiz, datos_aprendiz, id_ficha, num_llamados,
                    usr_insert, fec_insert, usr_update, fec_update, ind_etdo_formacion
                ) VALUES (
                    v_id_persona,
                    NULL,
                    v_id_ficha_actual,
                    0,
                    v_usr_insert,
                    v_fec_insert,
                    NULL::VARCHAR,
                    NULL::TIMESTAMP,
                    8
                );
                v_insertados := v_insertados + 1;
            END IF;

            -- 4. Insertar histórico de todas las fichas distintas (sin duplicados)
            INSERT INTO tab_aprendices_fichas (
                id_ficha, id_aprendiz, id_jornada,
                usr_insert, fec_insert, usr_update, fec_update
            )
            SELECT DISTINCT
                t.id_ficha,
                v_id_persona,
                f.id_jornada,
                v_usr_insert,
                v_fec_insert,
                NULL::VARCHAR,
                NULL::TIMESTAMP
            FROM tab_temp_aprendices t
            JOIN tab_fichas f ON t.id_ficha = f.id_ficha
            WHERE t.id_tipodoc = rec.id_tipodoc AND t.num_documento = rec.num_documento
            ON CONFLICT (id_ficha, id_aprendiz) DO NOTHING;

        EXCEPTION WHEN OTHERS THEN
            v_errores := v_errores + 1;
            -- Puedes agregar un RAISE NOTICE si quieres ver el error específico
            RAISE NOTICE 'Error procesando persona %: %', v_id_persona, SQLERRM;
        END;
    END LOOP;

    -- Devolver el mensaje con estadísticas
    RETURN format('Procesados total: %s | Insertados: %s | Actualizados: %s | Errores: %s',
                  v_total, v_insertados, v_actualizados, v_errores);
END;
$$ LANGUAGE plpgsql;