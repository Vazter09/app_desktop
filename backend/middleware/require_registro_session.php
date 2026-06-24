<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/core/prepare.php';
require_once dirname(__DIR__) . '/core/RouterResponse.php';
require_once dirname(__DIR__) . '/services/registro/access.php';

if (!registroTieneSesionStandalone()) {
    RouterResponse::unauthorized('Sesión de registro no válida.');
}
