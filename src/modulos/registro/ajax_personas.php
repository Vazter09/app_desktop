<?php
declare(strict_types=1);

require_once __DIR__ . '/init.php';
require_once __DIR__ . '/lib/personas_list.php';

registroRequireAccess();

header('Content-Type: application/json; charset=UTF-8');

$tipo = trim((string) ($_GET['tipo'] ?? ''));
if ($tipo === '' || !ctype_digit($tipo)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Parámetro tipo inválido.'], JSON_UNESCAPED_UNICODE);
    exit;
}

$tipoNum = (int) $tipo;
if ($tipoNum < 1 || $tipoNum > 4) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Tipo fuera de rango.'], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $data = registroFetchPersonasPorTipo($pdo, $tipoNum);
    echo json_encode(['status' => 'ok', 'data' => $data], JSON_UNESCAPED_UNICODE);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}