<?php
session_start();
require_once(__DIR__ . '/../core/prepare.php');

try {
    if (isset($_SESSION['id_usuario'])) {
        // Usamos el stmt centralizado de prepare.php para eliminar la sesión
        $stmt_del_sesion->execute([$_SESSION['id_usuario']]);
    }
}
catch (Exception $e) {
    // Registrar error en log (opcional pero recomendado)
    error_log("LOGOUT ERROR para usuario " . ($_SESSION['id_usuario'] ?? 'desconocido') . ": " . $e->getMessage());
}

// Destruimos la sesión de PHP
session_unset();
session_destroy();

// Saltamos a la raíz (donde está el index.php)
header("Location: ../../index.php");
exit();