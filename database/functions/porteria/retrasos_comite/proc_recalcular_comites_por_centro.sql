-- Recalcula comités automáticos de todos los aprendices de un centro.
CREATE OR REPLACE PROCEDURE proc_recalcular_comites_por_centro(
    p_id_centro tab_fichas.id_centro%TYPE
)
LANGUAGE plpgsql AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT a.id_aprendiz
          FROM tab_aprendices a
          JOIN tab_fichas f ON f.id_ficha = a.id_ficha
         WHERE f.id_centro = p_id_centro
    LOOP
        PERFORM fun_sincronizar_comite_aprendiz(rec.id_aprendiz);
    END LOOP;
END;
$$;
