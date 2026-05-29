<?php
/**
 * CARGADOR DE VARIABLES DE ENTORNO - SistNomina
 * Lee archivo .env y establece constantes de configuración
 */

class EnvLoader {
    private static $loaded = false;

    public static function load($path = '') {
        if (self::$loaded) return;
        
        if (empty($path)) {
            $path = dirname(dirname(__DIR__)) . '/.env';
        }
        
        if (!file_exists($path)) {
            // Usar valores por defecto si .env no existe
            self::setDefaults();
            self::$loaded = true;
            return;
        }

        $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            if (strpos($line, '#') === 0 || strpos(trim($line), '=') === false) continue;
            
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);
            
            // Remover comillas si existen
            if ((strpos($value, '"') === 0 && strrpos($value, '"') === strlen($value) - 1) ||
                (strpos($value, "'") === 0 && strrpos($value, "'") === strlen($value) - 1)) {
                $value = substr($value, 1, -1);
            }
            
            // Establecer como variable de entorno
            if (!isset($_ENV[$key])) {
                putenv("$key=$value");
                $_ENV[$key] = $value;
            }
        }
        
        self::$loaded = true;
    }

    private static function setDefaults() {
        $defaults = [
            'DB_HOST' => 'localhost',
            'DB_PORT' => '5432',
            'DB_NAME' => 'db_smartcset',
            'DB_USER' => 'postgres',
            'DB_PASS' => 'postgres123',
            'COLOR_VERDE_OSCURO' => '#2E4731',
            'COLOR_VERDE_OLIVA' => '#6B8E23',
            'PATH_LOGO' => 'img/logo-sena.png',
            'SESSION_TIMEOUT' => '1800',
            'APP_ENV' => 'development'
        ];
        
        foreach ($defaults as $key => $value) {
            if (!isset($_ENV[$key])) {
                putenv("$key=$value");
                $_ENV[$key] = $value;
            }
        }
    }

    public static function get($key, $default = null) {
        return $_ENV[$key] ?? getenv($key) ?: $default;
    }
}
?>
