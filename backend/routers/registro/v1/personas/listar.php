<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Listar personas por tipo",
 *   "tags": ["Registro"],
 *   "parameters": [
 *     { "name": "tipo", "in": "query", "required": true, "schema": { "type": "integer", "minimum": 1, "maximum": 4 } }
 *   ],
 *   "responses": {
 *     "200": { "description": "Listado de personas", "dataSchema": { "type": "object", "properties": { "personas": { "type": "array", "items": { "type": "object" } } } } }
 *   }
 * }
 */
require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/middleware/require_registro_session.php';
require_once dirname(__DIR__, 4) . '/services/registro/personas_list.php';
require_once dirname(__DIR__, 4) . '/services/registro/access.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

$tipo = trim((string) ($_GET['tipo'] ?? ''));
if ($tipo === '' || !ctype_digit($tipo)) {
    RouterResponse::fail('Parámetro tipo inválido.');
}

$tipoNum = (int) $tipo;
if ($tipoNum < 1 || $tipoNum > 4) {
    RouterResponse::fail('Tipo fuera de rango.');
}

try {
    RouterResponse::ok(['personas' => registroFetchPersonasPorTipo($pdo, $tipoNum)]);
} catch (Throwable $e) {
    RouterResponse::fail('Error al cargar personas.', 500);
}
