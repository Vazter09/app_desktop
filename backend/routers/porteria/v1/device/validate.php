<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Validar token de dispositivo",
 *   "tags": ["Portería"],
 *   "responses": {
 *     "200": { "description": "Dispositivo válido", "dataSchema": { "type": "object", "properties": { "id_dispositivo": { "type": "integer" }, "nom_dispositivo": { "type": "string" }, "id_usuario_audit": { "type": "string" }, "id_entrada_default": { "type": "integer", "nullable": true } } } }
 *   }
 * }
 */
require_once dirname(__DIR__, 2) . '/prepare.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$device = porteriaApiRequireDevice();

RouterResponse::ok([
    'id_dispositivo' => (int) $device['id_dispositivo'],
    'nom_dispositivo' => (string) $device['nom_dispositivo'],
    'id_usuario_audit' => (string) $device['id_usuario_audit'],
    'id_entrada_default' => $device['id_entrada_default'] !== null
        ? (int) $device['id_entrada_default']
        : null,
]);
