<?php
declare(strict_types=1);

require_once __DIR__ . '/query.php';

$personasListado = [
    'menu_id' => '0301',
    'titulo' => 'Aprendices',
    'fetch' => 'personasListadoFetchAprendices',
    'filtros_fields' => 'personasListadoAprendicesFiltrosFields',
    'tabla_columns' => personasListadoAprendicesColumnas(),
];

require dirname(__DIR__) . '/lib/listado_index.php';
