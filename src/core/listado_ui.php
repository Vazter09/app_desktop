<?php
declare(strict_types=1);

/**
 * Utilidades reutilizables para listados admin (paginación, URLs, render de componentes).
 */

/** @return array{page: int, per_page: int, offset: int} */
function listadoPaginacionFromRequest(array $query, int $defaultPerPage = 25): array
{
    $allowed = [10, 25, 50, 100];
    $page = max(1, (int) ($query['page'] ?? 1));
    $perPage = (int) ($query['per_page'] ?? $defaultPerPage);
    if (!in_array($perPage, $allowed, true)) {
        $perPage = $defaultPerPage;
    }

    return [
        'page' => $page,
        'per_page' => $perPage,
        'offset' => ($page - 1) * $perPage,
    ];
}

/**
 * @return array{
 *   rows: list<array<string, mixed>>,
 *   total: int,
 *   page: int,
 *   per_page: int,
 *   total_pages: int,
 *   from: int,
 *   to: int
 * }
 */
function listadoPaginacionMeta(array $rows, int $total, int $page, int $perPage): array
{
    $totalPages = max(1, (int) ceil($total / max(1, $perPage)));
    if ($page > $totalPages) {
        $page = $totalPages;
    }
    $from = $total === 0 ? 0 : (($page - 1) * $perPage) + 1;
    $to = min($total, $page * $perPage);

    return [
        'rows' => $rows,
        'total' => $total,
        'page' => $page,
        'per_page' => $perPage,
        'total_pages' => $totalPages,
        'from' => $from,
        'to' => $to,
    ];
}

/** @param list<array<string, mixed>>|array<string, mixed> $result */
function listadoNormalizeResult(array $result, array $query, int $defaultPerPage = 25): array
{
    if (isset($result['rows']) && is_array($result['rows'])) {
        $page = max(1, (int) ($result['page'] ?? 1));
        $perPage = max(1, (int) ($result['per_page'] ?? $defaultPerPage));
        $total = max(0, (int) ($result['total'] ?? count($result['rows'])));

        return listadoPaginacionMeta($result['rows'], $total, $page, $perPage);
    }

    $pag = listadoPaginacionFromRequest($query, $defaultPerPage);
    $total = count($result);

    return listadoPaginacionMeta($result, $total, 1, $pag['per_page']);
}

/**
 * @param array<string, scalar|null> $params
 */
function listadoBuildQuery(array $params, array $omitKeys = ['partial']): string
{
    $clean = [];
    foreach ($params as $key => $value) {
        if (in_array((string) $key, $omitKeys, true)) {
            continue;
        }
        if ($value === null || $value === '') {
            continue;
        }
        $clean[(string) $key] = $value;
    }

    return $clean === [] ? '' : ('?' . http_build_query($clean));
}

/**
 * @param array<string, mixed> $config
 */
function listadoRenderFiltros(array $config): void
{
    $listadoFiltros = $config;
    include dirname(__DIR__) . '/layout/components/listado/filtros.php';
}

/**
 * @param array<string, mixed> $config
 */
function listadoRenderTabla(array $config): void
{
    $listadoTabla = $config;
    include dirname(__DIR__) . '/layout/components/listado/tabla.php';
}

/**
 * @param array<string, mixed> $config
 */
function listadoRenderPaginacion(array $config): void
{
    $listadoPaginacion = $config;
    include dirname(__DIR__) . '/layout/components/listado/paginacion.php';
}

/**
 * @param array<string, mixed> $config
 */
function listadoRenderShell(array $config): void
{
    $listadoShell = $config;
    include dirname(__DIR__) . '/layout/components/listado/shell.php';
}
