-- ****************************************************************************************
-- Trigger para enviar a comite cuando cumple el umbral de llamados de atención (Aprendiz).
-- ****************************************************************************************

CREATE OR REPLACE FUNCTION trg_aprendices_after_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.num_llamados IS DISTINCT FROM NEW.num_llamados THEN
        PERFORM fun_sincronizar_comite_aprendiz(NEW.id_aprendiz);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_aprendices_after_update
AFTER UPDATE ON tab_aprendices
FOR EACH ROW
EXECUTE FUNCTION trg_aprendices_after_update();


-- *************************************************************************
-- Trigger para actualizar el número de llamados de atención de un aprendiz.
-- *************************************************************************

CREATE OR REPLACE FUNCTION trg_llamados_atencion_after()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.ind_tipo_tercero = TRUE THEN
            PERFORM fun_actualizar_num_llamados(NEW.id_tercero);
        END IF;
        RETURN NEW;
    
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.ind_tipo_tercero = TRUE THEN
            PERFORM fun_actualizar_num_llamados(OLD.id_tercero);
        END IF;
        RETURN OLD;
    
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.id_tercero IS DISTINCT FROM NEW.id_tercero OR
           OLD.ind_tipo_tercero IS DISTINCT FROM NEW.ind_tipo_tercero THEN
            IF OLD.ind_tipo_tercero = TRUE THEN
                PERFORM fun_actualizar_num_llamados(OLD.id_tercero);
            END IF;
            IF NEW.ind_tipo_tercero = TRUE THEN
                PERFORM fun_actualizar_num_llamados(NEW.id_tercero);
            END IF;
        ELSE
            IF NEW.ind_tipo_tercero = TRUE THEN
                PERFORM fun_actualizar_num_llamados(NEW.id_tercero);
            END IF;
        END IF;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_llamados_atencion_after
AFTER INSERT OR DELETE OR UPDATE ON tab_llamados_atencion
FOR EACH ROW
EXECUTE FUNCTION trg_llamados_atencion_after();