<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Exportar asistencia por ficha a Excel",
 *   "description": "Descarga un archivo .xlsx con metadatos de la ficha y el detalle de asistencia del período consultado (máx. 31 días).",
 *   "tags": ["Instructor"],
 *   "parameters": [
 *     { "name": "id_ficha", "in": "query", "required": true, "schema": { "type": "integer", "minimum": 1 } },
 *     { "name": "fecha", "in": "query", "schema": { "type": "string", "format": "date" } },
 *     { "name": "desde", "in": "query", "schema": { "type": "string", "format": "date" } },
 *     { "name": "hasta", "in": "query", "schema": { "type": "string", "format": "date" } }
 *   ],
 *   "responses": {
 *     "200": { "description": "Archivo Excel (.xlsx)" }
 *   }
 * }
 */
require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 4) . '/core/XlsxWriter.php';
require_once dirname(__DIR__, 4) . '/middleware/require_instructor.php';
require_once dirname(__DIR__, 4) . '/services/instructor/asistencia_service.php';

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
    $desde = $rango['desde'];
    $hasta = $rango['hasta'];

    $modoRango = isset($_GET['desde'], $_GET['hasta'])
        && trim((string) $_GET['desde']) !== ''
        && trim((string) $_GET['hasta']) !== ''
        && trim((string) ($_GET['desde'] ?? '')) !== trim((string) ($_GET['hasta'] ?? ''));

    $asistencia = instructorListarAsistenciaPorContexto(
        $stmt_fun_listar_asistencia_ficha,
        $stmt_fun_listar_asistencia_ficha_admin,
        $ctx,
        $idFicha,
        $desde,
        $hasta
    );

    $meta = instructorObtenerMetadatosFichaExport($pdo, $idFicha);
    $export = instructorConstruirFilasExportacion($asistencia, $meta, $modoRango);

    $writer = new XlsxWriter();
    $writer->addSheet('Detalle', $export['detalle'], $export['detalle_bold_rows']);

    if (is_array($export['resumen']) && $export['resumen'] !== []) {
        $writer->addSheet('Resumen', $export['resumen'], $export['resumen_bold_rows']);
    }

    $filename = $desde === $hasta
        ? 'asistencia_ficha_' . $idFicha . '_' . $desde . '.xlsx'
        : 'asistencia_ficha_' . $idFicha . '_' . $desde . '_' . $hasta . '.xlsx';

    $writer->output($filename);
} catch (InvalidArgumentException $e) {
    RouterResponse::fail($e->getMessage());
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
