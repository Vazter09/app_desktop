<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/prepare.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session_or_device.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$auth = porteriaRequireSessionOrDevice();
$device = ($auth['type'] ?? '') === 'device'
    ? $auth['row']
    : ['id_usuario_audit' => porteriaAuthAuditUser($auth), 'usr_audit' => porteriaAuthAuditUser($auth)];
$json = PorteriaRouterPayload::readJsonBody();

try {
    $result = porteriaApiRegistrarIngreso($device, $json);
    RouterResponse::ok($result);
} catch (PDOException $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
