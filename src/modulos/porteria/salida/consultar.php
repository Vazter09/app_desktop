<?php
require_once __DIR__ . '/../lib/init.php';
require_once __DIR__ . '/../lib/salidas_registro.php';

header('Content-Type: application/json; charset=utf-8');

if (!isset($_SESSION['id_usuario'])) {
    http_response_code(401);
    echo json_encode(['ok' => false, 'error' => 'Sesión no válida.']);
    exit;
}

try {
    $resultado = salidaConsultarAcceso(
        $stmt_buscar_persona_doc,
        $stmt_buscar_ingreso_abierto,
        $_GET['documento'] ?? '',
        $_GET['tipo_doc'] ?? 'CC'
    );
    echo json_encode([
        'ok' => true,
        'persona' => $resultado['persona'],
        'ingreso_abierto' => $resultado['ingreso_abierto'],
        'puede_salir' => $resultado['puede_salir'],
        'puede_ingresar' => !$resultado['puede_salir'],
    ]);
} catch (Exception $e) {
    echo json_encode(['ok' => false, 'error' => ErrorHandler::userMessageFromException($e)]);
}
