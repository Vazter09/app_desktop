<?php
declare(strict_types=1);

require_once __DIR__ . '/query.php';

$personasListado = [
    'menu_id' => '20703',
    'titulo' => 'Contratistas',
    'fetch' => 'personasListadoFetchContratistas',
];

require dirname(__DIR__) . '/lib/listado_index.php';
