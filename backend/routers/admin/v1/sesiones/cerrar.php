<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Cerrar sesión activa (admin)",
 *   "tags": ["Admin"],
 *   "requestBody": {
 *     "required": ["id_sesion"],
 *     "properties": {
 *       "id_sesion": { "type": "integer", "minimum": 1 }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Sesión cerrada", "dataSchema": { "$ref": "#/components/schemas/MessageData" } }
 *   }
 * }
 */
require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 4) . '/core/lib/acceso_sesion.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session.php';
require_once dirname(__DIR__, 4) . '/middleware/require_admin.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$raw = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : $_POST;
if (!is_array($json)) {
    $json = $_POST;
}

$idSesion = (int) ($json['id_sesion'] ?? $json['hid_id_sesion'] ?? 0);

try {
    if ($idSesion < 1) {
        RouterResponse::fail('Debe indicar la sesión a cerrar.');
    }

    accesoSalidaSesion(
        $stmt_fun_salida_sesion,
        $idSesion,
        ACCESO_SESION_CIERRE_ADMIN,
        (string) $_SESSION['id_usuario']
    );

    RouterResponse::ok(['message' => 'Sesión #' . $idSesion . ' cerrada correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
