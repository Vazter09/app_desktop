<?php
/**
 * Gestión de sesión y autenticación
 * Sistema CSET
 */

session_start();

define('APP_USER', 'usuariocset');
define('APP_PASS', 'usuariocset');

/**
 * Verifica si el usuario está autenticado, si no redirige al login
 */
function requireAuth(): void {
    if (!isset($_SESSION['authenticated']) || $_SESSION['authenticated'] !== true) {
        header('Location: login.php');
        exit;
    }
}

/**
 * Intenta autenticar al usuario con las credenciales dadas
 */
function authenticate(string $user, string $pass): bool {
    if ($user === APP_USER && $pass === APP_PASS) {
        $_SESSION['authenticated'] = true;
        $_SESSION['username']      = $user;
        $_SESSION['login_time']    = time();
        return true;
    }
    return false;
}

/**
 * Cierra la sesión activa
 */
function logout(): void {
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $p = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000,
            $p['path'], $p['domain'], $p['secure'], $p['httponly']);
    }
    session_destroy();
    header('Location: login.php');
    exit;
}
