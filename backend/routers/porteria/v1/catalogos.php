<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Catálogos portería (tipos doc, persona, entradas)",
 *   "tags": ["Portería"],
 *   "responses": {
 *     "200": { "description": "Catálogos del centro", "dataSchema": { "type": "object", "additionalProperties": true } }
 *   }
 * }
 */
require_once dirname(__DIR__) . '/prepare.php';
require_once dirname(__DIR__, 3) . '/middleware/require_session_or_device.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

porteriaRequireSessionOrDevice();

try {
    RouterResponse::ok(porteriaApiCatalogos());
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
