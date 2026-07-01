<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Listar menús asignados a un usuario",
 *   "tags": ["Menús"],
 *   "parameters": [
 *     { "name": "usuario", "in": "query", "required": true, "schema": { "type": "string" } }
 *   ],
 *   "responses": {
 *     "200": { "description": "IDs de menú del perfil", "dataSchema": { "type": "object", "properties": { "menus": { "type": "array", "items": { "type": "string" } }, "admin": { "type": "boolean" } } } }
 *   }
 * }
 */
require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session.php';
require_once dirname(__DIR__, 4) . '/middleware/require_admin.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

$usuario = trim((string) ($_GET['usuario'] ?? ''));

if ($usuario === '') {
    RouterResponse::fail('Usuario requerido.');
}

if (usuarioEsAdministrador($pdo, $usuario)) {
    $stmt = $pdo->query('SELECT id_menu FROM tab_menus ORDER BY id_menu');
    $ids = $stmt->fetchAll(PDO::FETCH_COLUMN);
    RouterResponse::ok(['menus' => array_map('strval', $ids), 'admin' => true]);
}

$stmt = $pdo->prepare(
    'SELECT id_menu FROM tab_menu_usuarios WHERE id_usuario = CAST(? AS TEXT) ORDER BY id_menu'
);
$stmt->execute([$usuario]);
$ids = $stmt->fetchAll(PDO::FETCH_COLUMN);

RouterResponse::ok(['menus' => array_map('strval', $ids), 'admin' => false]);
