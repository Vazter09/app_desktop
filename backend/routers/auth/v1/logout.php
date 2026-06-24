<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/helpers.php';
require_once dirname(__DIR__, 3) . '/core/lib/acceso_sesion.php';

try {
    if (!empty($_SESSION['id_sesion'])) {
        accesoSalidaSesion(
            $stmt_fun_salida_sesion,
            (int) $_SESSION['id_sesion'],
            ACCESO_SESION_CIERRE_LOGOUT,
            (string) ($_SESSION['id_usuario'] ?? '')
        );
    }
} catch (Throwable $e) {
    error_log('LOGOUT ERROR: ' . $e->getMessage());
}

session_unset();
session_destroy();

header('Location: ' . smartcsetUrl('/index.php'));
exit;
