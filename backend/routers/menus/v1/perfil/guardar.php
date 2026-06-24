<?php
declare(strict_types=1);

require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session.php';
require_once dirname(__DIR__, 4) . '/middleware/require_admin.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$raw = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : $_POST;
if (!is_array($json)) {
    $json = $_POST;
}

$idU = $json['hid_usuario'] ?? null;
$menus = $json['chk_menu'] ?? $json['menus'] ?? [];

try {
    if ($idU === null || $idU === '') {
        RouterResponse::fail('ID del usuario es obligatorio.');
    }

    if (usuarioEsAdministrador($pdo, (string) $idU)) {
        RouterResponse::fail('Los usuarios administrador tienen acceso fijo a todo el catálogo.');
    }

    if (!is_array($menus)) {
        $menus = [];
    }

    $pdo->beginTransaction();
    $stmt_del_perfil->execute([$idU]);
    foreach ($menus as $idM) {
        if (!empty($idM)) {
            $stmt_ins_perfil->execute([$idU, $idM]);
        }
    }
    $pdo->commit();

    $cantidad = count($menus);
    RouterResponse::ok([
        'message' => $cantidad === 1 ? '1 menú asignado correctamente' : "{$cantidad} menús asignados correctamente",
        'cantidadGuardada' => $cantidad,
    ]);
} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
