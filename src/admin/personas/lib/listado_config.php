<?php
declare(strict_types=1);

/**
 * Configuración por defecto de filtros y columnas para listados Personas.
 */

/** @return list<array<string, mixed>> */
function personasListadoFiltrosFields(): array
{
    return [
        [
            'name' => 'q',
            'label' => 'Buscar',
            'type' => 'text',
            'placeholder' => 'Documento, nombre, correo…',
            'col' => 'col-md-4',
            'maxlength' => 80,
        ],
        [
            'name' => 'estado',
            'label' => 'Estado',
            'type' => 'select',
            'col' => 'col-md-2',
            'options' => [
                '' => 'Todos',
                '1' => 'Activos',
                '0' => 'Inactivos',
            ],
        ],
    ];
}

/** @return list<array<string, mixed>> */
function personasListadoTablaColumnas(): array
{
    return [
        ['key' => 'id_persona', 'label' => 'Documento', 'th_class' => 'ps-3 py-2', 'td_class' => 'ps-3 py-2 fw-bold'],
        ['key' => 'nombres', 'label' => 'Nombres y apellidos', 'td_class' => 'py-2'],
        [
            'key' => 'correo',
            'label' => 'Correo',
            'td_class' => 'py-2 text-truncate',
            'truncate' => 220,
            'title_from' => 'correo',
        ],
        [
            'key' => 'direccion',
            'label' => 'Dirección',
            'td_class' => 'py-2 text-truncate',
            'truncate' => 280,
            'title_from' => 'direccion',
        ],
        ['key' => 'fec_nacimiento', 'label' => 'F. Nac.', 'td_class' => 'py-2 fw-semibold'],
        [
            'key' => 'estado',
            'label' => 'Estado',
            'th_class' => 'py-2 text-center',
            'td_class' => 'py-2 text-center',
            'render' => 'badge',
            'badge_key' => 'activo',
        ],
    ];
}

/** @return array<string, string> */
function personasListadoFiltrosValues(array $query): array
{
    return [
        'q' => trim((string) ($query['q'] ?? '')),
        'estado' => (string) ($query['estado'] ?? ''),
    ];
}

/**
 * @param array<string, mixed> $config
 * @return array<string, mixed>
 */
function personasListadoBuildFiltrosConfig(array $config, array $query): array
{
    $basePath = (string) ($config['base_path'] ?? '');
    $values = personasListadoFiltrosValues($query);
    $fields = $config['filtros_fields'] ?? personasListadoFiltrosFields();
    if (!is_array($fields)) {
        $fields = personasListadoFiltrosFields();
    }

    return [
        'action' => $basePath,
        'reset_url' => $basePath,
        'fields' => $fields,
        'values' => $values,
        'form_id' => (string) ($config['form_id'] ?? 'personas-listado-filtros'),
    ];
}

/**
 * @param array<string, mixed> $listadoResult
 * @param array<string, mixed> $config
 * @param array<string, mixed> $query
 * @return array<string, mixed>
 */
function personasListadoBuildShellConfig(array $listadoResult, array $config, array $query): array
{
    $titulo = (string) ($config['titulo'] ?? 'Personas');
    $basePath = (string) ($config['base_path'] ?? '');
    $values = personasListadoFiltrosValues($query);
    $queryParams = array_filter(
        array_merge($values, [
            'per_page' => (int) ($listadoResult['per_page'] ?? 25),
        ]),
        static fn ($v) => $v !== null && $v !== ''
    );

    $columns = $config['tabla_columns'] ?? personasListadoTablaColumnas();
    if (!is_array($columns)) {
        $columns = personasListadoTablaColumnas();
    }

    return [
        'title' => $titulo,
        'page_title' => 'Listado — ' . $titulo,
        'badge_count' => (int) ($listadoResult['total'] ?? 0),
        'root_id' => (string) ($config['root_id'] ?? 'personas-listado-root'),
        'filtros' => personasListadoBuildFiltrosConfig($config, $query),
        'tabla' => [
            'id' => (string) ($config['tabla_id'] ?? 'tabla-personas'),
            'columns' => $columns,
            'rows' => $listadoResult['rows'] ?? [],
            'empty_message' => (string) ($config['empty_message'] ?? 'No hay registros para este tipo.'),
            'aria_label' => 'Listado de ' . $titulo,
        ],
        'paginacion' => [
            'page' => (int) ($listadoResult['page'] ?? 1),
            'per_page' => (int) ($listadoResult['per_page'] ?? 25),
            'total' => (int) ($listadoResult['total'] ?? 0),
            'total_pages' => (int) ($listadoResult['total_pages'] ?? 1),
            'from' => (int) ($listadoResult['from'] ?? 0),
            'to' => (int) ($listadoResult['to'] ?? 0),
            'base_path' => $basePath,
            'query_params' => $queryParams,
        ],
    ];
}
