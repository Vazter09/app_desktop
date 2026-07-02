<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Listar asistencia por ficha y rango de fechas",
 *   "tags": ["Instructor"],
 *   "parameters": [
 *     { "name": "id_ficha", "in": "query", "required": true, "schema": { "type": "integer", "minimum": 1 } },
 *     { "name": "fecha", "in": "query", "schema": { "type": "string", "format": "date" } },
 *     { "name": "desde", "in": "query", "schema": { "type": "string", "format": "date" } },
 *     { "name": "hasta", "in": "query", "schema": { "type": "string", "format": "date" } }
 *   ],
 *   "responses": {
 *     "200": { "description": "Listado de asistencia", "dataSchema": { "type": "object", "additionalProperties": true } }
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
$idFicha = (int) ($_GET['id_ficha'] ?? 0);

if ($idFicha < 1) {
    RouterResponse::fail('Debe indicar la ficha.');
}

try {
    if (!instructorPuedeAccederFicha(
        $pdo,
        $stmt_fun_listar_fichas_instructor,
        $stmt_fun_listar_fichas_admin,
        $ctx,
        $idFicha
    )) {
        RouterResponse::fail('No tiene acceso a la ficha seleccionada.', 403);
    }

    $rango = instructorNormalizarRangoFechas($_GET);
    $data = instructorListarAsistenciaPorContexto(
        $stmt_fun_listar_asistencia_ficha,
        $stmt_fun_listar_asistencia_ficha_admin,
        $ctx,
        $idFicha,
        $rango['desde'],
        $rango['hasta']
    );

    RouterResponse::ok($data);
} catch (InvalidArgumentException $e) {
    RouterResponse::fail($e->getMessage());
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
