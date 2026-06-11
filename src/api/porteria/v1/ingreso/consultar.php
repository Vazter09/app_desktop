<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::fail('Método no permitido.', 405);
}

porteriaApiRequireDevice();

$documento = trim((string) ($_GET['documento'] ?? ''));
$tipoDoc = trim((string) ($_GET['tipo_doc'] ?? 'CC'));

try {
    global $stmt_buscar_persona_doc, $stmt_buscar_ingreso_abierto;
    $resultado = ingresoConsultarAcceso(
        $stmt_buscar_persona_doc,
        $stmt_buscar_ingreso_abierto,
        $documento,
        $tipoDoc
    );
    ApiResponse::ok([
        'persona' => ApiPayload::formatPersona($resultado['persona']),
        'ingreso_abierto' => ApiPayload::formatIngresoAbierto($resultado['ingreso_abierto']),
        'puede_ingresar' => (bool) $resultado['puede_ingresar'],
    ]);
} catch (Throwable $e) {
    ApiResponse::fail(ErrorHandler::userMessageFromException($e));
}
