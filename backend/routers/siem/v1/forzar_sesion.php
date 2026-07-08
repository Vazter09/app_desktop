<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/core/lib/acceso_sesion.php';
require_once dirname(__DIR__, 3) . '/middleware/require_session.php';

// Acceso: admin O usuario con menú 21103 (Sesiones Activas) asignado
if (!usuarioTieneMenu($pdo, (string) $_SESSION['id_usuario'], '21103')) {
    RouterResponse::fail('No tienes permiso para esta acción.', 403);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$raw  = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : $_POST;
if (!is_array($json)) {
    $json = $_POST;
}

$idSesion = (int) ($json['id_sesion'] ?? $json['hid_id_sesion'] ?? 0);

if ($idSesion < 1) {
    RouterResponse::fail('ID de sesión requerido.');
}

// No permitir cerrar la propia sesión desde aquí
if ($idSesion === (int) ($_SESSION['id_sesion'] ?? 0)) {
    RouterResponse::fail('No puedes cerrar tu propia sesión desde esta herramienta.');
}

try {
    accesoSalidaSesion(
        $stmt_fun_salida_sesion,
        $idSesion,
        ACCESO_SESION_CIERRE_ADMIN,
        (string) $_SESSION['id_usuario']
    );
    RouterResponse::ok(['message' => 'Sesión cerrada correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
