--SELECT fun_proceso_pe04();
--SELECT * FROM tab_temp_pe04;
--SELECT * FROM tab_temp_df49;
--SELECT * FROM centro;
--SELECT * FROM programa;
--SELECT * FROM ficha;
CREATE OR REPLACE FUNCTION fun_proceso_pe04() RETURNS BOOLEAN AS
$BODY$
    DECLARE wcur_pe04 REFCURSOR;
    DECLARE wreg_pe04 RECORD;
    DECLARE wsql      TEXT;
    DECLARE wruta     TEXT;
    DECLARE wnumrows  INTEGER;
    BEGIN
-- CARGA DE LA TABLA DESDE EL DISCO
--        wruta := '/var/www/html/seguimi0.1/postgres';
--copy tab_temp_pe04 FROM '/var/www/html/seguimiento0.1/postgres/PE04_1.csv' DELIMITER '|';
--        wsql  := FORMAT('COPY tab_temp_pe04 FROM /var/www/html/seguimiento0.1/postgres/PE04_1.csv DELIMITER '|';');
--		RAISE NOTICE '%',wsql;
--		EXECUTE wsql;
--        GET DIAGNOSTICS wnumrows = ROW_COUNT;
--        RAISE NOTICE 'Carga exitosa: % filas insertadas en la tabla.', wnumrows;
--        RETURN wnumrows;
--        EXCEPTION
--            WHEN OTHERS THEN
-- Manejo de errores detallado
--                RAISE EXCEPTION 'Error al cargar el archivo: %. Sentencia ejecutada: %', SQLERRM,wsql;
--        EXECUTE 'COPY tab_temp_df49 FROM ''/var/www/html/seguimiento0.1/postgres/DF-49_1CEPR.csv'' DELIMITER ''|''';
-- FIN DE LA CARGA

        OPEN wcur_pe04 FOR SELECT a.cod_regional,a.nom_regional,a.cod_centro,a.nom_centro,a.id_ficha,a.id_unico_ficha,a.ind_estado_curso,
                                  a.id_nivel_forma,a.id_jornada,a.nom_jornada,a.ind_tipo_forma,a.fec_inicio_ficha,a.fec_fin_ficha,
                                  a.val_etapa_ficha,a.val_modalidad,a.nom_responsable,a.id_empresa,a.id_tipodoc_emp,a.nom_empresa,a.id_sector_prog,
                                  a.nom_sector_prog,a.id_ocupacion,a.nom_ocupacion,a.id_programa,a.id_version,a.nom_programa,a.id_pais,a.nom_pais,
                                  a.id_depto,a.nom_depto,a.id_municipio,a.nom_municipio,a.id_convenio,a.nom_convenio,a.ind_cobertura,
                                  a.id_prog_especial,a.nom_prog_especial,a.num_cursos,a.num_aprend_masc,a.num_aprend_fem,a.num_aprend_nobin,
                                  a.num_tot_aprend,a.val_hrs_planta,a.val_hrs_contrat,a.val_hrs_context,a.val_hrs_monitor,a.val_hrs_instemp,
                                  a.val_total_hrs,a.val_total_apr_act,a.val_duracion_prog,a.nom_nuevo_sector FROM tab_temp_pe04 a;
            FETCH wcur_pe04 INTO wreg_pe04;
            WHILE FOUND LOOP
                RAISE NOTICE 'Mire mijo, Estoy Procesando la Ficha %', wreg_pe04.id_ficha;
-- VALIDAR LAS ENTRADAS QUE VIENEN DEL FRONT, POR SI LAS DUDAS (NULIDAD, VALOR NEGATIVOS, ETC.)
	            PERFORM 1 FROM centro
	            WHERE cen_id =  wreg_pe04.cod_centro;
	            IF NOT FOUND THEN
                    INSERT INTO centro VALUES(wreg_pe04.cod_centro,wreg_pe04.nom_centro,wreg_pe04.id_programa,wreg_pe04.id_version,
                                              wreg_pe04.nom_programa);
                    IF NOT FOUND THEN
		                RAISE NOTICE 'Salió mal la cosa al insertar Centro %..', wreg_pe04.cod_centro;
                        RETURN FALSE;
                    END IF;
	            END IF;
	            PERFORM 1 FROM programa
	            WHERE pro_id =  wreg_pe04.id_programa;
	            IF NOT FOUND THEN
                    INSERT INTO programa VALUES(wreg_pe04.id_programa,wreg_pe04.nom_programa,wreg_pe04.id_version,'NA','NA','NA');
                    IF NOT FOUND THEN
		                RAISE NOTICE 'Salió mal la cosa al insertar Programa %', wreg_pe04.id_programa;
                        RETURN FALSE;
                    END IF;
                END IF;
	            PERFORM 1 FROM ficha
	            WHERE fic_id =  wreg_pe04.id_ficha;
	            IF NOT FOUND THEN
