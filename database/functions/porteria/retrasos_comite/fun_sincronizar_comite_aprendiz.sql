-- ***********************************************************
-- Función para sincronizar los ciclos de comité del aprendiz.
-- ***********************************************************

CREATE OR REPLACE FUNCTION fun_sincronizar_comite_aprendiz(p_id_aprendiz DECIMAL)
RETURNS VOID AS $$
DECLARE
    v_id_centro tab_fichas.id_centro%TYPE;
    v_limite tab_pmtros_grales.val_max_llamados_aprendiz%TYPE;
    v_num_llamados tab_aprendices.num_llamados%TYPE;
    v_ciclo_esperado INTEGER;
    v_max_ciclo_activo INTEGER;
    v_ciclo_actual INTEGER;
    v_usr_actual VARCHAR(50);
    v_responsable_comite tab_comite_aprendices.responsable_comite%TYPE := 0;
BEGIN
    v_usr_actual := COALESCE(current_setting('app.current_user', true), 'SISTEMA');
    
    -- Obtener centro
    v_id_centro := fun_obtener_centro_aprendiz(p_id_aprendiz);
    IF v_id_centro IS NULL THEN
        RAISE WARNING 'No se pudo determinar el centro para el aprendiz %', p_id_aprendiz;
        RETURN;
    END IF;
    
    -- Obtener límite
    v_limite := fun_obtener_limite_llamados(v_id_centro);
    IF v_limite IS NULL OR v_limite <= 0 THEN
        RAISE NOTICE 'Límite inválido o no definido para centro %', v_id_centro;
        RETURN;
    END IF;
    
    -- Obtener número actual de llamados
    SELECT num_llamados INTO v_num_llamados
    FROM tab_aprendices
    WHERE id_aprendiz = p_id_aprendiz;
    
    IF v_num_llamados IS NULL THEN
        RETURN;
    END IF;
    
    -- Ciclo esperado
    v_ciclo_esperado := FLOOR(v_num_llamados / v_limite);
    
    RAISE NOTICE 'Aprendiz %, llamados=%, límite=%, ciclo_esperado=%', 
                 p_id_aprendiz, v_num_llamados, v_limite, v_ciclo_esperado;
    
    -- Obtener máximo ciclo activo entre los automáticos
    SELECT COALESCE(MAX(ciclo_comite), 0)
    INTO v_max_ciclo_activo
    FROM tab_comite_aprendices
    WHERE id_implicado = p_id_aprendiz
      AND estado_comite != 2
      AND usr_insert = 'SISTEMA';
    
    -- Insertar nuevos ciclos si corresponde
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
                v_responsable_comite,
                v_ciclo_actual,
                0,
                'Ciclo ' || v_ciclo_actual || ' alcanzado automáticamente con ' || (v_ciclo_actual * v_limite) || ' llamados de atención',
                v_usr_actual,
                NOW()
            );
            RAISE NOTICE 'Insertado ciclo % para aprendiz %', v_ciclo_actual, p_id_aprendiz;
        END LOOP;
    END IF;
    
    -- Cerrar ciclos automáticos que ya no correspondan
    UPDATE tab_comite_aprendices
    SET estado_comite = 2,
        observacion_comite = 'Cerrado automáticamente porque los llamados bajaron a ' || v_num_llamados,
        usr_update = v_usr_actual,
        fec_update = NOW()
    WHERE id_implicado = p_id_aprendiz
      AND ciclo_comite > v_ciclo_esperado
      AND estado_comite != 2
      AND usr_insert = 'SISTEMA';
    
    IF FOUND THEN
        RAISE NOTICE 'Se cerraron ciclos automáticos para aprendiz % (nuevo total: %)', p_id_aprendiz, v_num_llamados;
    END IF;
    
END;
$$ LANGUAGE plpgsql;