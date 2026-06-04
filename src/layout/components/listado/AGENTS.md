# Componentes de listado (reutilizables)

Patrón tipo “props” de React: PHP arma un **array de configuración** y el partial solo renderiza.

## Archivos

| Partial | Función PHP | Variable de entrada |
|---------|-------------|---------------------|
| `filtros.php` | `listadoRenderFiltros()` | `$listadoFiltros` |
| `tabla.php` | `listadoRenderTabla()` | `$listadoTabla` |
| `paginacion.php` | `listadoRenderPaginacion()` | `$listadoPaginacion` |
| `shell.php` | `listadoRenderShell()` | `$listadoShell` |

Lógica compartida: `src/core/listado_ui.php`  
JS: `js/smartcset-listado.js` (`window.SmartcsetListado`)

## Uso en un módulo nuevo

```php
require_once 'src/core/listado_ui.php';

$listadoShell = [
    'title' => 'Mi listado',
    'filtros' => [
        'action' => '/ruta/index.php',
        'reset_url' => '/ruta/index.php',
        'fields' => [ /* name, label, type, col, options */ ],
        'values' => [ 'q' => '...' ],
    ],
    'tabla' => [
        'columns' => [ ['key' => 'id', 'label' => 'ID'], ... ],
        'rows' => $rows,
    ],
    'paginacion' => [
        'page' => 1, 'per_page' => 25, 'total' => 100,
        'base_path' => '/ruta/index.php',
        'query_params' => [ 'q' => 'x' ],
    ],
];
listadoRenderShell($listadoShell);
```

## AJAX partial

Misma página con `?partial=1`. El host debe tener `id="personas-listado-host"` o `data-smart-listado-host` y cargar `smartcset-listado.js`.

## Columnas tabla

- `render` => `badge` + `badge_key` => `activo`
- `truncate` => ancho máx. + `title_from`

## Extender Personas por tipo

En `aprendices/index.php`:

```php
$personasListado['filtros_fields'] = array_merge(personasListadoFiltrosFields(), [ /* extra */ ]);
$personasListado['tabla_columns'] = [ /* columnas propias */ ];
```

Consulta paginada en `aprendices/query.php` (puede dejar de usar `personasListadoFetchPorTipo`).
