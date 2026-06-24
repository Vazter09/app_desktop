<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/prepare.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session_or_device.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

porteriaRequireSessionOrDevice();

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
    RouterResponse::ok([
        'persona' => PorteriaRouterPayload::formatPersona($resultado['persona']),
        'ingreso_abierto' => PorteriaRouterPayload::formatIngresoAbierto($resultado['ingreso_abierto']),
        'puede_ingresar' => (bool) $resultado['puede_ingresar'],
    ]);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
