<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/core/prepare.php';
require_once __DIR__ . '/require_session.php';

if (empty($_SESSION['ind_usuario'])) {
    RouterResponse::unauthorized('Requiere perfil administrador.');
}
