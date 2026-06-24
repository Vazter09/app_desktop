<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/core/prepare.php';
require_once dirname(__DIR__) . '/core/RouterResponse.php';

if (!isset($_SESSION['id_usuario']) || $_SESSION['id_usuario'] === '') {
    RouterResponse::unauthorized('Sesión no válida.');
}
