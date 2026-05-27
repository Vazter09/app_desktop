<?php
declare(strict_types=1);

require_once __DIR__ . '/init.php';

header('Content-Type: application/json; charset=UTF-8');

if (!registroModuloHabilitado()) {
    http_response_code(403);
    echo json_encode(['error' => 'Módulo deshabilitado']);
    exit;
}

if (registroUsaLoginStandalone()) {
    if (!registroTieneSesionStandalone()) {
        http_response_code(401);
        echo json_encode(['error' => 'No autorizado']);
        exit;
    }
} elseif (!registroTieneSesionPrincipal()) {
    http_response_code(401);
    echo json_encode(['error' => 'No autorizado']);
    exit;
}

$idDpto = trim($_GET['id_dpto'] ?? '');
if ($idDpto === '') {
    echo json_encode([]);
    exit;
}

try {
    echo json_encode(registroGetCiudadesByDpto($pdo, $idDpto), JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Error al cargar ciudades']);
}
