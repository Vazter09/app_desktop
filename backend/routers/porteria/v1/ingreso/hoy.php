<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Listar ingresos de hoy",
 *   "tags": ["Portería"],
 *   "responses": {
 *     "200": { "description": "Ingresos del día", "dataSchema": { "type": "object", "properties": { "items": { "type": "array", "items": { "type": "object" } } } } }
 *   }
 * }
 */
require_once dirname(__DIR__, 2) . '/prepare.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session_or_device.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

porteriaRequireSessionOrDevice();

try {
    RouterResponse::ok(['items' => porteriaApiListIngresosHoy()]);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
