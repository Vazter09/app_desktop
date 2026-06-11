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
                <div class="card-header bg-corporativo smart-listado-header d-flex flex-wrap justify-content-between align-items-center gap-2">
                    <div class="smart-listado-header-title">
                        <i class="bi bi-person-vcard-fill" aria-hidden="true"></i>
                        <span>Listado — <?= htmlspecialchars($title, ENT_QUOTES, 'UTF-8') ?></span>
                        <span class="smart-listado-count-badge"
                              title="<?= number_format($badgeCount, 0, ',', '.') ?> registros">
                            <?= number_format($badgeCount, 0, ',', '.') ?>
                        </span>
                    </div>
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
                <div class="card-footer border-top smart-listado-paginacion-wrap">
                    <?php listadoRenderPaginacion($listadoShell['paginacion']); ?>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>
