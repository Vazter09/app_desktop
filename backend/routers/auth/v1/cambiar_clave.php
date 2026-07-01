<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Cambiar contraseña autenticado",
 *   "tags": ["Auth"],
 *   "requestBody": {
 *     "required": ["pass_antigua", "pass_nueva"],
 *     "properties": {
 *       "pass_antigua": { "type": "string", "format": "password" },
 *       "pass_nueva": { "type": "string", "format": "password", "minLength": 12 }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Contraseña actualizada", "dataSchema": { "$ref": "#/components/schemas/MessageData" } }
 *   }
 * }
 */
require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/middleware/require_session.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$raw = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : $_POST;
if (!is_array($json)) {
    $json = $_POST;
}

$idUsuario = (string) $_SESSION['id_usuario'];
$passAntigua = (string) ($json['pass_antigua'] ?? $json['wpass_antigua'] ?? '');
$passNueva = (string) ($json['pass_nueva'] ?? $json['wpass_nueva'] ?? '');

try {
    validarLongitudPassword($passNueva, true);

    $stmt = $pdo->prepare('SELECT pass_usuario FROM tab_usuarios WHERE id_usuario = ?');
    $stmt->execute([$idUsuario]);
    $hashActual = $stmt->fetchColumn();

    if (!$hashActual || !password_verify($passAntigua, (string) $hashActual)) {
        RouterResponse::fail('La contraseña anterior es incorrecta.');
    }

    $nuevoHash = password_hash($passNueva, PASSWORD_BCRYPT);
    $stmtFn = $pdo->prepare('SELECT fun_actualizar_password(CAST(? AS TEXT), CAST(? AS TEXT))');
    $stmtFn->execute([$idUsuario, $nuevoHash]);
    $res = $stmtFn->fetchColumn();

    if ($res !== 'OK') {
        RouterResponse::fail('Error del motor: ' . $res);
    }

    RouterResponse::ok(['message' => 'Su contraseña ha sido actualizada.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
