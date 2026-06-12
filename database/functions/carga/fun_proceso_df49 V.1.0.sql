--SELECT fun_genera_files();
--SELECT * FROM tab_temp_df49;
--SELECT * FROM centro;
--SELECT * FROM programa;
--SELECT * FROM ficha;
CREATE OR REPLACE FUNCTION fun_proceso_df49() RETURNS BOOLEAN AS
$$
    DECLARE wcur_df49 REFCURSOR;
    DECLARE wreg_df49 RECORD;
    BEGIN
        OPEN wcur_df49 FOR SELECT a.cod_regional,a.nom_regional,a.cod_centro,a.nom_centro,a.id_ficha,
                                  a.fec_inicial,a.fec_final,a.ind_estado,a.id_programa,a.id_version,
							      a.nom_programa,a.ind_nivel,a.ind_cobertura,a.num_aprend_certif,
                                  a.num_aprend_sincer,a.num_aprend_sinjui,a.num_aprend_noapro,
                                  a.num_aprend_matric,a.id_prog_especial
                           FROM tab_temp_df49 a;
            FETCH wcur_df49 INTO wreg_df49;
            WHILE FOUND LOOP
                RAISE NOTICE 'Mire mijo, Estoy Procesando la Ficha %', wreg_df49.id_ficha;
-- VALIDAR LAS ENTRADAS QUE VIENEN DEL FRONT, POR SI LAS DUDAS (NULIDAD, VALOR NEGATIVOS, ETC.)
	            PERFORM 1 FROM centro
	            WHERE cen_id =  wreg_df49.cod_centro;
	            IF NOT FOUND THEN
                    INSERT INTO centro VALUES(wreg_df49.cod_centro,wreg_df49.nom_centro,wreg_df49.id_programa,wreg_df49.id_version,
                                              wreg_df49.nom_programa);
                    IF NOT FOUND THEN
		                RAISE NOTICE 'Salió mal la cosa al insertar Centro %..', wreg_df49.cod_centro;
                        RETURN FALSE;
                    END IF;
	            END IF;
	            PERFORM 1 FROM programa
	            WHERE pro_id =  wreg_df49.id_programa;
	            IF NOT FOUND THEN
                    INSERT INTO programa VALUES(wreg_df49.id_programa,wreg_df49.nom_programa,wreg_df49.id_version,'NA','NA','NA');
                    IF NOT FOUND THEN
		                RAISE NOTICE 'Salió mal la cosa al insertar Programa %', wreg_df49.id_programa;
                        RETURN FALSE;
                    END IF;
                END IF;
	            PERFORM 1 FROM ficha
	            WHERE fic_id =  wreg_df49.id_ficha;
	            IF NOT FOUND THEN
-- Jornada: 0:NA/1:Mañana/2:Tarde/3:Mixta/4:Noche
                    INSERT INTO ficha VALUES(wreg_df49.id_ficha,wreg_df49.ind_estado,wreg_df49.ind_nivel,'JORNADA','TIPO FORM.',wreg_df49.fec_inicial,
                                             wreg_df49.fec_final,'ETAPA','MODALIDAD','RESPONSABLE',wreg_df49.id_programa,wreg_df49.ind_cobertura,
                                             0,0,0,'TIP_RTA',0,0,wreg_df49.num_aprend_matric,0,0,wreg_df49.num_aprend_sincer,wreg_df49.num_aprend_certif,
                                             wreg_df49.num_aprend_certif,0,0,0,0,'0',wreg_df49.num_aprend_sinjui,wreg_df49.num_aprend_noapro,0,0,0,0,
                                             wreg_df49.num_aprend_matric,0,wreg_df49.cod_centro,wreg_df49.id_prog_especial,0,0,0,'0');
                    IF FOUND THEN
                        RAISE NOTICE 'La Ficha % se insertó bien.. No es tab bruto como pensé',wreg_df49.id_ficha;
                    ELSE
                        RAISE NOTICE 'problemas insertando la  Ficha %.. parece que Usted es muuuuy bruto',wreg_df49.id_ficha;
                        RETURN FALSE;
                    END IF;
-- ACTUALIZAR SI EXISTE EL PROGRAMA
	            END IF;
--                RAISE NOTICE '% % % %',wreg_df49.cod_regional,wreg_df49.nom_regional,wreg_df49.cod_centro,wreg_df49.nom_centro;
                FETCH wcur_df49 INTO wreg_df49;
            END LOOP;
        CLOSE wcur_df49;
        RETURN TRUE;
    END;
$$
LANGUAGE PLPGSQL;