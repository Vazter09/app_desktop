<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Health check API portería",
 *   "tags": ["Portería"],
 *   "security": [],
 *   "responses": {
 *     "200": { "description": "Servicio activo", "dataSchema": { "type": "object", "properties": { "service": { "type": "string" }, "version": { "type": "string" }, "time": { "type": "string", "format": "date-time" }, "api_enabled": { "type": "boolean" } } } }
 *   }
 * }
 */
require_once dirname(__DIR__) . '/prepare.php';

RouterResponse::ok([
    'service' => 'smartcset-porteria-api',
    'version' => 'v1',
    'time' => date('c'),
    'api_enabled' => PorteriaRouterAuth::isEnabled(),
]);
