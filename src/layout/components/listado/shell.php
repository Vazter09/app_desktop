<?php
/**
 * Contenedor de listado: filtros + tabla + paginación.
 * Variable: $listadoShell — title, badge_count?, filtros?, tabla, paginacion?, root_id?, page_title?
 */
declare(strict_types=1);

if (!isset($listadoShell) || !is_array($listadoShell)) {
    return;
}

$title = (string) ($listadoShell['title'] ?? 'Listado');
$badgeCount = (int) ($listadoShell['badge_count'] ?? 0);
$rootId = (string) ($listadoShell['root_id'] ?? 'personas-listado-root');
$pageTitle = (string) ($listadoShell['page_title'] ?? ('Listado — ' . $title));
?>
<div class="personas-listado-admin smart-listado"
     id="<?= htmlspecialchars($rootId, ENT_QUOTES, 'UTF-8') ?>"
     data-page-title="<?= htmlspecialchars($pageTitle, ENT_QUOTES, 'UTF-8') ?>">
    <div class="row g-3">
        <div class="col-12">
            <div class="card shadow-sm border-0">
                <div class="card-header bg-corporativo py-2 d-flex flex-wrap justify-content-between align-items-center gap-2">
                    <strong style="font-size:0.95rem;">
                        <i class="bi bi-person-vcard-fill me-2"></i>Listado — <?= htmlspecialchars($title, ENT_QUOTES, 'UTF-8') ?>
                        <span class="badge bg-light text-dark ms-1" style="font-size:0.72rem;"><?= $badgeCount ?></span>
                    </strong>
                </div>
                <?php if (!empty($listadoShell['filtros']) && is_array($listadoShell['filtros'])): ?>
                <div class="card-body border-bottom py-3 smart-listado-filtros-wrap">
                    <?php listadoRenderFiltros($listadoShell['filtros']); ?>
                </div>
                <?php endif; ?>
                <div class="smart-listado-tabla-wrap">
                    <?php
                    if (!empty($listadoShell['tabla']) && is_array($listadoShell['tabla'])) {
                        listadoRenderTabla($listadoShell['tabla']);
                    }
                    ?>
                </div>
                <?php if (!empty($listadoShell['paginacion']) && is_array($listadoShell['paginacion'])): ?>
                <div class="card-footer bg-white border-top smart-listado-paginacion-wrap">
                    <?php listadoRenderPaginacion($listadoShell['paginacion']); ?>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>
