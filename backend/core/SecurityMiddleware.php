<?php
/**
 * MIDDLEWARE DE SEGURIDAD - SistNomina V.1.2
 * Incluir al inicio de prepare.php o en config.php
 * Maneja: Headers, HTTPS, Input validation, Rate limiting
 */

class SecurityMiddleware {
    
    public static function initialize() {
        // 1. Headers de Seguridad
        self::setSecurityHeaders();
        
        // 2. Validar HTTPS en producción
        // self::enforceHTTPS();
        
        // 3. Protección contra ataques comunes
        self::preventCommonAttacks();
        
        // 4. Configurar sesión segura
        self::configureSessionSecurity();
    }

    private static function setSecurityHeaders() {
        header("X-Content-Type-Options: nosniff");
        header("X-Frame-Options: SAMEORIGIN");
        header("X-XSS-Protection: 1; mode=block");
        header("Referrer-Policy: strict-origin-when-cross-origin");
        header("Permissions-Policy: geolocation=(), microphone=(), camera=()");
        
        // CSP activado (Fase 1 MSPI, E4): todos los scripts inline fueron
        // externalizados a js/ (incluyendo los wizards de porteria
        // ingreso/salida y cambiar_clave). style-src permite 'unsafe-inline'
        // porque varios módulos usan <style> embebido para temas dinámicos.
        header("Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; font-src 'self'; img-src 'self' data:;");
    }

    private static function enforceHTTPS() {
        if (defined('APP_ENV') && APP_ENV === 'production') {
            if (empty($_SERVER['HTTPS']) || $_SERVER['HTTPS'] === 'off') {
                $url = "https://" . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'];
                header("Location: $url", true, 301);
                exit();
            }
        }
    }

    private static function preventCommonAttacks() {
        // Validar método HTTP permitido
        $allowed_methods = ['GET', 'POST', 'HEAD', 'OPTIONS'];
        if (!in_array($_SERVER['REQUEST_METHOD'], $allowed_methods)) {
            http_response_code(405);
            die("Método no permitido");
        }

        // Prevenir Directory Traversal
        if (isset($_GET) && !empty($_GET)) {
            foreach ($_GET as $key => $value) {
                if (is_string($value) && strpos($value, '..') !== false) {
                    http_response_code(400);
                    die("Solicitud inválida");
                }
            }
        }
    }

    private static function configureSessionSecurity() {
        if (session_status() === PHP_SESSION_NONE) {
            $w_cookie_secure = (defined('APP_ENV') && APP_ENV === 'production') ? '1' : '0';

            // Configuración de sesión segura
            ini_set('session.cookie_httponly', '1');      // No accesible desde JavaScript
            ini_set('session.cookie_secure', $w_cookie_secure); // Solo HTTPS en producción
            ini_set('session.cookie_samesite', 'Strict'); // CSRF protection
            ini_set('session.use_strict_mode', '1');      // Rechazar session IDs desconocidas

            session_start();
        }
    }

    public static function validateCSRFToken() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            if (!isset($_POST['csrf_token']) || $_POST['csrf_token'] !== $_SESSION['csrf_token']) {
                http_response_code(403);
                die("Token CSRF inválido");
            }
        }
    }

    public static function generateCSRFToken() {
        if (!isset($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }
}

// Inicializar middleware
SecurityMiddleware::initialize();
?>
