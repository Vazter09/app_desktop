<?php
declare(strict_types=1);

require_once __DIR__ . '/query.php';

$personasListado = [
    'menu_id' => '20101',
    'titulo' => 'Instructores',
    'fetch' => 'personasListadoFetchInstructores',
];

require dirname(__DIR__) . '/lib/listado_index.php';
