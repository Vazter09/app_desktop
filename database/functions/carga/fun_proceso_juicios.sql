--SELECT fun_proceso_raps();
CREATE OR REPLACE FUNCTION fun_proceso_juicios() RETURNS BOOLEAN AS
$BODY$
    DECLARE wcur_raps       REFCURSOR;
    DECLARE wreg_raps       RECORD;
    DECLARE wsql            TEXT;
    DECLARE wruta           TEXT;
    DECLARE wnumrows        INTEGER;
    DECLARE wid_regional    DECIMAL(4,0);
    DECLARE wid_programa    tab_programas.id_programa%TYPE;
    DECLARE wid_ficha       tab_fichas.id_ficha%TYPE;
    DECLARE wid_centro      tab_centros.id_centro%TYPE;
    DECLARE wid_instructor  tab_instructores.id_instructor%TYPE;
    DECLARE wid_aprendiz    tab_aprendices.id_aprendiz%TYPE;
    DECLARE wid_compet      tab_competencias.id_compet%TYPE;
    DECLARE wid_rap         tab_raps.id_rap%TYPE;
    DECLARE wtot_aprend     DECIMAL(2,0);
    DECLARE wtot_aprend_act DECIMAL(2,0);
    DECLARE wind_estado     tab_fichas.ind_estado%TYPE;
    BEGIN
-- CARGA DE LA TABLA DESDE EL DISCO
--        wruta := '/var/www/html/seguimi0.1/postgres';
--copy tab_temp_pe04 FROM '/var/www/html/seguimiento0.1/postgres/PE04_1.csv' DELIMITER '|';
--        wsql  := FORMAT('COPY tab_temp_raps FROM /var/www/html/seguimiento0.1/postgres/Reporte_Raps.csv DELIMITER '|';');
--		RAISE NOTICE '%',wsql;
--		EXECUTE wsql;
--        GET DIAGNOSTICS wnumrows = ROW_COUNT;
--        RAISE NOTICE 'Carga exitosa: % filas insertadas en la tabla.', wnumrows;
--        RETURN wnumrows;
--        EXCEPTION
--            WHEN OTHERS THEN
-- Manejo de errores detallado
--                RAISE EXCEPTION 'Error al cargar el archivo: %. Sentencia ejecutada: %', SQLERRM,wsql;
--        EXECUTE 'COPY tab_temp_raps FROM ''/var/www/html/seguimiento0.1/postgres/Reporte_Raps.csv'' DELIMITER ''|''';
-- FIN DE LA CARGA
--Validando y extractando el Centro desde la tabla de RAPS.
        SELECT SUBSTR(a.nom_centro,1,4) INTO wid_centro FROM tab_temp_raps a
        LIMIT 1;
        IF NOT FOUND OR
           wid_centro IS NULL THEN
            RAISE NOTICE 'Nos jodimos... El centro % tiene problemas',wid_centro;
            RETURN FALSE;
        END IF;
--Validando y extractando la Regional desde la tabla de RAPS.
        SELECT SUBSTR(a.nom_regional,1,2) INTO wid_regional FROM tab_temp_raps a
        LIMIT 1;
        IF NOT FOUND OR
           wid_regional IS NULL THEN
            RAISE NOTICE 'Nos jodimos... La Regional % tiene problemas',wid_regional;
            RETURN FALSE;
        END IF;
-- Total de aprendices que vienen en el reporte
        SELECT COUNT(DISTINCT a.nom_aprendiz) INTO wtot_aprend FROM tab_temp_raps a;
        IF NOT FOUND OR wtot_aprend IS NULL THEN
            wtot_aprend = 0;
            RETURN FALSE;
        END IF;
-- Total de aprendices activos que vienen en el reporte
        SELECT COUNT(DISTINCT a.nom_aprendiz) INTO wtot_aprend_act FROM tab_temp_raps a
        WHERE a.ind_est_aprendiz = 'EN FORMACION';
        IF NOT FOUND OR wtot_aprend_act IS NULL THEN
            wtot_aprend_act = 0;
            RETURN FALSE;
        END IF;
