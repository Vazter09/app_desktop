<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/listado_ui.php';
require_once dirname(__DIR__, 3) . '/modulos/registro/lib/personas_list.php';
require_once __DIR__ . '/tipo_id.php';

/**
 * Listado paginado de personas por tipo (filtros reutilizables).
 *
 * @param array<string, mixed> $filters
 * @param array{
 *     join_sql?: string,
 *     select_extra?: string,
 *     search_extra?: string,
 *     where_extra?: string,
 *     where_params?: array<string, mixed>,
 *     map_row?: callable|string
 * } $extensions
 * @return array{rows: list<array<string, mixed>>, total: int, page: int, per_page: int, total_pages: int, from: int, to: int}
 */
function personasListadoFetchPorTipo(PDO $pdo, string $tipoName, array $filters = [], array $extensions = []): array
{
    $tipo = personasResolveTipoId($pdo, $tipoName);
    if ($tipo < 1) {
        $pag = listadoPaginacionFromRequest($filters);

        return listadoPaginacionMeta([], 0, $pag['page'], $pag['per_page']);
    }

    $pag = listadoPaginacionFromRequest($filters);
    $q = trim((string) ($filters['q'] ?? ''));
    $estado = (string) ($filters['estado'] ?? '');
    $joinSql = trim((string) ($extensions['join_sql'] ?? ''));
    $selectExtra = (string) ($extensions['select_extra'] ?? '');
    $searchExtra = trim((string) ($extensions['search_extra'] ?? ''));
    $whereExtra = trim((string) ($extensions['where_extra'] ?? ''));
    $whereParams = $extensions['where_params'] ?? [];
    if (!is_array($whereParams)) {
        $whereParams = [];
    }
    $mapRow = $extensions['map_row'] ?? 'registroMapPersonaRow';

    $where = ['p.id_tipo_persona = :tipo'];
    $params = [':tipo' => $tipo];

    if ($q !== '') {
        $searchParts = [
            'CAST(p.id_persona AS TEXT) ILIKE :q',
            'p.nom_persona ILIKE :q',
            'p.ape_persona ILIKE :q',
            "COALESCE(p.mail_persona, '') ILIKE :q",
        ];
        if ($searchExtra !== '') {
            $searchParts[] = ltrim($searchExtra, 'OR ');
        }
        $where[] = '(' . implode("\n            OR ", $searchParts) . ')';
        $params[':q'] = '%' . $q . '%';
    }

    if ($estado === '1') {
        $where[] = 'p.ind_estado = TRUE';
    } elseif ($estado === '0') {
        $where[] = 'p.ind_estado = FALSE';
    }

    if ($whereExtra !== '') {
        $where[] = $whereExtra;
    }

    foreach ($whereParams as $paramKey => $paramValue) {
        $params[(string) $paramKey] = $paramValue;
    }

    $whereSql = implode(' AND ', $where);
    $joinClause = $joinSql !== '' ? "\n        {$joinSql}" : '';

    $sqlCount = "SELECT COUNT(*) FROM tab_personas p{$joinClause} WHERE {$whereSql}";
    $stmtCount = $pdo->prepare($sqlCount);
    $stmtCount->execute($params);
    $total = (int) ($stmtCount->fetchColumn() ?: 0);

    $sql = "
        SELECT
            p.id_persona,
            p.id_tipo_persona,
            COALESCE(tp.nom_tipo_persona, '') AS nom_tipo_persona,
            p.nom_persona,
            p.ape_persona,
            p.mail_persona,
            p.fec_nacimiento,
            p.ind_estado,
            COALESCE(d.nom_dpto, '') AS nom_dpto,
            COALESCE(c.nom_ciudad, '') AS nom_ciudad,
            p.dir_ciudad_reside{$selectExtra}
        FROM tab_personas p
        LEFT JOIN tab_tipos_persona tp ON tp.id_tipo_persona = p.id_tipo_persona
        LEFT JOIN tab_dptos d ON d.id_dpto = p.id_dpto_reside
        LEFT JOIN tab_ciudades c ON c.id_ciudad = p.id_ciudad_reside{$joinClause}
        WHERE {$whereSql}
        ORDER BY p.fec_insert DESC NULLS LAST
        LIMIT :limit OFFSET :offset
    ";

    $stmt = $pdo->prepare($sql);
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $pag['per_page'], PDO::PARAM_INT);
    $stmt->bindValue(':offset', $pag['offset'], PDO::PARAM_INT);
    $stmt->execute();

    $mapFn = is_string($mapRow) ? $mapRow : null;
    if (!is_string($mapRow) && !is_callable($mapRow)) {
        $mapFn = 'registroMapPersonaRow';
    }

    $rows = array_map(
        static function (array $row) use ($mapFn, $mapRow): array {
            if (is_callable($mapRow)) {
                return $mapRow($row);
            }

            return $mapFn !== null && function_exists($mapFn)
                ? $mapFn($row)
                : registroMapPersonaRow($row);
        },
        $stmt->fetchAll(PDO::FETCH_ASSOC) ?: []
    );

    return listadoPaginacionMeta($rows, $total, $pag['page'], $pag['per_page']);
}
