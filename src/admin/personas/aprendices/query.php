<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/lib/query_shared.php';

/**
 * @param array<string, mixed> $filters
 * @return array{rows: list<array<string, mixed>>, total: int, page: int, per_page: int, total_pages: int, from: int, to: int}
 */
function personasListadoFetchAprendices(PDO $pdo, array $filters = []): array
{
    return personasListadoFetchPorTipo($pdo, 'Aprendiz', $filters);
}
