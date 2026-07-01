<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Actualizar asistencia manual",
 *   "description": "Solo instructor con permiso de escritura.",
 *   "tags": ["Instructor"],
 *   "method": "PUT",
 *   "requestBody": {
 *     "required": ["id_aprendiz", "fec_asistencia"],
 *     "schema": {
 *       "type": "object",
 *       "required": ["id_aprendiz", "fec_asistencia"],
 *       "properties": {
 *         "id_aprendiz": { "type": "integer", "minimum": 1 },
 *         "fec_asistencia": { "type": "string", "format": "date" },
 *         "ind_asistencia": { "type": "string" },
 *         "observacion": { "type": "string" }
 *       }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Asistencia actualizada", "dataSchema": { "$ref": "#/components/schemas/MessageData" } }
 *   }
 * }
 */
require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 4) . '/middleware/require_instructor.php';
require_once dirname(__DIR__, 4) . '/routers/porteria/_lib/Payload.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    RouterResponse::fail('Método no permitido.', 405);
}

$ctx = instructorRequireContext();

try {
    instructorRequireWriteAccess($ctx);
} catch (RuntimeException $e) {
    RouterResponse::fail($e->getMessage(), 403);
}

$idInstructor = (int) ($ctx['id_instructor'] ?? 0);
$json = PorteriaRouterPayload::readJsonBody();

try {
    $idAprendiz = (int) ($json['id_aprendiz'] ?? 0);
    $fecha = trim((string) ($json['fec_asistencia'] ?? ''));
    if ($fecha === '' || !instructorExisteRegistroAsistencia($pdo, $idAprendiz, $fecha)) {
        RouterResponse::fail('No hay registro de asistencia para actualizar en la fecha indicada.');
    }

    instructorActualizarAsistenciaManual(
        $stmt_fun_guardar_asistencia_manual,
        $idInstructor,
        $json,
        (string) $ctx['id_usuario']
    );

    RouterResponse::ok(['message' => 'Asistencia actualizada correctamente.']);
} catch (InvalidArgumentException $e) {
    RouterResponse::fail($e->getMessage());
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
