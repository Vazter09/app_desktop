<?php
/**
 * Fragmento HTML del listado (sin layout). Variables: $tituloTipo, $personas.
 */
?>
<div class="registro-listado-admin" id="registro-listado-root" data-page-title="Listado — <?= htmlspecialchars($tituloTipo, ENT_QUOTES, 'UTF-8') ?>">
    <div class="row g-3">
        <div class="col-12">
            <div class="card shadow-sm border-0">
                <div class="card-header bg-corporativo py-2 d-flex flex-wrap justify-content-between align-items-center gap-2">
                    <strong style="font-size:0.95rem;">
                        <i class="bi bi-person-vcard-fill me-2"></i>Listado — <?= htmlspecialchars($tituloTipo, ENT_QUOTES, 'UTF-8') ?>
                        <span class="badge bg-light text-dark ms-1" style="font-size:0.72rem;"><?= count($personas) ?></span>
                    </strong>
                </div>
                <div class="table-responsive scroll-lista">
                    <table class="table table-hover align-middle mb-0 table-sm" aria-label="Listado de <?= htmlspecialchars($tituloTipo, ENT_QUOTES, 'UTF-8') ?>">
                        <thead class="thead-oliva sticky-top">
                            <tr style="font-size:0.85rem;">
                                <th class="ps-3 py-2">Tipo</th>
                                <th class="py-2">Documento</th>
                                <th class="py-2">Nombres y apellidos</th>
                                <th class="py-2">Correo</th>
                                <th class="py-2">Dirección</th>
                                <th class="py-2">F. Nac.</th>
                                <th class="py-2 text-center">Estado</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if ($personas === []): ?>
                            <tr>
                                <td colspan="7" class="text-center text-muted py-4 small">
                                    No hay registros para este tipo.
                                </td>
                            </tr>
                            <?php else: ?>
                            <?php foreach ($personas as $row): ?>
                            <tr style="font-size:0.875rem;">
                                <td class="ps-3 py-2 fw-semibold"><?= htmlspecialchars((string) $row['tipo'], ENT_QUOTES, 'UTF-8') ?></td>
                                <td class="py-2 fw-bold"><?= htmlspecialchars((string) $row['id_persona'], ENT_QUOTES, 'UTF-8') ?></td>
                                <td class="py-2"><?= htmlspecialchars((string) $row['nombres'], ENT_QUOTES, 'UTF-8') ?></td>
                                <td class="py-2 text-truncate" style="max-width:220px;" title="<?= htmlspecialchars((string) $row['correo'], ENT_QUOTES, 'UTF-8') ?>">
                                    <?= htmlspecialchars((string) $row['correo'], ENT_QUOTES, 'UTF-8') ?>
                                </td>
                                <td class="py-2 text-truncate" style="max-width:280px;" title="<?= htmlspecialchars((string) $row['direccion'], ENT_QUOTES, 'UTF-8') ?>">
                                    <?= htmlspecialchars((string) $row['direccion'], ENT_QUOTES, 'UTF-8') ?>
                                </td>
                                <td class="py-2 fw-semibold"><?= htmlspecialchars((string) $row['fec_nacimiento'], ENT_QUOTES, 'UTF-8') ?></td>
                                <td class="py-2 text-center">
                                    <span class="badge <?= !empty($row['activo']) ? 'text-bg-success' : 'text-bg-secondary' ?>">
                                        <?= htmlspecialchars((string) $row['estado'], ENT_QUOTES, 'UTF-8') ?>
                                    </span>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
