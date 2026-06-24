<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/middleware/require_session.php';
require_once dirname(__DIR__, 3) . '/middleware/require_admin.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$raw = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : $_POST;
if (!is_array($json)) {
    $json = $_POST;
}

try {
    global $stmt_login, $stmt_fun_upd_user;

    $id = trim((string) ($json['id_usuario'] ?? $json['hid_id_usuario'] ?? ''));
    $nuevoEstado = (string) ($json['nuevo_estado'] ?? $json['hid_nuevo_estado'] ?? 'false');

    $stmt_login->execute([$id]);
    $r = $stmt_login->fetch();
    if (!$r) {
        RouterResponse::fail('Usuario no encontrado.');
    }

    $stmt_fun_upd_user->execute([
        $id,
        $r['nom_usuario'],
        $r['pass_usuario'],
        $r['mail_usuario'],
        !empty($r['ind_usuario']) ? 'true' : 'false',
        $nuevoEstado,
    ]);

    RouterResponse::ok(['message' => 'Estado actualizado correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
