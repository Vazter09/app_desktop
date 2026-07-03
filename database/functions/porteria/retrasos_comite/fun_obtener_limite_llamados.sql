-- ***********************************************************************************
-- Función para obtener el límite de llamados de atención para un centro de formación.
-- ***********************************************************************************

CREATE OR REPLACE FUNCTION fun_obtener_limite_llamados(p_id_centro DECIMAL)
RETURNS SMALLINT AS $$
DECLARE
    v_limite tab_pmtros_grales.val_max_llamados_aprendiz%TYPE;
BEGIN
    SELECT val_max_llamados_aprendiz
    INTO v_limite
    FROM tab_pmtros_grales
    WHERE id_centro = p_id_centro;
    
    RAISE NOTICE 'Límite obtenido para centro %: %', p_id_centro, v_limite;
    RETURN v_limite;
END;
$$ LANGUAGE plpgsql;