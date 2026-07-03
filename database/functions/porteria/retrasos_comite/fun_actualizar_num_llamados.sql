-- *************************************************************************
-- Función para actualizar el número de llamados de atención de un aprendiz.
-- *************************************************************************

CREATE OR REPLACE FUNCTION fun_actualizar_num_llamados(p_id_aprendiz DECIMAL)
RETURNS VOID AS $$
DECLARE
    v_total INTEGER;
    v_usr_update VARCHAR(50);
BEGIN
    v_usr_update := COALESCE(current_setting('app.current_user', true), 'SISTEMA');
    
    SELECT COUNT(*)
    INTO v_total
    FROM tab_llamados_atencion
    WHERE id_tercero = p_id_aprendiz
      AND ind_tipo_tercero = TRUE;
    
    UPDATE tab_aprendices
    SET num_llamados = v_total,
        usr_update = v_usr_update,
        fec_update = NOW()
    WHERE id_aprendiz = p_id_aprendiz;
    
    RAISE NOTICE 'num_llamados actualizado a % para aprendiz %', v_total, p_id_aprendiz;
END;
$$ LANGUAGE plpgsql;