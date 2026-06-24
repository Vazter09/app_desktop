<?php
declare(strict_types=1);

/**
 * Heartbeat de presencia: actualiza ult_actividad / ult_ruta sin recargar la página.
 */
require_once __DIR__ . '/prepare.php';

header('Content-Type: application/json; charset=UTF-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['ok' => false, 'error' => 'Método no permitido'], JSON_UNESCAPED_UNICODE);
    exit;
}

$idSesion = (int) ($_SESSION['id_sesion'] ?? 0);
$idUsuario = trim((string) ($_SESSION['id_usuario'] ?? ''));

if ($idSesion < 1 || $idUsuario === '') {
    http_response_code(401);
    echo json_encode(['ok' => false, 'error' => 'No autorizado'], JSON_UNESCAPED_UNICODE);
    exit;
}

$ultRuta = trim((string) ($_POST['ult_ruta'] ?? ''));
if ($ultRuta === '') {
    $ultRuta = Db::resolverUltRuta();
}

$ultMenuId = trim((string) ($_POST['ult_menu_id'] ?? ''));
if ($ultMenuId === '') {
    $menu = Db::resolverUltMenuId();
    $ultMenuId = $menu ?? '';
}

try {
    accesoTouchSesion(
        $stmt_fun_touch_sesion,
        $idSesion,
        $ultRuta,
        $ultMenuId !== '' ? $ultMenuId : null
    );
    $_SESSION['_sesion_touch_at'] = time();

    echo json_encode(['ok' => true], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    error_log('heartbeat sesion: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(
        ['ok' => false, 'error' => 'No se pudo actualizar la actividad'],
        JSON_UNESCAPED_UNICODE
    );
}