-- Obteniendo el estado de la ficha
        SELECT ind_estado,
        CASE 
            WHEN ind_estado = 'EN INDUCCION' THEN 0
		    WHEN ind_estado = 'EN EJECUCION' THEN 1
            WHEN ind_estado = 'TERMINADA POR FECHA' THEN 2
            WHEN ind_estado = 'TERMINADA' THEN 3
        ELSE 5
        END INTO wind_estado
        FROM tab_temp_raps
        LIMIT 1;

-- Carga del reporte en el cursor para recorrer y filtrar, poblando las tablas que se requieran
        OPEN wcur_raps FOR SELECT a.fec_reporte,a.id_ficha,a.id_programa,a.id_version,a.nom_ficha,a.ind_estado,a.fec_inicio,a.fec_fin,a.id_modalidad,
                                  SUBSTRING(a.nom_regional FROM '^\d+') AS id_regional,TRIM(REGEXP_REPLACE(a.nom_regional, '^.*? - ', '')) AS nom_regional,
                                  SUBSTRING(a.nom_centro FROM '^\d+') AS id_centro,TRIM(REGEXP_REPLACE(a.nom_centro, '^.*? - ', '')) AS nom_centro,
                                  a.id_tipodoc,a.num_docume,a.nom_aprendiz,a.ape_aprendiz,a.ind_est_aprendiz,
                                  SUBSTRING(a.nom_competencia FROM '^\d+') AS id_compet,
                                  TRIM(REGEXP_REPLACE(a.nom_competencia, '^.*? - ', '')) AS nom_compet,
                                  SUBSTRING(nom_rap FROM '^(\d+)') AS id_rap,
                                  SUBSTRING(nom_rap FROM ' - (\d+)') AS val_sec_rap,
                                  TRIM(REGEXP_REPLACE(nom_rap, '^.*? - (\d+\s+)?', '')) AS nom_rap,a.val_juicio,a.fec_juicio,
								  SPLIT_PART(nom_instructor, ' ', 1) AS id_tipodocins,
                                  TRIM(SUBSTRING(nom_instructor FROM ' ([0-9]+) -')) AS id_instructor,
                                  TRIM(SPLIT_PART(nom_instructor, '-', 2)) AS nom_instructor FROM tab_temp_raps a;
            FETCH wcur_raps INTO wreg_raps;
            WHILE FOUND LOOP
                RAISE NOTICE 'Mire mijo, Estoy Procesando la Ficha %', wreg_raps.id_ficha;
-- VALIDAR LAS ENTRADAS QUE VIENEN DEL FRONT, POR SI LAS DUDAS (NULIDAD, VALOR NEGATIVOS, ETC.)
	            PERFORM 1 FROM tab_centros
	            WHERE id_centro =  wid_centro;
	            IF NOT FOUND THEN
                    INSERT INTO tab_centros VALUES(wid_centro,wreg_raps.nom_centro,CURRENT_DATE);
                    IF NOT FOUND THEN
		                RAISE NOTICE 'Salió mal la cosa al insertar Centro %..', wid_centro;
                        RETURN FALSE;
                    END IF;
	            END IF;
                wid_programa = wreg_raps.id_programa;
	            PERFORM 1 FROM tab_programas
	            WHERE id_programa =  wid_programa;
	            IF NOT FOUND THEN
                    INSERT INTO tab_programas VALUES(wid_programa,wreg_raps.nom_ficha,wreg_raps.id_version,0,0,0);
                    IF NOT FOUND THEN
		                RAISE NOTICE 'Salió mal la cosa al insertar Programa %', wid_programa;
                        RETURN FALSE;
                    END IF;
                END IF;
                wid_ficha = wreg_raps.id_ficha;
	            PERFORM 1 FROM tab_fichas
	            WHERE id_ficha =  wid_ficha;
	            IF NOT FOUND THEN
