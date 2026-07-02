<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/middleware/require_session.php';

// Acceso: admin O usuario con menú 0603 (Sesiones Activas) asignado
$_stmt_acceso = $pdo->prepare(
    'SELECT 1 FROM tab_menu_usuarios WHERE id_usuario = ?::VARCHAR AND id_menu = ?'
);
$_stmt_acceso->execute([$_SESSION['id_usuario'], '0603']);
if (empty($_SESSION['ind_usuario']) && !$_stmt_acceso->fetch()) {
    RouterResponse::fail('No tienes permiso para esta acción.', 403);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$raw  = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : null;
$data = is_array($json) ? $json : $_POST;

$id_sesion = trim((string) ($data['id_sesion'] ?? ''));

if ($id_sesion === '') {
    RouterResponse::fail('ID de sesión requerido.');
}

// No permitir cerrar la propia sesión desde aquí
if ($id_sesion === ($_SESSION['id_sesion'] ?? '')) {
    RouterResponse::fail('No puedes cerrar tu propia sesión desde esta herramienta.');
}

try {
    global $pdo;
    $stmt = $pdo->prepare("SELECT fun_siem_forzar_cierre_sesion(?::TEXT, ?::TEXT)");
    $stmt->execute([$id_sesion, $_SESSION['id_usuario']]);
    RouterResponse::ok(['mensaje' => 'Sesión cerrada correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
