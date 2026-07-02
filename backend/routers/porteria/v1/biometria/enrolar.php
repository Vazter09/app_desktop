<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Enrolar biometría facial (app desktop de portería)",
 *   "tags": ["Portería", "Biometría"],
 *   "requestBody": {
 *     "schema": { "type": "object", "properties": {
 *       "documento": { "type": "string" },
 *       "vector_facial": { "type": "array", "items": { "type": "number" }, "minItems": 512, "maxItems": 512 },
 *       "foto_base64": { "type": "string" },
 *       "calidad_facial": { "type": "number" }
 *     }, "required": ["documento", "vector_facial"] }
 *   },
 *   "responses": {
 *     "200": { "description": "Biometría enrolada", "dataSchema": { "type": "object", "properties": { "id_persona": { "type": "integer" } } } }
 *   }
 * }
 */
require_once dirname(__DIR__, 2) . '/prepare.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session_or_device.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$auth = porteriaRequireSessionOrDevice();
if (($auth['type'] ?? '') !== 'device') {
    RouterResponse::unauthorized('Solo dispositivos autorizados pueden enrolar biometría.');
}

$json = PorteriaRouterPayload::readJsonBody();

try {
    $result = porteriaApiEnrolarBiometria($auth['row'], $json);
    RouterResponse::ok($result);
} catch (PDOException $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
