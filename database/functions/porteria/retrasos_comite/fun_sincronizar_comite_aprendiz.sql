-- Sincroniza ciclos de comité automático según num_llamados / umbral del centro.
-- Comités automáticos: responsable_comite = 0 (no usr_insert = SISTEMA).
CREATE OR REPLACE FUNCTION fun_sincronizar_comite_aprendiz(
    p_id_aprendiz tab_aprendices.id_aprendiz%TYPE
) RETURNS VOID AS $$
DECLARE
    v_id_centro         tab_fichas.id_centro%TYPE;
    v_limite            SMALLINT;
    v_num_llamados      tab_aprendices.num_llamados%TYPE;
    v_ciclo_esperado    INTEGER;
    v_max_ciclo_activo  INTEGER;
    v_ciclo_actual      INTEGER;
    v_usr_actual        TEXT;
    w_exc_state         TEXT;
    w_exc_msg           TEXT;
    w_exc_detail        TEXT;
    w_exc_hint          TEXT;
BEGIN
    v_usr_actual := NULLIF(TRIM(current_setting('app.usuario', true)), '');
    IF v_usr_actual IS NULL THEN
        RETURN;
    END IF;

    v_id_centro := fun_obtener_centro_aprendiz(p_id_aprendiz);
    IF v_id_centro IS NULL THEN
        RETURN;
    END IF;

    v_limite := fun_obtener_limite_llamados(v_id_centro);
    IF v_limite IS NULL OR v_limite <= 0 THEN
        RETURN;
    END IF;

    SELECT a.num_llamados
      INTO v_num_llamados
      FROM tab_aprendices a
     WHERE a.id_aprendiz = p_id_aprendiz;

    IF v_num_llamados IS NULL THEN
        RETURN;
    END IF;

    v_ciclo_esperado := FLOOR(v_num_llamados::NUMERIC / v_limite::NUMERIC)::INTEGER;

    SELECT COALESCE(MAX(c.ciclo_comite), 0)
      INTO v_max_ciclo_activo
      FROM tab_comite_aprendices c
     WHERE c.id_implicado = p_id_aprendiz
       AND c.estado_comite <> 2
       AND c.responsable_comite = 0;

    IF v_max_ciclo_activo < v_ciclo_esperado THEN
        FOR v_ciclo_actual IN (v_max_ciclo_activo + 1)..v_ciclo_esperado LOOP
            INSERT INTO tab_comite_aprendices (
                id_implicado,
                responsable_comite,
                ciclo_comite,
                estado_comite,
                observacion_comite,
                usr_insert,
                fec_insert
            ) VALUES (
                p_id_aprendiz,
                0,
                v_ciclo_actual,
                0,
                'Ciclo ' || v_ciclo_actual
                    || ' alcanzado automáticamente con '
                    || (v_ciclo_actual * v_limite)
                    || ' llamados de atención',
                v_usr_actual,
                CURRENT_TIMESTAMP
            );
        END LOOP;
    END IF;

    UPDATE tab_comite_aprendices
       SET estado_comite = 2,
           observacion_comite = 'Cerrado automáticamente porque los llamados bajaron a '
               || v_num_llamados,
           usr_update = v_usr_actual,
           fec_update = CURRENT_TIMESTAMP
     WHERE id_implicado = p_id_aprendiz
       AND ciclo_comite > v_ciclo_esperado
       AND estado_comite <> 2
       AND responsable_comite = 0;
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
