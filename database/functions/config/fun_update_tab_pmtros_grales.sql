CREATE OR REPLACE FUNCTION fun_update_tab_pmtros_grales(
    wid_centro                   tab_pmtros_grales.id_centro%TYPE,
    wdir_centro                  tab_pmtros_grales.dir_centro%TYPE,
    wtel_centro                  tab_pmtros_grales.tel_centro%TYPE,
    wano_academico               tab_pmtros_grales.ano_academico%TYPE,
    wmes_academico               tab_pmtros_grales.mes_academico%TYPE,
    wval_nota_minima_rap         tab_pmtros_grales.val_nota_minima_rap%TYPE,
    wnum_horas_instructor        tab_pmtros_grales.num_horas_instructor%TYPE,
    wval_porcent_icfes_raps      tab_pmtros_grales.val_porcent_icfes_raps%TYPE,
    wval_tiempo_gracia_aprendiz  tab_pmtros_grales.val_tiempo_gracia_aprendiz%TYPE,
    wval_tiempo_gracia_instru    tab_pmtros_grales.val_tiempo_gracia_instru%TYPE,
    wval_max_llamados_aprendiz   tab_pmtros_grales.val_max_llamados_aprendiz%TYPE,
    wnom_administrador           tab_pmtros_grales.nom_administrador%TYPE,
    wtel_administrador           tab_pmtros_grales.tel_administrador%TYPE,
    wusr_update                  VARCHAR
) RETURNS TEXT AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_centro IS NULL OR NOT EXISTS (
        SELECT 1 FROM tab_centros WHERE id_centro = wid_centro
    ) THEN
        PERFORM smartcset_raise_validacion('El centro indicado no existe.');
    END IF;

    IF LENGTH(TRIM(wdir_centro)) < 10 THEN
        PERFORM smartcset_raise_validacion('La dirección del centro debe tener al menos 10 caracteres.');
    END IF;

    IF wtel_centro IS NULL OR wtel_centro <= 0 THEN
        PERFORM smartcset_raise_validacion('El teléfono del centro debe ser un número válido.');
    END IF;

    IF wano_academico IS NULL OR wano_academico < 2000 OR wano_academico > 2100 THEN
        PERFORM smartcset_raise_validacion('El año académico debe estar entre 2000 y 2100.');
    END IF;

    IF wmes_academico IS NULL OR wmes_academico < 1 OR wmes_academico > 12 THEN
        PERFORM smartcset_raise_validacion('El mes académico debe estar entre 1 y 12.');
    END IF;

    IF wval_nota_minima_rap IS NULL OR wval_nota_minima_rap < 0 OR wval_nota_minima_rap > 100 THEN
        PERFORM smartcset_raise_validacion('La nota mínima RAP debe estar entre 0 y 100.');
    END IF;

    IF wnum_horas_instructor IS NULL OR wnum_horas_instructor < 0 OR wnum_horas_instructor > 200 THEN
        PERFORM smartcset_raise_validacion('Las horas del instructor deben estar entre 0 y 200.');
    END IF;

    IF wval_porcent_icfes_raps IS NULL OR wval_porcent_icfes_raps < 0 OR wval_porcent_icfes_raps > 100 THEN
        PERFORM smartcset_raise_validacion('El porcentaje mínimo de RAPs para ICFES debe estar entre 0 y 100.');
    END IF;

    IF wval_tiempo_gracia_aprendiz IS NULL OR wval_tiempo_gracia_aprendiz < 0 THEN
        PERFORM smartcset_raise_validacion('El tiempo de gracia del aprendiz no puede ser negativo.');
    END IF;

    IF wval_tiempo_gracia_instru IS NULL OR wval_tiempo_gracia_instru < 0 THEN
        PERFORM smartcset_raise_validacion('El tiempo de gracia del instructor no puede ser negativo.');
    END IF;

    IF wval_max_llamados_aprendiz IS NULL OR wval_max_llamados_aprendiz < 1 OR wval_max_llamados_aprendiz > 9 THEN
        PERFORM smartcset_raise_validacion('El máximo de llamados de atención debe estar entre 1 y 9.');
    END IF;

    IF LENGTH(TRIM(wnom_administrador)) < 3 OR LENGTH(TRIM(wnom_administrador)) > 80 THEN
        PERFORM smartcset_raise_validacion('El nombre del administrador debe tener entre 3 y 80 caracteres.');
    END IF;

    IF wtel_administrador IS NULL OR wtel_administrador <= 0 THEN
        PERFORM smartcset_raise_validacion('El teléfono del administrador debe ser un número válido.');
    END IF;

    UPDATE tab_pmtros_grales
    SET dir_centro                  = TRIM(wdir_centro),
        tel_centro                  = wtel_centro,
        ano_academico               = wano_academico,
        mes_academico               = wmes_academico,
        val_nota_minima_rap         = wval_nota_minima_rap,
        num_horas_instructor        = wnum_horas_instructor,
        val_porcent_icfes_raps      = wval_porcent_icfes_raps,
        val_tiempo_gracia_aprendiz  = wval_tiempo_gracia_aprendiz,
        val_tiempo_gracia_instru    = wval_tiempo_gracia_instru,
        val_max_llamados_aprendiz   = wval_max_llamados_aprendiz,
        nom_administrador           = TRIM(wnom_administrador),
        tel_administrador           = wtel_administrador,
        usr_update                  = wusr_update,
        fec_update                  = NOW()
    WHERE id_centro = wid_centro;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'No existen parámetros generales para el centro indicado.',
            'id_centro=' || wid_centro
        );
    END IF;

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;
