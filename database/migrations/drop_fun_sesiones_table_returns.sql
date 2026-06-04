-- Reemplazo: validación TEXT; listado vía SELECT en prepare.php (como portería).
DROP FUNCTION IF EXISTS fun_listar_sesiones_activas();
DROP FUNCTION IF EXISTS fun_consultar_sesion_activa(INTEGER, VARCHAR);
DROP FUNCTION IF EXISTS fun_consultar_sesion_activa(INTEGER, TEXT);
