<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Registrar salida manual",
 *   "tags": ["Portería"],
 *   "requestBody": {
 *     "schema": { "type": "object", "additionalProperties": true, "description": "Payload de salida (documento, id_ingreso, etc.)" }
 *   },
 *   "responses": {
 *     "200": { "description": "Salida registrada", "dataSchema": { "type": "object", "properties": { "id_ingreso": { "type": "integer" } } } }
 *   }
 * }
 */
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
    $result = porteriaApiRegistrarSalida($device, $json);
    RouterResponse::ok($result);
} catch (PDOException $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
