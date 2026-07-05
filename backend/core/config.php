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

// Modo SSL de la conexión PHP->PostgreSQL (vacío = comportamiento actual, sin forzar TLS).
// Activar 'require' o 'verify-full' solo cuando el servidor PostgreSQL tenga SSL habilitado
// (postgresql.conf: ssl=on + certificados) — ver Fase 1 Entregable 8.
define('DB_SSLMODE', EnvLoader::get('DB_SSLMODE', ''));

// Clave de cifrado de datos sensibles en reposo (pgcrypto, ver Fase 1 Entregable 2).
// Debe coincidir con app.encryption_key configurado en PostgreSQL (ALTER DATABASE ... SET).
define('DB_ENCRYPTION_KEY', EnvLoader::get('DB_ENCRYPTION_KEY', ''));
if (empty(DB_ENCRYPTION_KEY)) {
    error_log('[SmartCSET] ADVERTENCIA: DB_ENCRYPTION_KEY no configurada.');
}

// Estilos corporativos y rutas (desde .env)
define('COLOR_VERDE_OSCURO', EnvLoader::get('COLOR_VERDE_OSCURO', '#004d40'));
define('COLOR_VERDE_OLIVA', EnvLoader::get('COLOR_VERDE_OLIVA', '#808000'));
define('PATH_LOGO', EnvLoader::get('PATH_LOGO', 'assets/img/logo-sena.png'));

// Raíz del proyecto (contiene backend/, frontend/, storage/)
define('SMARTCSET_ROOT', dirname(__DIR__, 2));

define(
    'STORAGE_PORTERIA_PATH',
    EnvLoader::get('STORAGE_PORTERIA_PATH', 'storage/porteria')
);

function smartcsetStoragePorteriaAbs(string $subdir, string $fechaDir): string
{
    $base = STORAGE_PORTERIA_PATH;
    if ($base !== '' && $base[0] === '/') {
        $root = rtrim($base, '/');
    } else {
        $root = SMARTCSET_ROOT . '/' . trim($base, '/');
    }

    return $root . '/' . $subdir . '/' . $fechaDir;
}

// Configuración de sesión (desde .env)
define('SESSION_TIMEOUT', (int) EnvLoader::get('SESSION_TIMEOUT', '1800'));
define('APP_ENV', EnvLoader::get('APP_ENV', 'development'));

// Prefijo URL cuando la app no está en la raíz del dominio (ej. /smartcset en Apache).
define('APP_BASE_PATH', trim((string) EnvLoader::get('APP_BASE_PATH', ''), '/'));

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

// Rate limiting de login (E3 — FASE 1)
define('LOGIN_MAX_INTENTOS', max(1, (int) EnvLoader::get('LOGIN_MAX_INTENTOS', '5')));
define('LOGIN_VENTANA_MINUTOS', max(1, (int) EnvLoader::get('LOGIN_VENTANA_MINUTOS', '15')));

// Notación para variables globales
$w_error_db = "Error de conexión: ";

// Configuración de sesión basada en variable de entorno
if (session_status() === PHP_SESSION_NONE) {
    ini_set('session.gc_maxlifetime', (string) SESSION_TIMEOUT);
    ini_set('session.cookie_lifetime', (string) SESSION_TIMEOUT);
    $cookiePath = APP_BASE_PATH !== '' ? '/' . APP_BASE_PATH . '/' : '/';
    session_set_cookie_params([
        'lifetime' => SESSION_TIMEOUT,
        'path' => $cookiePath,
        'httponly' => true,
        'samesite' => 'Lax',
        'secure' => APP_ENV === 'production' && !empty($_SERVER['HTTPS']),
    ]);
}
?>
