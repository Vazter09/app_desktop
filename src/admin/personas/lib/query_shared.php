<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/listado_ui.php';
require_once dirname(__DIR__, 3) . '/modulos/registro/lib/personas_list.php';
require_once __DIR__ . '/tipo_id.php';

/**
 * Listado paginado de personas por tipo (filtros reutilizables).
 *
 * @param array<string, mixed> $filters
 * @return array{rows: list<array<string, mixed>>, total: int, page: int, per_page: int, total_pages: int, from: int, to: int}
 */
function personasListadoFetchPorTipo(PDO $pdo, string $tipoName, array $filters = []): array
{
    $tipo = personasResolveTipoId($pdo, $tipoName);
    if ($tipo < 1) {
        $pag = listadoPaginacionFromRequest($filters);

        return listadoPaginacionMeta([], 0, $pag['page'], $pag['per_page']);
    }

    $pag = listadoPaginacionFromRequest($filters);
    $q = trim((string) ($filters['q'] ?? ''));
    $estado = (string) ($filters['estado'] ?? '');

    $where = ['p.id_tipo_persona = :tipo'];
    $params = [':tipo' => $tipo];

    if ($q !== '') {
        $where[] = "(
            CAST(p.id_persona AS TEXT) ILIKE :q
            OR p.nom_persona ILIKE :q
            OR p.ape_persona ILIKE :q
            OR COALESCE(p.mail_persona, '') ILIKE :q
        )";
        $params[':q'] = '%' . $q . '%';
    }

    if ($estado === '1') {
        $where[] = 'p.ind_estado = TRUE';
    } elseif ($estado === '0') {
        $where[] = 'p.ind_estado = FALSE';
    }

    $whereSql = implode(' AND ', $where);

    $sqlCount = "SELECT COUNT(*) FROM tab_personas p WHERE {$whereSql}";
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
            p.dir_ciudad_reside
        FROM tab_personas p
        LEFT JOIN tab_tipos_persona tp ON tp.id_tipo_persona = p.id_tipo_persona
        LEFT JOIN tab_dptos d ON d.id_dpto = p.id_dpto_reside
        LEFT JOIN tab_ciudades c ON c.id_ciudad = p.id_ciudad_reside
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

    $rows = array_map(
        'registroMapPersonaRow',
        $stmt->fetchAll(PDO::FETCH_ASSOC) ?: []
    );

    return listadoPaginacionMeta($rows, $total, $pag['page'], $pag['per_page']);
}
