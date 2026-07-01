<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Eliminar entrada del centro",
 *   "tags": ["Entradas"],
 *   "requestBody": {
 *     "required": ["id_entrada"],
 *     "properties": {
 *       "id_entrada": { "type": "integer", "minimum": 1 }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Entrada eliminada", "dataSchema": { "$ref": "#/components/schemas/MessageData" } }
 *   }
 * }
 */
require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/middleware/require_session.php';
require_once dirname(__DIR__, 3) . '/middleware/require_admin.php';
require_once dirname(__DIR__, 3) . '/services/entradas/entrada_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$raw = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : $_POST;
if (!is_array($json)) {
    $json = $_POST;
}

$id = (int) ($json['id_entrada'] ?? $json['hid_id_entrada'] ?? 0);

try {
    global $stmt_fun_delete_entrada;
    entradasEliminar($stmt_fun_delete_entrada, $id);
    RouterResponse::ok(['message' => 'Entrada eliminada correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
