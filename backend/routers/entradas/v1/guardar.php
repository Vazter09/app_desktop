<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/middleware/require_session.php';
require_once dirname(__DIR__, 3) . '/middleware/require_admin.php';
require_once dirname(__DIR__, 3) . '/services/entradas/entrada_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$raw = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : $_POST;
if (!is_array($json)) {
    $json = $_POST;
}

try {
    global $stmt_fun_upsert_entrada;

    $id = isset($json['id_entrada']) && $json['id_entrada'] !== ''
        ? entradasResolveIdEntradaPost((string) $json['id_entrada'])
        : null;
    $nombre = trim((string) ($json['nombre'] ?? $json['txt_nom_entrada'] ?? ''));
    [$centro, $sede] = entradasParseSedeSeleccionada((string) ($json['sel_sede'] ?? ''));

    $codigo = entradasGuardar($stmt_fun_upsert_entrada, $id, $nombre, $centro, $sede);
    RouterResponse::ok([
        'message' => $codigo !== '' ? "Entrada {$codigo} guardada correctamente." : 'Entrada guardada correctamente.',
        'codigo' => $codigo,
    ]);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