-- Jornada: 0:NA/1:Mañana/2:Tarde/3:Mixta/4:Noche
                    INSERT INTO ficha VALUES(wreg_pe04.id_ficha,wreg_pe04.ind_estado_curso,wreg_pe04.id_nivel_forma,wreg_pe04.id_jornada,
                                             wreg_pe04.ind_tipo_forma,wreg_pe04.fec_inicio_ficha,wreg_pe04.fec_fin_ficha,wreg_pe04.val_etapa_ficha,
                                             wreg_pe04.val_modalidad,wreg_pe04.nom_responsable,wreg_pe04.id_programa,wreg_pe04.ind_cobertura,
                                             wreg_pe04.num_tot_aprend,wreg_pe04.val_total_apr_act,30,'TIP_RTA',0,0,wreg_pe04.val_total_apr_act,0,0,
                                             0,0,0,0,0,0,0,'0',0,0,0,0,0,0,wreg_pe04.val_total_apr_act,0,wreg_pe04.cod_centro,
                                             wreg_pe04.id_prog_especial,0,0,0,'0');
                    IF FOUND THEN
                        RAISE NOTICE 'La Ficha % se insertó bien.. No es tab bruto como pensé',wreg_pe04.id_ficha;
                    ELSE
                        RAISE NOTICE 'problemas insertando la  Ficha %.. parece que Usted es muuuuy bruto',wreg_pe04.id_ficha;
                        RETURN FALSE;
                    END IF;
-- ACTUALIZAR SI EXISTE EL PROGRAMA
                ELSE
                    UPDATE ficha SET fic_id   = wreg_pe04.id_ficha,
                                     fic_est  = wreg_pe04.ind_estado_curso,
                                     fic_niv  = wreg_pe04.id_nivel_forma,
                                     fic_jor  = wreg_pe04.id_jornada,
                                     fic_tip  = wreg_pe04.ind_tipo_forma,
                                     fic_fin  = wreg_pe04.fec_inicio_ficha,
                                     fic_fte  = wreg_pe04.fec_fin_ficha,
                                     fic_eta  = wreg_pe04.val_etapa_ficha,
                                     fic_mod  = wreg_pe04.val_modalidad,
                                     fic_res  = wreg_pe04.nom_responsable,
                                     pro_id   = wreg_pe04.id_programa,
                                     fic_amp  = wreg_pe04.ind_cobertura,
                                     fic_tot  = wreg_pe04.num_tot_aprend,
                                     fic_act  = wreg_pe04.val_total_apr_act,
                                     fic_cup  = 30,
--                                     fic_tre  = 'TIP_RTA',
--                                     fic_tra  = 0,
--                                     fic_indu = 0,
                                     fic_form = wreg_pe04.val_total_apr_act,
--                                     fic_cond = 0,
--                                     fic_apla = 0,
--                                     fic_canc = 0,
--                                     fic_pcer = 0,
--                                     fic_cert = 0,
--                                     fic_tras = 0,
--                                     fic_otro = 0,
--                                     fic_rut  = 0,
--                                     fic_sru  = 0,
--                                     fic_pgr  = '0',
--                                     fic_sij  = 0,
--                                     fic_nap  = 0,
--                                     fic_ava  = 0,
--                                     fic_com  = 0,
--                                     fic_min  = 0,
--                                     fic_max  = 0,
                                     fic_apr  = wreg_pe04.val_total_apr_act,
--                                     eta_cal  = 0,
                                     cen_id   = wreg_pe04.cod_centro,
                                     pre_id   = wreg_pe04.id_prog_especial
--                                     rap_tot  = 0,
--                                     rap_50s  = 0,
--                                     rap_etp  = 0,
--                                     fic_bi   = '0')
                    WHERE fic_id = wreg_pe04.id_ficha;
                    IF FOUND THEN
                        RAISE NOTICE 'La Ficha % se actualizó bien.. No es tan bruto como pensé',wreg_pe04.id_ficha;
                    ELSE
                        RAISE NOTICE 'problemas actualizando la  Ficha %.. parece que Usted es muuuuy bruto',wreg_pe04.id_ficha;
                        RETURN FALSE;
                    END IF;
	            END IF;
--                RAISE NOTICE '% % % %',wreg_pe04.cod_regional,wreg_pe04.nom_regional,wreg_pe04.cod_centro,wreg_pe04.nom_centro;
                FETCH wcur_pe04 INTO wreg_pe04;
            END LOOP;
        CLOSE wcur_pe04;
        RETURN TRUE;
    END;
$BODY$
LANGUAGE PLPGSQL;