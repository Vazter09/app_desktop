<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Actualizar captura biométrica del ingreso abierto",
 *   "tags": ["Portería"],
 *   "requestBody": {
 *     "schema": { "type": "object", "additionalProperties": true }
 *   },
 *   "responses": {
 *     "200": { "description": "Captura actualizada", "dataSchema": { "type": "object", "properties": { "id_ingreso": { "type": "integer" }, "accion": { "type": "string" } } } }
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
    global $pdo, $stmt_fun_actualizar_captura_ingreso, $stmt_buscar_ingreso_abierto;

    $post = PorteriaRouterPayload::ingresoToPost($json);
    if (isset($json['embedding']) && is_array($json['embedding'])) {
        $post['embedding'] = $json['embedding'];
    }
    if (isset($json['huella_template_b64']) && is_string($json['huella_template_b64'])) {
        $post['huella_template_b64'] = trim($json['huella_template_b64']);
    }

    $usrAudit = (string) ($device['id_usuario_audit'] ?? $device['usr_audit'] ?? 'system');
    $pdo->exec('SET app.usuario = ' . $pdo->quote($usrAudit));

    $idIngreso = ingresoActualizarCapturaAbierto(
        $stmt_fun_actualizar_captura_ingreso,
        $stmt_buscar_ingreso_abierto,
        $post
    );

    RouterResponse::ok([
        'id_ingreso' => $idIngreso,
        'accion' => 'captura_actualizada',
    ]);
} catch (PDOException $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
