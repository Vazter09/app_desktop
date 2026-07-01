<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Recuperar contraseña",
 *   "tags": ["Auth"],
 *   "security": [],
 *   "requestBody": {
 *     "required": ["usuario"],
 *     "properties": {
 *       "usuario": { "type": "string" },
 *       "metodo": { "type": "string", "enum": ["correo", "pantalla"], "default": "correo" },
 *       "correo": { "type": "string", "format": "email" }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Clave temporal generada o enviada", "dataSchema": { "$ref": "#/components/schemas/MessageData" } }
 *   }
 * }
 */
require_once dirname(__DIR__, 3) . '/core/prepare_login.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$raw = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : $_POST;
if (!is_array($json)) {
    $json = $_POST;
}

$idUsuario = trim((string) ($json['usuario'] ?? $json['txt_usuario'] ?? ''));
$metodo = trim((string) ($json['metodo'] ?? $json['rdo_metodo'] ?? 'correo'));
$correo = trim((string) ($json['correo'] ?? $json['txt_correo'] ?? ''));

if ($idUsuario === '') {
    RouterResponse::fail('Debe indicar el ID de usuario.');
}

$passTemp = substr(str_shuffle('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'), 0, 12);
$passHash = password_hash($passTemp, PASSWORD_BCRYPT);

try {
    global $stmt_valida_mail, $stmt_upd_pass, $stmt_login;

    if ($metodo === 'correo') {
        $stmt_valida_mail->execute([$idUsuario, $correo]);
        if (!$stmt_valida_mail->fetch()) {
            RouterResponse::fail('El usuario o correo no coinciden.');
        }
        $stmt_upd_pass->execute([$passHash, $idUsuario]);
        RouterResponse::ok(['message' => 'Se ha enviado la clave temporal a su correo.']);
    } else {
        $stmt_login->execute([$idUsuario]);
        $usr = $stmt_login->fetch();
        if (!$usr || empty($usr['ind_estado'])) {
            RouterResponse::fail('El usuario no existe o está inactivo.');
        }
        $stmt_upd_pass->execute([$passHash, $idUsuario]);
        RouterResponse::ok([
            'message' => 'Clave generada correctamente.',
            'clave_temporal' => $passTemp,
            'mostrar_pantalla' => true,
        ]);
    }
} catch (Throwable $e) {
    RouterResponse::fail($e->getMessage());
}
