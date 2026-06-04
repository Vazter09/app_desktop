<?php
/**
 * ARCHIVO DE CONFIGURACIÓN - SistNomina V.1.2
 * Carga variables desde .env para mayor seguridad
 */

// Cargar variables de entorno
require_once(__DIR__ . '/EnvLoader.php');
EnvLoader::load();

// Parámetros de conexión a PostgreSQL (desde .env)
define('DB_HOST', EnvLoader::get('DB_HOST', 'localhost'));
define('DB_PORT', EnvLoader::get('DB_PORT', '5432'));
define('DB_NAME', EnvLoader::get('DB_NAME', 'db_smartcset'));
define('DB_USER', EnvLoader::get('DB_USER', 'postgres'));
define('DB_PASS', EnvLoader::get('DB_PASS', 'postgres123'));

// Estilos corporativos y rutas (desde .env)
define('COLOR_VERDE_OSCURO', EnvLoader::get('COLOR_VERDE_OSCURO', '#004d40'));
define('COLOR_VERDE_OLIVA', EnvLoader::get('COLOR_VERDE_OLIVA', '#808000'));
define('PATH_LOGO', EnvLoader::get('PATH_LOGO', 'img/logo-sena.png'));

// Configuración de sesión (desde .env)
define('SESSION_TIMEOUT', (int) EnvLoader::get('SESSION_TIMEOUT', '1800'));
define('APP_ENV', EnvLoader::get('APP_ENV', 'development'));

// Zona horaria: BD guarda TIMESTAMP sin TZ (servidor PostgreSQL suele ser UTC).
define('DB_TIMEZONE', EnvLoader::get('DB_TIMEZONE', 'UTC'));
define('APP_TIMEZONE', EnvLoader::get('APP_TIMEZONE', 'America/Bogota'));
date_default_timezone_set(APP_TIMEZONE);

// Presencia lite (ult_actividad + heartbeat)
define('SESION_PRESENCIA_ACTIVO_MIN', max(1, (int) EnvLoader::get('SESION_PRESENCIA_ACTIVO_MIN', '5')));
define('SESION_HEARTBEAT_SEG', max(15, (int) EnvLoader::get('SESION_HEARTBEAT_SEG', '60')));

// Validar que la IP del request coincida con ip_cliente de tab_sesiones (anti secuestro de cookie).
define(
    'SESION_VALIDAR_IP',
    filter_var(EnvLoader::get('SESION_VALIDAR_IP', '1'), FILTER_VALIDATE_BOOLEAN)
);
// Tras proxy/Nginx confiable: usar el primer valor de X-Forwarded-For como IP del cliente.
define(
    'SESION_TRUST_PROXY',
    filter_var(EnvLoader::get('SESION_TRUST_PROXY', '0'), FILTER_VALIDATE_BOOLEAN)
);

// Notación para variables globales
$w_error_db = "Error de conexión: ";

// Configuración de sesión basada en variable de entorno
if (session_status() === PHP_SESSION_NONE) {
    ini_set('session.gc_maxlifetime', SESSION_TIMEOUT);
    ini_set('session.cookie_lifetime', SESSION_TIMEOUT);
}
?>
