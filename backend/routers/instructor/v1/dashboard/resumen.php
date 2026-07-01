<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Resumen dashboard de asistencia",
 *   "tags": ["Instructor"],
 *   "parameters": [
 *     { "name": "fecha", "in": "query", "schema": { "type": "string", "format": "date" } }
 *   ],
 *   "responses": {
 *     "200": { "description": "Resumen por ficha y totales", "dataSchema": { "type": "object", "additionalProperties": true } }
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
$fecha = trim((string) ($_GET['fecha'] ?? ''));

try {
    $fichas = instructorListarFichasPorContexto(
        $stmt_fun_listar_fichas_instructor,
        $stmt_fun_listar_fichas_admin,
        $ctx
    );

    if (($ctx['modo'] ?? '') === 'admin_lectura') {
        RouterResponse::ok([
            'fecha' => $fecha !== '' ? $fecha : date('Y-m-d'),
            'total_fichas' => count($fichas),
            'total_aprendices' => 0,
            'hoy' => [
                'Presente' => 0,
                'Tarde' => 0,
                'Ausente' => 0,
                'Pendiente' => 0,
                'Desconocido' => 0,
                'total' => 0,
            ],
            'por_ficha' => [],
            'modo' => 'admin_lectura',
        ]);
    }

    $resumen = instructorDashboardResumen(
        $stmt_fun_listar_asistencia_ficha,
        $stmt_fun_listar_asistencia_ficha_admin,
        $ctx,
        $fichas,
        $fecha
    );
    $resumen['modo'] = $ctx['modo'];

    RouterResponse::ok($resumen);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
