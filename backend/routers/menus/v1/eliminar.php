<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Eliminar menú",
 *   "tags": ["Menús"],
 *   "requestBody": {
 *     "required": ["id_menu"],
 *     "properties": {
 *       "id_menu": { "type": "string" }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Menú eliminado", "dataSchema": { "$ref": "#/components/schemas/MessageData" } }
 *   }
 * }
 */
require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/middleware/require_session.php';
require_once dirname(__DIR__, 3) . '/middleware/require_admin.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$raw = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : $_POST;
if (!is_array($json)) {
    $json = $_POST;
}

$id = trim((string) ($json['id_menu'] ?? $json['hid_id_menu'] ?? ''));

try {
    global $stmt_del_menu;
    $stmt_del_menu->execute([$id]);
    $res = (string) $stmt_del_menu->fetchColumn();

    if (strpos($res, 'OK') === false) {
        if (stripos($res, 'tab_menu_usuarios') !== false) {
            RouterResponse::fail('No se puede eliminar: el menú está asignado a usuarios. Primero desasígnelo en Accesos.');
        }
        RouterResponse::fail('Error: ' . $res);
    }

    RouterResponse::ok(['message' => 'Menú eliminado correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
