<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/services/registro/catalogos.php';
require_once dirname(__DIR__, 3) . '/services/registro/access.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

if (!registroModuloHabilitado()) {
    RouterResponse::fail('Módulo deshabilitado.', 403);
}

if (registroUsaLoginStandalone()) {
    if (!registroTieneSesionStandalone()) {
        RouterResponse::unauthorized();
    }
} elseif (!registroTieneSesionPrincipal()) {
    RouterResponse::unauthorized();
}

$idDpto = trim((string) ($_GET['id_dpto'] ?? ''));
if ($idDpto === '') {
    RouterResponse::ok(['ciudades' => []]);
}

try {
    RouterResponse::ok(['ciudades' => registroGetCiudadesByDpto($pdo, $idDpto)]);
} catch (Throwable $e) {
    RouterResponse::fail('Error al cargar ciudades.', 500);
}
