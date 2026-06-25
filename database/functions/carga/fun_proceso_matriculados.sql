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
    v_estado_aprendiz VARCHAR;
    v_estado_num DECIMAL(1,0);
    v_usr_insert VARCHAR(50) := 'SISTEMA';
    v_fec_insert TIMESTAMP := CURRENT_TIMESTAMP;
    v_total INT := 0;
    v_errores INT := 0;
BEGIN
    -- Recorrer cada persona distinta (identificada por tipo y número de documento)
    FOR rec IN (
        SELECT DISTINCT ON (id_tipodoc, num_documento)
            id_tipodoc,
            num_documento,
            nom_aprendiz,
            ape_aprendiz,
            val_correo,
            nom_movil,
            ind_estado_aprendiz,
            -- Obtener la ficha actual: prioridad estado '3', luego la más reciente
            (SELECT id_ficha
             FROM tab_temp_aprendices t2
             WHERE t2.id_tipodoc = t1.id_tipodoc AND t2.num_documento = t1.num_documento
             ORDER BY CASE WHEN t2.ind_estado_ficha = '3' THEN 0 ELSE 1 END, t2.fecha_reporte DESC
             LIMIT 1) AS id_ficha_actual
        FROM tab_temp_aprendices t1
        ORDER BY id_tipodoc, num_documento, fecha_reporte DESC
    ) LOOP
        v_total := v_total + 1;
        BEGIN
            -- Asignar variables
            v_id_persona := rec.num_documento::DECIMAL(10,0);
            v_nom_persona := rec.nom_aprendiz;
            v_ape_persona := rec.ape_aprendiz;
            v_mail_persona := rec.val_correo;
            v_estado_aprendiz := rec.ind_estado_aprendiz;
            v_id_ficha_actual := rec.id_ficha_actual;

            IF v_id_ficha_actual IS NULL THEN
                RAISE EXCEPTION 'No se encontró ficha para persona %', v_id_persona;
            END IF;

            -- Procesar teléfono móvil
            BEGIN
                v_tel_movil := COALESCE(rec.nom_movil::DECIMAL(10,0), 3000000000);
                IF v_tel_movil NOT BETWEEN 3000000000 AND 3519999999 THEN
                    v_tel_movil := 3000000000;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                v_tel_movil := 3000000000;
            END;

            -- Convertir estado del aprendiz (usando unaccent para normalizar tildes)
            v_estado_num := CASE
                WHEN unaccent(lower(v_estado_aprendiz)) = 'en formacion' THEN 1
                WHEN unaccent(lower(v_estado_aprendiz)) = 'aplazado' THEN 2
                WHEN unaccent(lower(v_estado_aprendiz)) = 'retiro voluntario' THEN 3
                WHEN unaccent(lower(v_estado_aprendiz)) = 'cancelado' THEN 4
                WHEN unaccent(lower(v_estado_aprendiz)) = 'condicionado' THEN 5
                WHEN unaccent(lower(v_estado_aprendiz)) = 'suspendido' THEN 6
                WHEN unaccent(lower(v_estado_aprendiz)) = 'desertado' THEN 7
                ELSE 8
            END;

            -- 1. Insertar o actualizar tab_personas usando ON CONFLICT
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
                2,
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
            )
            ON CONFLICT (id_persona) DO UPDATE SET
                nom_persona = EXCLUDED.nom_persona,
                ape_persona = EXCLUDED.ape_persona,
                mail_persona = EXCLUDED.mail_persona,
                tel_persona_movil = EXCLUDED.tel_persona_movil,
                usr_update = v_usr_insert,
                fec_update = v_fec_insert;

            -- 2. Insertar o actualizar tab_aprendices usando ON CONFLICT
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
                NULL::VARCHAR,
                NULL::TIMESTAMP
            )
            ON CONFLICT (id_aprendiz) DO UPDATE SET
                id_ficha = EXCLUDED.id_ficha,
                ind_etdo_formacion = EXCLUDED.ind_etdo_formacion,
                usr_update = v_usr_insert,
                fec_update = v_fec_insert;

            -- 3. Insertar histórico de todas las fichas distintas (sin duplicados)
            INSERT INTO tab_aprendices_fichas (id_ficha, id_aprendiz, id_jornada, usr_insert, fec_insert)
            SELECT DISTINCT
                t.id_ficha,
                v_id_persona,
                f.id_jornada,
                v_usr_insert,
                v_fec_insert
            FROM tab_temp_aprendices t
            JOIN tab_fichas f ON t.id_ficha = f.id_ficha
            WHERE t.id_tipodoc = rec.id_tipodoc AND t.num_documento = rec.num_documento
            ON CONFLICT (id_ficha, id_aprendiz) DO NOTHING;

        EXCEPTION WHEN OTHERS THEN
            v_errores := v_errores + 1;
            RAISE WARNING 'Error en persona %: % (SQLSTATE %)', v_id_persona, SQLERRM, SQLSTATE;
        END;
    END LOOP;

    -- Retorno similar a fun_procesar_pe04
    RETURN format('Procesados total: %s | Errores: %s', v_total, v_errores);
END;
$$ LANGUAGE plpgsql;