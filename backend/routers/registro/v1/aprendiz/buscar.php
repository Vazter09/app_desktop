<?php
declare(strict_types=1);

require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 4) . '/middleware/require_registro_session.php';
require_once dirname(__DIR__, 4) . '/services/registro/registro_buscar_aprendiz.php';
require_once dirname(__DIR__, 4) . '/services/registro/access.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

$idPersonaRaw = trim((string) ($_GET['id_persona'] ?? ''));
$idTipoDocum = isset($_GET['id_tipo_docum']) ? trim((string) $_GET['id_tipo_docum']) : null;
if ($idTipoDocum === '') {
    $idTipoDocum = null;
}

$doc = registroNormalizarDocumentoAprendiz($idPersonaRaw);
if ($doc === '' || strlen($doc) < 6) {
    RouterResponse::ok([
        'status' => 'invalid',
        'message' => 'Ingrese un número de documento válido (mínimo 6 dígitos).',
    ]);
}

try {
    $result = registroBuscarAprendizPorDocumento($pdo, $doc, $idTipoDocum);

    if ($result === null) {
        RouterResponse::ok([
            'status' => 'not_found',
            'message' => 'No se encontró una persona con ese documento.',
        ]);
    }

    RouterResponse::ok($result);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
