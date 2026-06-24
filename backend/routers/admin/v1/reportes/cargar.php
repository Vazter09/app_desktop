<?php
declare(strict_types=1);

/**
 * Recibe el archivo de un reporte SENA (.xlsx / .csv) y lo guarda en storage.
 * No procesa ni TRUNCA tab_temp_* todavía: el procesamiento se habilitará tras
 * validar el layout real del archivo (evita destruir datos con un mapeo errado).
 */

require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session.php';
require_once dirname(__DIR__, 4) . '/middleware/require_admin.php';
require_once dirname(__DIR__, 4) . '/services/reportes/reportes_catalogo.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

try {
    $key = (string) ($_POST['reporte'] ?? '');
    $rep = reportesGet($key);
    if ($rep === null) {
        RouterResponse::fail('Reporte no válido.');
    }

    $file = $_FILES['archivo'] ?? null;
    $err = is_array($file) ? (int) ($file['error'] ?? UPLOAD_ERR_NO_FILE) : UPLOAD_ERR_NO_FILE;
    if ($err === UPLOAD_ERR_NO_FILE) {
        RouterResponse::fail('No se recibió ningún archivo.');
    }
    if ($err !== UPLOAD_ERR_OK) {
        RouterResponse::fail('Error al subir el archivo (código ' . $err . ').');
    }
    if (!is_uploaded_file((string) $file['tmp_name'])) {
        RouterResponse::fail('Archivo inválido.');
    }

    $ext = strtolower(pathinfo((string) ($file['name'] ?? ''), PATHINFO_EXTENSION));
    if (!in_array($ext, ['xlsx', 'csv'], true)) {
        RouterResponse::fail('Formato no permitido. Use .xlsx o .csv.');
    }

    $maxBytes = 20 * 1024 * 1024;
    if ((int) ($file['size'] ?? 0) > $maxBytes) {
        RouterResponse::fail('El archivo supera el tamaño máximo (20 MB).');
    }

    $root = dirname(__DIR__, 5);
    $dir = $root . '/storage/reportes/' . $key;
    if (!is_dir($dir) && !mkdir($dir, 0775, true) && !is_dir($dir)) {
        RouterResponse::fail('No se pudo preparar el almacenamiento.');
    }

    $safeName = $key . '_' . date('Ymd_His') . '.' . $ext;
    $dest = $dir . '/' . $safeName;
    if (!move_uploaded_file((string) $file['tmp_name'], $dest)) {
        RouterResponse::fail('No se pudo guardar el archivo.');
    }

    // TODO(backend): conectar el procesamiento del archivo a la base de datos.
    //   1. Parsear $dest según $ext: .csv con fgetcsv; .xlsx con lector puro PHP (ZipArchive + XML).
    //   2. Validar el layout contra $rep (filas de encabezado a saltar y orden de columnas).
    //   3. En una transacción: TRUNCATE {$rep['tabla']} e INSERT de las filas parseadas.
    //   4. Si el reporte tiene función de proceso (df49/pe04/aprendices/fichas/juicios),
    //      ejecutar su fun_procesar_* hacia las tablas finales.
    //   5. Devolver totales (cargados / procesados) en el mensaje de respuesta.
    //   Bloqueado hasta tener un archivo de ejemplo: un mapeo errado + TRUNCATE borraría datos.

    $kb = max(1, (int) round(((int) ($file['size'] ?? 0)) / 1024));
    RouterResponse::ok([
        'message' => 'Archivo recibido: ' . htmlspecialchars((string) ($file['name'] ?? ''), ENT_QUOTES, 'UTF-8')
            . ' (' . $kb . ' KB). El procesamiento a la base de datos se habilitará en el siguiente paso.',
        'archivo' => $safeName,
    ]);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
