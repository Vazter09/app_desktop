<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/core/prepare.php';
require_once dirname(__DIR__) . '/core/RouterResponse.php';
require_once dirname(__DIR__) . '/services/registro/access.php';

if (registroUsaLoginStandalone()) {
    if (!registroTieneSesionStandalone()) {
        RouterResponse::unauthorized('Sesión de registro no válida.');
    }
} else {
    if (!registroTieneSesionPrincipal()) {
        RouterResponse::unauthorized('Sesión no válida.');
    }
    require_once dirname(__DIR__) . '/core/helpers.php';
    if (!usuarioTieneMenu($pdo, (string) $_SESSION['id_usuario'], '0300')) {
        RouterResponse::unauthorized('No tiene el módulo de registro asignado.');
    }
}

$pdo->exec("SET app.usuario = " . $pdo->quote(registroDisplayUsername()));
