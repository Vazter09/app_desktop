<?php
/**
 * Paginación server-side reutilizable.
 * Variable: $listadoPaginacion — page, per_page, total, total_pages, from, to, base_path, query_params
 */
declare(strict_types=1);

if (!isset($listadoPaginacion) || !is_array($listadoPaginacion)) {
    return;
}

$page = max(1, (int) ($listadoPaginacion['page'] ?? 1));
$perPage = max(1, (int) ($listadoPaginacion['per_page'] ?? 25));
$total = max(0, (int) ($listadoPaginacion['total'] ?? 0));
$totalPages = max(1, (int) ($listadoPaginacion['total_pages'] ?? 1));
$from = (int) ($listadoPaginacion['from'] ?? 0);
$to = (int) ($listadoPaginacion['to'] ?? 0);
$basePath = (string) ($listadoPaginacion['base_path'] ?? '');
$queryParams = $listadoPaginacion['query_params'] ?? [];
if (!is_array($queryParams)) {
    $queryParams = [];
}

$buildPageUrl = static function (int $targetPage) use ($basePath, $queryParams, $perPage): string {
    $params = array_merge($queryParams, [
        'page' => $targetPage,
        'per_page' => $perPage,
    ]);

    return $basePath . listadoBuildQuery($params);
};

$window = 2;
$start = max(1, $page - $window);
$end = min($totalPages, $page + $window);
?>
<nav class="smart-listado-paginacion d-flex flex-wrap align-items-center justify-content-between gap-2 py-2 px-1"
     aria-label="Paginación del listado"
     data-smart-listado-paginacion="1">
    <div class="small text-muted">
        <?php if ($total === 0): ?>
            Sin resultados
        <?php else: ?>
            Mostrando <strong><?= $from ?></strong>–<strong><?= $to ?></strong> de <strong><?= $total ?></strong>
        <?php endif; ?>
    </div>
    <ul class="pagination pagination-sm mb-0">
        <li class="page-item <?= $page <= 1 ? 'disabled' : '' ?>">
            <a class="page-link"
               href="<?= htmlspecialchars($buildPageUrl(max(1, $page - 1)), ENT_QUOTES, 'UTF-8') ?>"
               data-smart-listado-page="<?= max(1, $page - 1) ?>"
               aria-label="Anterior">&laquo;</a>
        </li>
        <?php if ($start > 1): ?>
        <li class="page-item">
            <a class="page-link" href="<?= htmlspecialchars($buildPageUrl(1), ENT_QUOTES, 'UTF-8') ?>" data-smart-listado-page="1">1</a>
        </li>
        <?php if ($start > 2): ?>
        <li class="page-item disabled"><span class="page-link">…</span></li>
        <?php endif; ?>
        <?php endif; ?>
        <?php for ($i = $start; $i <= $end; $i++): ?>
        <li class="page-item <?= $i === $page ? 'active' : '' ?>">
            <a class="page-link"
               href="<?= htmlspecialchars($buildPageUrl($i), ENT_QUOTES, 'UTF-8') ?>"
               data-smart-listado-page="<?= $i ?>"><?= $i ?></a>
        </li>
        <?php endfor; ?>
        <?php if ($end < $totalPages): ?>
        <?php if ($end < $totalPages - 1): ?>
        <li class="page-item disabled"><span class="page-link">…</span></li>
        <?php endif; ?>
        <li class="page-item">
            <a class="page-link"
               href="<?= htmlspecialchars($buildPageUrl($totalPages), ENT_QUOTES, 'UTF-8') ?>"
               data-smart-listado-page="<?= $totalPages ?>"><?= $totalPages ?></a>
        </li>
        <?php endif; ?>
        <li class="page-item <?= $page >= $totalPages ? 'disabled' : '' ?>">
            <a class="page-link"
               href="<?= htmlspecialchars($buildPageUrl(min($totalPages, $page + 1)), ENT_QUOTES, 'UTF-8') ?>"
               data-smart-listado-page="<?= min($totalPages, $page + 1) ?>"
               aria-label="Siguiente">&raquo;</a>
        </li>
    </ul>
    <form method="get" action="<?= htmlspecialchars($basePath, ENT_QUOTES, 'UTF-8') ?>" class="d-flex align-items-center gap-1 smart-listado-per-page">
        <?php foreach ($queryParams as $pKey => $pVal): ?>
            <?php if ($pKey === 'page' || $pKey === 'per_page' || $pVal === null || $pVal === '') {
                continue;
            } ?>
            <input type="hidden" name="<?= htmlspecialchars((string) $pKey, ENT_QUOTES, 'UTF-8') ?>"
                   value="<?= htmlspecialchars((string) $pVal, ENT_QUOTES, 'UTF-8') ?>">
        <?php endforeach; ?>
        <input type="hidden" name="page" value="1">
        <label class="small text-muted mb-0" for="smart-listado-per-page">Por página</label>
        <select name="per_page" id="smart-listado-per-page" class="form-select form-select-sm" style="width:auto;" data-smart-listado-per-page="1">
            <?php foreach ([10, 25, 50, 100] as $opt): ?>
            <option value="<?= $opt ?>" <?= $perPage === $opt ? 'selected' : '' ?>><?= $opt ?></option>
            <?php endforeach; ?>
        </select>
    </form>
</nav>
