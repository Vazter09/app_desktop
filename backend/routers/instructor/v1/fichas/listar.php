<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Listar fichas del instructor",
 *   "tags": ["Instructor"],
 *   "responses": {
 *     "200": { "description": "Fichas asignadas", "dataSchema": { "type": "object", "properties": { "fichas": { "type": "array", "items": { "type": "object" } }, "modo": { "type": "string" } } } }
 *   }
 * }
 */
require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 4) . '/middleware/require_instructor.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

$ctx = instructorRequireContext();

try {
    $fichas = instructorListarFichasPorContexto(
        $stmt_fun_listar_fichas_instructor,
        $stmt_fun_listar_fichas_admin,
        $ctx
    );
    RouterResponse::ok([
        'fichas' => $fichas,
        'modo' => $ctx['modo'],
    ]);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
