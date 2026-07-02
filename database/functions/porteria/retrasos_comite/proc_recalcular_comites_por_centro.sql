CREATE OR REPLACE PROCEDURE proc_recalcular_comites_por_centro(p_id_centro DECIMAL(4,0))
LANGUAGE plpgsql AS $$
DECLARE
    rec RECORD;
    v_usr_actual VARCHAR(50);
BEGIN
    v_usr_actual := COALESCE(current_setting('app.current_user', true), 'SISTEMA');
    RAISE NOTICE 'Iniciando recálculo de comités para centro % por usuario %', p_id_centro, v_usr_actual;
    
    -- Recorrer aprendices del centro (a través de la ficha)
    FOR rec IN 
        SELECT a.id_aprendiz
        FROM tab_aprendices a
        JOIN tab_fichas f ON a.id_ficha_vigente = f.id_ficha
        WHERE f.id_centro = p_id_centro
    LOOP
        PERFORM fun_sincronizar_comite_aprendiz(rec.id_aprendiz);
    END LOOP;
    
    RAISE NOTICE 'Recálculo completado para centro %', p_id_centro;
END;
$$;