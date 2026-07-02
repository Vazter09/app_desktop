<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/middleware/require_session.php';

// Acceso: admin O usuario con menú 0604 (IPs Bloqueadas) asignado
$_stmt_acceso = $pdo->prepare(
    'SELECT 1 FROM tab_menu_usuarios WHERE id_usuario = ?::VARCHAR AND id_menu = ?'
);
$_stmt_acceso->execute([$_SESSION['id_usuario'], '0604']);
if (empty($_SESSION['ind_usuario']) && !$_stmt_acceso->fetch()) {
    RouterResponse::fail('No tienes permiso para esta acción.', 403);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$raw  = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : null;
$data = is_array($json) ? $json : $_POST;

$ip_cliente = trim((string) ($data['ip_cliente'] ?? ''));

if ($ip_cliente === '') {
    RouterResponse::fail('IP requerida.');
}

try {
    global $pdo;
    $stmt = $pdo->prepare("SELECT fun_siem_desbloquear_ip(?::TEXT, ?::TEXT)");
    $stmt->execute([$ip_cliente, $_SESSION['id_usuario']]);
    RouterResponse::ok(['mensaje' => 'IP desbloqueada correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
