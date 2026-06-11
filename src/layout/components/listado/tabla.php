<?php
/**
 * Tabla de datos reutilizable.
 * Variable: $listadoTabla — id?, columns[], rows[], empty_message?, table_class?, aria_label?
 */
declare(strict_types=1);

if (!isset($listadoTabla) || !is_array($listadoTabla)) {
    return;
}

$columns = $listadoTabla['columns'] ?? [];
$rows = $listadoTabla['rows'] ?? [];
$tableId = (string) ($listadoTabla['id'] ?? 'smart-listado-tabla');
$tableClass = 'table table-hover table-striped align-middle mb-0 table-sm smart-listado-tabla '
    . (string) ($listadoTabla['table_class'] ?? '');
$emptyMessage = (string) ($listadoTabla['empty_message'] ?? 'No hay registros.');
$ariaLabel = (string) ($listadoTabla['aria_label'] ?? 'Listado de datos');
$colspan = count($columns) > 0 ? count($columns) : 1;
?>
<div class="table-responsive scroll-lista">
    <table class="<?= htmlspecialchars(trim($tableClass), ENT_QUOTES, 'UTF-8') ?>"
           id="<?= htmlspecialchars($tableId, ENT_QUOTES, 'UTF-8') ?>"
           aria-label="<?= htmlspecialchars($ariaLabel, ENT_QUOTES, 'UTF-8') ?>">
        <thead class="thead-oliva sticky-top">
            <tr>
                <?php foreach ($columns as $col): ?>
                    <?php
                    if (!is_array($col)) {
                        continue;
                    }
                    $thClass = (string) ($col['th_class'] ?? 'py-2');
                    ?>
                    <th class="<?= htmlspecialchars($thClass, ENT_QUOTES, 'UTF-8') ?>">
                        <?= htmlspecialchars((string) ($col['label'] ?? ''), ENT_QUOTES, 'UTF-8') ?>
                    </th>
                <?php endforeach; ?>
            </tr>
        </thead>
        <tbody>
            <?php if ($rows === []): ?>
            <tr>
                <td colspan="<?= (int) $colspan ?>" class="text-center text-muted py-4 small">
                    <?= htmlspecialchars($emptyMessage, ENT_QUOTES, 'UTF-8') ?>
                </td>
            </tr>
            <?php else: ?>
            <?php foreach ($rows as $row): ?>
                <?php if (!is_array($row)) {
                    continue;
                } ?>
            <tr>
                <?php foreach ($columns as $col): ?>
                    <?php
                    if (!is_array($col)) {
                        continue;
                    }
                    $key = (string) ($col['key'] ?? '');
                    $tdClass = (string) ($col['td_class'] ?? 'py-2');
                    $render = (string) ($col['render'] ?? 'text');
                    $cell = $row[$key] ?? '';
                    $title = (string) ($col['title_from'] ?? '') !== '' ? (string) ($row[$col['title_from']] ?? $cell) : (string) $cell;
                    ?>
                    <?php
                    $truncateClass = !empty($col['truncate']) ? ' smart-listado-cell-truncate' : '';
                    $docClass = $key === 'id_persona' ? ' smart-listado-col-doc' : '';
                    ?>
                    <td class="<?= htmlspecialchars(trim($tdClass . $truncateClass . $docClass), ENT_QUOTES, 'UTF-8') ?>"
                        <?php if (!empty($col['truncate'])): ?>
                        style="max-width:<?= (int) ($col['truncate'] ?? 220) ?>px;"
                        title="<?= htmlspecialchars($title, ENT_QUOTES, 'UTF-8') ?>"
                        <?php endif; ?>>
                        <?php if ($render === 'badge'): ?>
                            <?php
                            $active = !empty($row[$col['badge_key'] ?? 'activo']);
                            $badgeClass = $active ? 'smart-listado-badge--activo' : 'smart-listado-badge--inactivo';
                            ?>
                            <span class="smart-listado-badge <?= $badgeClass ?>">
                                <?= htmlspecialchars((string) $cell, ENT_QUOTES, 'UTF-8') ?>
                            </span>
                        <?php else: ?>
                            <?= htmlspecialchars((string) $cell, ENT_QUOTES, 'UTF-8') ?>
                        <?php endif; ?>
                    </td>
                <?php endforeach; ?>
            </tr>
            <?php endforeach; ?>
            <?php endif; ?>
        </tbody>
    </table>
</div>
