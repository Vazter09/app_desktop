-- Requerido al cambiar RETURNS TEXT → VOID (ejecutar una vez antes de redesplegar portería).
DROP FUNCTION IF EXISTS fun_upsert_persona_visitante(numeric, character varying, numeric, character varying, character varying, character varying);
DROP FUNCTION IF EXISTS fun_update_persona_tras_ingreso(numeric, character varying);
DROP FUNCTION IF EXISTS fun_update_persona_tras_salida(numeric, character varying);
