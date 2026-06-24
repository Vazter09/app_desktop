<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/core/lib/acceso_sesion.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$idSesion = (int) ($_SESSION['id_sesion'] ?? 0);
$idUsuario = trim((string) ($_SESSION['id_usuario'] ?? ''));

if ($idSesion < 1 || $idUsuario === '') {
    RouterResponse::unauthorized();
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
    RouterResponse::ok();
} catch (Throwable $e) {
    error_log('heartbeat sesion: ' . $e->getMessage());
    RouterResponse::fail('No se pudo actualizar la actividad.', 500);
}
