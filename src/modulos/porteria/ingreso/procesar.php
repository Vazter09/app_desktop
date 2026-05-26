<?php
require_once __DIR__ . '/../lib/init.php';
require_once __DIR__ . '/../lib/ingresos_registro.php';
require_once __DIR__ . '/../lib/porteria_foto.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . $smartcset_asset_href . 'index.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: index.php');
    exit;
}

try {
    $idIngreso = ingresoRegistrarManual(
        $stmt_fun_registrar_ingreso,
        $stmt_buscar_ingreso_abierto,
        $_POST,
        $_SESSION['id_usuario']
    );

    $fotoData = trim($_POST['hid_foto_data'] ?? '');
    if ($fotoData !== '') {
        porteriaGuardarFotoRegistro($pdo, $idIngreso, 'ingreso', $fotoData);
    }

    $_SESSION['flash_msg'] = "Ingreso #{$idIngreso} registrado correctamente.";
    $_SESSION['flash_tipo'] = 'success';
    $_SESSION['ultimo_ingreso_id'] = $idIngreso;
    $_SESSION['ingreso_puerta_pref'] = (int) ($_POST['sel_entrada'] ?? 0);
} catch (PDOException $e) {
    $_SESSION['flash_msg'] = ErrorHandler::userMessageFromException($e);
    $_SESSION['flash_tipo'] = 'danger';
} catch (Exception $e) {
    $_SESSION['flash_msg'] = ErrorHandler::userMessageFromException($e);
    $_SESSION['flash_tipo'] = 'danger';
}

header('Location: index.php');
exit;
