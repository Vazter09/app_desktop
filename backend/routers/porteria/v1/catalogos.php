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

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

porteriaApiRequireDevice();

try {
    RouterResponse::ok(porteriaApiCatalogos());
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