-- Jornada: 0:NA/1:Mañana/2:Tarde/3:Mixta/4:Noche
                    INSERT INTO tab_fichas VALUES(wid_ficha,wind_estado,'1','X','0',
                                                  wreg_raps.fec_inicio,'N','N',wreg_raps.fec_fin,
                                                  wreg_raps.id_instructor,wreg_raps.id_programa,FALSE,wtot_aprend,
                                                  wtot_aprend_act,30,'TIP_RTA',0,0,wtot_aprend_act,0,0,0,0,0,0,0,0,0,'0',0,0,0,0,
                                                  0,0,wtot_aprend_act,0,wid_centro,'NA',0,0,0,'0');
                    IF FOUND THEN
                        RAISE NOTICE 'La Ficha % se insertó bien.. No es tab bruto como pensé',wid_ficha;
                    ELSE
                        RAISE NOTICE 'problemas insertando la  Ficha %.. parece que Usted es muuuuy bruto',wid_ficha;
                        RETURN FALSE;
                    END IF;
-- ACTUALIZAR SI EXISTE EL PROGRAMA
                ELSE
                    UPDATE ficha SET id_ficha           = wreg_raps.id_ficha,
                                     ind_estado         = wreg_raps.ind_estado,
                                     ind_nivel          = wreg_raps.id_nivel_forma,
                                     ind_jornada        = wreg_raps.id_jornada,
                                     ind_tipo           = wreg_raps.ind_tipo_forma,
                                     fec_ini_lectiva    = wreg_raps.fec_inicio_ficha,
                                     fec_fin_lectiva    = '1900-01-01',
                                     fec_ini_produc     = '1900-01-01',
                                     fec_fin_produc     = wreg_raps.fec_fin,
                                     ind_etapa          = wreg_raps.val_etapa_ficha,
                                     ind_modalidad      = wreg_raps.val_modalidad,
                                     nom_responsable    = wreg_raps.nom_responsable,
                                     id_programa        = wreg_raps.id_programa,
                                     ind_cobertura      = FALSE,
                                     val_total_aprend   = wreg_raps.num_tot_aprend,
                                     val_apr_activos    = wreg_raps.val_total_apr_act,
                                     val_cupo_ficha     = 30,
--                                   fic_tipo_respue    = 'TIP_RTA',
--                                   val_apre_transito  = 0,
--                                   val_apre_inducci   = 0,
                                     val_apre_formaci   = wreg_raps.val_total_apr_act,
--                                   val_apre_condici   = 0,
--                                   val_apre_aplaz     = 0; 
--                                   val_apre_cancel    = 0; 
--                                   val_apre_porcer    = 0;
--                                   val_apre_certif    = 0;
--                                   Val_apre_traslad   = 0;
--                                   val_apre_aotro     = 0;
--                                   val_apre_acruta    = 0;
--                                   val_apre_asruta    = 0;
--                                   ind_programada     = 0;
--                                   val_apre_sinjui    = 0;
--                                   val_apre_noapro    = 0;
--                                   val_apre_avacal    = 0;
--                                   val_competencias   = 0;
--                                   val_min_evalcomp   = 0;
--                                   val_max_evalcomp   = 0;
                                     val_apre_formaci   = wreg_raps.val_total_apr_act,
--                                   val_atapa_calcul   = 0,
                                     id_centro          = wid_centro,
                                     id_progespecial    = wreg_raps.id_prog_especial
--                                   val_total_raps     = 0,
--                                   val_rap_50s        = 0,
--                                   val_rap_produc     = 0,
--                                   vienen_fic_bi      = '0')
                    WHERE id_ficha = wreg_raps.id_ficha;
                    IF FOUND THEN
                        RAISE NOTICE 'La Ficha % se actualizó bien.. No es tan bruto como pensé',wreg_raps.id_ficha;
                    ELSE
                        RAISE NOTICE 'problemas actualizando la  Ficha %.. parece que Usted es muuuuy bruto',wreg_raps.id_ficha;
                        RETURN FALSE;
                    END IF;
	            END IF;
--                RAISE NOTICE '% % % %',wreg_raps.cod_regional,wreg_raps.nom_regional,wid_centro,wreg_raps.nom_centro;
                FETCH wcur_raps INTO wreg_raps;
            END LOOP;
        CLOSE wcur_raps;
        RETURN TRUE;
    END;
$BODY$
LANGUAGE PLPGSQL;