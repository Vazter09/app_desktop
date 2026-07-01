<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Crear o actualizar usuario",
 *   "tags": ["Usuarios"],
 *   "requestBody": {
 *     "required": ["id_usuario", "nom_usuario"],
 *     "properties": {
 *       "id_usuario": { "type": "string" },
 *       "nom_usuario": { "type": "string" },
 *       "mail_usuario": { "type": "string", "format": "email" },
 *       "pass_usuario": { "type": "string", "format": "password" },
 *       "admin": { "type": "boolean" },
 *       "estado": { "type": "boolean" }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Usuario guardado", "dataSchema": { "$ref": "#/components/schemas/MessageData" } }
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

try {
    global $stmt_login, $stmt_fun_ins_user, $stmt_fun_upd_user;

    $id = trim((string) ($json['id_usuario'] ?? $json['txt_id_usuario'] ?? ''));
    $nom = trim((string) ($json['nom_usuario'] ?? $json['txt_nom_usuario'] ?? ''));
    $mail = trim((string) ($json['mail_usuario'] ?? $json['txt_mail_usuario'] ?? ''));
    $pass = (string) ($json['pass_usuario'] ?? $json['txt_pass_usuario'] ?? '');
    $admin = !empty($json['admin']) || !empty($json['chk_admin']) ? 'true' : 'false';
    $estado = !empty($json['estado']) || !empty($json['chk_estado']) ? 'true' : 'false';

    if ($id === '' || $nom === '') {
        RouterResponse::fail('ID y nombre de usuario son obligatorios.');
    }

    $stmt_login->execute([$id]);
    $actual = $stmt_login->fetch();

    if ($actual) {
        validarLongitudPassword($pass, false);
        $passHash = $pass !== '' ? password_hash($pass, PASSWORD_BCRYPT) : $actual['pass_usuario'];
        $stmt_fun_upd_user->execute([$id, $nom, $passHash, $mail, $admin, $estado]);
        $res = (string) $stmt_fun_upd_user->fetchColumn();
    } else {
        validarLongitudPassword($pass, true);
        $passHash = password_hash($pass, PASSWORD_BCRYPT);
        $stmt_fun_ins_user->execute([$id, $nom, $passHash, $mail, $admin, $estado]);
        $res = (string) $stmt_fun_ins_user->fetchColumn();
    }

    if (strpos($res, 'OK') === false) {
        RouterResponse::fail('Error: ' . $res);
    }

    RouterResponse::ok(['message' => 'Usuario guardado correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
