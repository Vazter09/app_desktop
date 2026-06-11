<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::fail('Método no permitido.', 405);
}

$device = porteriaApiRequireDevice();

ApiResponse::ok([
    'id_dispositivo' => (int) $device['id_dispositivo'],
    'nom_dispositivo' => (string) $device['nom_dispositivo'],
    'id_usuario_audit' => (string) $device['id_usuario_audit'],
    'id_entrada_default' => $device['id_entrada_default'] !== null
        ? (int) $device['id_entrada_default']
        : null,
]);
