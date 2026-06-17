<?php
session_start();
require_once __DIR__ . '/../core/prepare.php';

try {
    if (!empty($_SESSION['id_sesion'])) {
        accesoSalidaSesion(
            $stmt_fun_salida_sesion,
            (int) $_SESSION['id_sesion'],
            ACCESO_SESION_CIERRE_LOGOUT,
            (string) ($_SESSION['id_usuario'] ?? '')
        );
    }
} catch (Exception $e) {
    error_log('LOGOUT ERROR: ' . $e->getMessage());
}

session_unset();
session_destroy();

header('Location: ../../index.php');
exit();
