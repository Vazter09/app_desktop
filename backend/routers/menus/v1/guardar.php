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
    global $stmt_ins_menu, $stmt_upd_menu, $pdo;

    $id = trim((string) ($json['id_menu'] ?? $json['txt_id_menu'] ?? ''));
    $nom = trim((string) ($json['nom_menu'] ?? $json['txt_nom_menu'] ?? ''));
    $padre = trim((string) ($json['id_padre'] ?? $json['txt_id_padre'] ?? smartcsetMenuPadreRaiz()));
    $programa = trim((string) ($json['nom_programa'] ?? $json['txt_nom_programa'] ?? '')) ?: 'no_aplica';

    if ($id === '' || $nom === '') {
        RouterResponse::fail('ID y descripción del menú son obligatorios.');
    }
    if ($padre === '') {
        $padre = smartcsetMenuPadreRaiz();
    }

    $stmt_check = $pdo->prepare('SELECT 1 FROM tab_menus WHERE id_menu = ?::TEXT');
    $stmt_check->execute([$id]);

    if ($stmt_check->fetch()) {
        $stmt_upd_menu->execute([$id, $nom, $padre, $programa]);
        $res = (string) $stmt_upd_menu->fetchColumn();
    } else {
        $stmt_ins_menu->execute([$id, $nom, $padre, $programa]);
        $res = (string) $stmt_ins_menu->fetchColumn();
    }

    if (strpos($res, 'OK') === false) {
        RouterResponse::fail('Error: ' . $res);
    }

    RouterResponse::ok(['message' => 'Menú guardado correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
