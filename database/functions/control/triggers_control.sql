CREATE OR REPLACE FUNCTION fn_validar_ano_academico()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ano_academico < EXTRACT(YEAR FROM CURRENT_DATE) THEN
        RAISE EXCEPTION 'El año académico (%) no puede ser menor al año actual (%).', NEW.ano_academico, EXTRACT(YEAR FROM CURRENT_DATE);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valid_ano_academico
BEFORE INSERT OR UPDATE OF ano_academico ON tab_pmtros_grales
FOR EACH ROW EXECUTE FUNCTION fn_validar_ano_academico();