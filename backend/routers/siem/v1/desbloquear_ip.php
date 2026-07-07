<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/middleware/require_session.php';

// Acceso: admin O usuario con menú 21104 (IPs Bloqueadas) asignado
if (!usuarioTieneMenu($pdo, (string) $_SESSION['id_usuario'], '21104')) {
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
