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

$origen = trim((string) ($json['usuario_origen'] ?? ''));
$destino = trim((string) ($json['usuario_destino'] ?? ''));

try {
    global $pdo, $stmt_del_perfil, $stmt_ins_perfil;

    if ($origen === '' || $destino === '') {
        RouterResponse::fail('Usuario origen y destino son obligatorios.');
    }
    if (usuarioEsAdministrador($pdo, $origen) || usuarioEsAdministrador($pdo, $destino)) {
        RouterResponse::fail('No se permite copiar el perfil de un usuario administrador.');
    }
    if ($origen === $destino) {
        RouterResponse::fail('El usuario origen y el usuario destino no pueden ser el mismo.');
    }

    $pdo->beginTransaction();
    $stmt_del_perfil->execute([$destino]);

    $stmtMenus = $pdo->prepare('SELECT id_menu FROM tab_menu_usuarios WHERE id_usuario = ? ORDER BY id_menu');
    $stmtMenus->execute([$origen]);
    $menus = $stmtMenus->fetchAll(PDO::FETCH_COLUMN);

    $copiados = 0;
    foreach ($menus as $idMenu) {
        if ($idMenu !== '') {
            $stmt_ins_perfil->execute([$destino, $idMenu]);
            $copiados++;
        }
    }
    $pdo->commit();

    RouterResponse::ok([
        'message' => $copiados === 1
            ? "Se copió 1 menú de {$origen} a {$destino}"
            : "Se copiaron {$copiados} menús de {$origen} a {$destino}",
        'copiados' => $copiados,
    ]);
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
