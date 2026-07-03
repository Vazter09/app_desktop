-- ***********************************************************
-- Función para obtener el centro de formación de un aprendiz.
-- ***********************************************************

CREATE OR REPLACE FUNCTION fun_obtener_centro_aprendiz(p_id_aprendiz DECIMAL)
RETURNS DECIMAL(4,0) AS $$
DECLARE
    v_id_centro tab_fichas.id_centro%TYPE;  -- Hereda el tipo de la columna
BEGIN
    SELECT f.id_centro
    INTO v_id_centro
    FROM tab_aprendices a
    JOIN tab_fichas f ON a.id_ficha_vigente = f.id_ficha
    WHERE a.id_aprendiz = p_id_aprendiz;
    
    RAISE NOTICE 'Centro obtenido para aprendiz %: %', p_id_aprendiz, v_id_centro;
    RETURN v_id_centro;
END;
$$ LANGUAGE plpgsql;