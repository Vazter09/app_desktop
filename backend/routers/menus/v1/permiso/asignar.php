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

$idUser = trim((string) ($json['id_usuario'] ?? ''));
$idMenu = trim((string) ($json['id_menu'] ?? ''));

/**
 * @return list<string>
 */
function menusObtenerAncestros(PDO $pdo, string $idMenu, array &$ancestros = []): array
{
    $stmt = $pdo->prepare('SELECT ind_id_padre FROM tab_menus WHERE id_menu = ?');
    $stmt->execute([$idMenu]);
    $padre = $stmt->fetchColumn();

    if ($padre && !smartcsetMenuEsPadreRaiz((string) $padre)) {
        $ancestros[] = (string) $padre;
        menusObtenerAncestros($pdo, (string) $padre, $ancestros);
    }

    return $ancestros;
}

try {
    global $pdo;

    if ($idUser === '' || $idMenu === '') {
        RouterResponse::fail('Usuario y menú son obligatorios.');
    }

    $lista = menusObtenerAncestros($pdo, $idMenu);
    $lista[] = $idMenu;

    $sql = 'INSERT INTO tab_menu_usuarios (id_usuario, id_menu) VALUES (?, ?) ON CONFLICT (id_usuario, id_menu) DO NOTHING';
    $stmt = $pdo->prepare($sql);
    foreach ($lista as $menuId) {
        $stmt->execute([$idUser, $menuId]);
    }

    RouterResponse::ok(['message' => 'Permiso asignado correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
