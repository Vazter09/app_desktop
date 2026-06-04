<?php
/**
 * Barra de filtros reutilizable (GET).
 * Variable: $listadoFiltros — action, fields[], values[], reset_url?, form_id?, extra_class?
 */
declare(strict_types=1);

if (!isset($listadoFiltros) || !is_array($listadoFiltros)) {
    return;
}

$action = (string) ($listadoFiltros['action'] ?? '');
$fields = $listadoFiltros['fields'] ?? [];
$values = $listadoFiltros['values'] ?? [];
$resetUrl = (string) ($listadoFiltros['reset_url'] ?? $action);
$formId = (string) ($listadoFiltros['form_id'] ?? 'smart-listado-filtros');
$formClass = 'smart-listado-filtros ' . (string) ($listadoFiltros['extra_class'] ?? '');
?>
<form method="get"
      action="<?= htmlspecialchars($action, ENT_QUOTES, 'UTF-8') ?>"
      id="<?= htmlspecialchars($formId, ENT_QUOTES, 'UTF-8') ?>"
      class="<?= htmlspecialchars(trim($formClass), ENT_QUOTES, 'UTF-8') ?>"
      data-smart-listado-filtros="1">
    <div class="row g-2 align-items-end">
        <?php foreach ($fields as $field): ?>
            <?php
            if (!is_array($field)) {
                continue;
            }
            $name = (string) ($field['name'] ?? '');
            if ($name === '') {
                continue;
            }
            $type = (string) ($field['type'] ?? 'text');
            $label = (string) ($field['label'] ?? $name);
            $col = (string) ($field['col'] ?? 'col-md-3');
            $value = $values[$name] ?? ($field['default'] ?? '');
            ?>
            <div class="<?= htmlspecialchars($col, ENT_QUOTES, 'UTF-8') ?>">
                <label class="form-label small fw-bold mb-1" for="<?= htmlspecialchars($formId . '_' . $name, ENT_QUOTES, 'UTF-8') ?>">
                    <?= htmlspecialchars($label, ENT_QUOTES, 'UTF-8') ?>
                </label>
                <?php if ($type === 'select'): ?>
                    <select name="<?= htmlspecialchars($name, ENT_QUOTES, 'UTF-8') ?>"
                            id="<?= htmlspecialchars($formId . '_' . $name, ENT_QUOTES, 'UTF-8') ?>"
                            class="form-select form-select-sm">
                        <?php foreach (($field['options'] ?? []) as $optVal => $optLabel): ?>
                            <option value="<?= htmlspecialchars((string) $optVal, ENT_QUOTES, 'UTF-8') ?>"
                                <?= (string) $value === (string) $optVal ? 'selected' : '' ?>>
                                <?= htmlspecialchars((string) $optLabel, ENT_QUOTES, 'UTF-8') ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                <?php else: ?>
                    <input type="<?= htmlspecialchars($type, ENT_QUOTES, 'UTF-8') ?>"
                           name="<?= htmlspecialchars($name, ENT_QUOTES, 'UTF-8') ?>"
                           id="<?= htmlspecialchars($formId . '_' . $name, ENT_QUOTES, 'UTF-8') ?>"
                           class="form-control form-control-sm"
                           value="<?= htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8') ?>"
                           placeholder="<?= htmlspecialchars((string) ($field['placeholder'] ?? ''), ENT_QUOTES, 'UTF-8') ?>"
                           <?= !empty($field['maxlength']) ? 'maxlength="' . (int) $field['maxlength'] . '"' : '' ?>>
                <?php endif; ?>
            </div>
        <?php endforeach; ?>
        <div class="col-auto ms-auto d-flex flex-wrap gap-2 pb-1">
            <button type="submit" class="btn btn-sm fw-bold text-white" style="background:var(--v-oscuro);">
                <i class="bi bi-funnel-fill me-1"></i>Filtrar
            </button>
            <?php if ($resetUrl !== ''): ?>
            <a href="<?= htmlspecialchars($resetUrl, ENT_QUOTES, 'UTF-8') ?>"
               class="btn btn-sm btn-outline-secondary"
               data-smart-listado-reset="1">
                Limpiar
            </a>
            <?php endif; ?>
        </div>
    </div>
</form>
