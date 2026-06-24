<?php
declare(strict_types=1);

/**
 * Fetch genérico de un reporte SENA con búsqueda (q) y paginación.
 * $rep proviene de reportesCatalogo(); los identificadores (tabla/columnas) se
 * blindan con whitelist [a-z0-9_] aunque no sean input de usuario. El valor de
 * búsqueda va siempre parametrizado.
 *
 * @param array<string, mixed> $rep
 * @param array<string, mixed> $filters  típicamente $_GET
 * @return array{rows: list<array<string,mixed>>, total:int, page:int, per_page:int, total_pages:int, from:int, to:int}
 */
function reportesFetch(PDO $pdo, array $rep, array $filters): array
{
    $ident = static fn (string $s): string => preg_replace('/[^a-z0-9_]/', '', strtolower($s)) ?? '';

    $tabla = $ident((string) ($rep['tabla'] ?? ''));
    $columnas = is_array($rep['columnas'] ?? null) ? $rep['columnas'] : [];
    $colKeys = array_values(array_filter(array_map(
        static fn ($c): string => $ident((string) ($c['key'] ?? '')),
        $columnas
    )));

    if ($tabla === '' || $colKeys === []) {
        return listadoPaginacionMeta([], 0, 1, 25);
    }

    $pag = listadoPaginacionFromRequest($filters);

    $where = '';
    $params = [];
    $q = trim((string) ($filters['q'] ?? ''));
    $buscar = is_array($rep['buscar'] ?? null) ? $rep['buscar'] : [];
    if ($q !== '' && $buscar !== []) {
        $parts = [];
        foreach ($buscar as $bc) {
            $col = $ident((string) $bc);
            if ($col !== '') {
                $parts[] = "CAST({$col} AS TEXT) ILIKE :q";
            }
        }
        if ($parts !== []) {
            $where = 'WHERE (' . implode(' OR ', $parts) . ')';
            $params[':q'] = '%' . $q . '%';
        }
    }

    $orden = $ident((string) ($rep['orden'] ?? $colKeys[0]));
    if ($orden === '') {
        $orden = $colKeys[0];
    }

    $stmtCount = $pdo->prepare("SELECT COUNT(*) FROM {$tabla} {$where}");
    $stmtCount->execute($params);
    $total = (int) ($stmtCount->fetchColumn() ?: 0);

    $colSql = implode(', ', $colKeys);
    $sql = "SELECT {$colSql} FROM {$tabla} {$where} ORDER BY {$orden} ASC NULLS LAST LIMIT :limit OFFSET :offset";
    $stmt = $pdo->prepare($sql);
    foreach ($params as $k => $v) {
        $stmt->bindValue($k, $v);
    }
    $stmt->bindValue(':limit', $pag['per_page'], PDO::PARAM_INT);
    $stmt->bindValue(':offset', $pag['offset'], PDO::PARAM_INT);
    $stmt->execute();

    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

    return listadoPaginacionMeta($rows, $total, $pag['page'], $pag['per_page']);
}
