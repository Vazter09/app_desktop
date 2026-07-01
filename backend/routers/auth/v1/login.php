<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Iniciar sesión web",
 *   "description": "Acepta JSON o form-urlencoded. Crea sesión PHP y cookie PHPSESSID.",
 *   "tags": ["Auth"],
 *   "security": [],
 *   "requestBody": {
 *     "required": true,
 *     "oneOf": [
 *       { "type": "object", "required": ["usuario", "clave"], "properties": { "usuario": { "type": "string" }, "clave": { "type": "string", "format": "password" } } }
 *     ]
 *   },
 *   "responses": {
 *     "200": { "description": "Login exitoso", "dataSchema": { "type": "object", "properties": { "redirect": { "type": "string" }, "usuario": { "$ref": "#/components/schemas/UsuarioLogin" } } } }
 *   }
 * }
 */
require_once dirname(__DIR__, 3) . '/core/prepare_login.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/core/lib/acceso_sesion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$raw = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : [];
if (!is_array($json)) {
    $json = [];
}

$usuario = trim((string) ($json['usuario'] ?? $_POST['txt_usuario'] ?? ''));
$clave = (string) ($json['clave'] ?? $_POST['txt_clave'] ?? '');

if ($usuario === '' || $clave === '') {
    RouterResponse::fail('ID de usuario y contraseña son obligatorios.');
}

try {
    $stmt_login->execute([$usuario]);
    $reg = $stmt_login->fetch();

    if (!$reg) {
        RouterResponse::fail('ID de usuario o contraseña incorrectos.');
    }

    if ($reg['ind_estado'] == false) {
        RouterResponse::fail('ACCESO DENEGADO: Su usuario se encuentra inhabilitado por el administrador.');
    }

    if (!password_verify($clave, $reg['pass_usuario'])) {
        RouterResponse::fail('ID de usuario o contraseña incorrectos.');
    }

    $ip = smartcsetClientIp();
    $timeoutSesion = !empty($reg['ind_usuario']) ? SESSION_TIMEOUT : 0;
    $idSesion = accesoIngresoSesion(
        $stmt_fun_ingreso_sesion,
        (string) $reg['id_usuario'],
        $ip,
        $timeoutSesion
    );

    session_regenerate_id(true);

    $_SESSION['id_usuario'] = $reg['id_usuario'];
    $_SESSION['nom_usuario'] = $reg['nom_usuario'];
    $_SESSION['ind_usuario'] = smartcsetPgBool($reg['ind_usuario']);
    $_SESSION['id_sesion'] = $idSesion;

    RouterResponse::ok([
        'redirect' => smartcsetUrl('/pages/menu/menu_principal.php'),
        'usuario' => [
            'id' => (string) $reg['id_usuario'],
            'nombre' => (string) $reg['nom_usuario'],
            'admin' => !empty($reg['ind_usuario']),
        ],
    ]);
} catch (PDOException $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
