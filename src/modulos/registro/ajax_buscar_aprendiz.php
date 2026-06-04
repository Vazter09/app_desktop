<?php
declare(strict_types=1);

require_once __DIR__ . '/init.php';
require_once __DIR__ . '/lib/registro_buscar_aprendiz.php';

registroRequireAccess();

header('Content-Type: application/json; charset=UTF-8');

$idPersonaRaw = trim((string) ($_GET['id_persona'] ?? ''));
$idTipoDocum  = isset($_GET['id_tipo_docum']) ? trim((string) $_GET['id_tipo_docum']) : null;
if ($idTipoDocum === '') {
    $idTipoDocum = null;
}

$doc = registroNormalizarDocumentoAprendiz($idPersonaRaw);
if ($doc === '' || strlen($doc) < 6) {
    echo json_encode([
        'status'  => 'invalid',
        'message' => 'Ingrese un número de documento válido (mínimo 6 dígitos).',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $result = registroBuscarAprendizPorDocumento($pdo, $doc, $idTipoDocum);

    if ($result === null) {
        echo json_encode([
            'status'  => 'not_found',
            'message' => 'No se encontró una persona con ese documento.',
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    echo json_encode($result, JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'status'  => 'error',
        'message' => ErrorHandler::userMessageFromException($e),
    ], JSON_UNESCAPED_UNICODE);
}
