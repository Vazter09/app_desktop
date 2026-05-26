<?php
/**
 * Fragmento HTML del listado (sin layout). Variables: $tituloTipo, $personas.
 */
?>
<div class="registro-listado-admin" id="registro-listado-root" data-page-title="Listado — <?= htmlspecialchars($tituloTipo, ENT_QUOTES, 'UTF-8') ?>">
    <section class="panel-block">
        <div class="panel-toolbar">
            <h2>Listado — <?= htmlspecialchars($tituloTipo, ENT_QUOTES, 'UTF-8') ?></h2>
        </div>

        <div class="data-table-wrap">
            <table class="data-table" aria-label="Listado de <?= htmlspecialchars($tituloTipo, ENT_QUOTES, 'UTF-8') ?>">
                <thead>
                    <tr>
                        <th>Tipo</th>
                        <th>Documento</th>
                        <th>Nombres y apellidos</th>
                        <th>Correo</th>
                        <th>Dirección</th>
                        <th>F. Nac.</th>
                        <th>Estado</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if ($personas === []): ?>
                    <tr>
                        <td colspan="7" class="panel-status">No hay registros para este tipo.</td>
                    </tr>
                    <?php else: ?>
                    <?php foreach ($personas as $row): ?>
                    <tr>
                        <td><?= htmlspecialchars((string) $row['tipo'], ENT_QUOTES, 'UTF-8') ?></td>
                        <td class="mono"><?= htmlspecialchars((string) $row['id_persona'], ENT_QUOTES, 'UTF-8') ?></td>
                        <td><?= htmlspecialchars((string) $row['nombres'], ENT_QUOTES, 'UTF-8') ?></td>
                        <td class="truncate" title="<?= htmlspecialchars((string) $row['correo'], ENT_QUOTES, 'UTF-8') ?>">
                            <?= htmlspecialchars((string) $row['correo'], ENT_QUOTES, 'UTF-8') ?>
                        </td>
                        <td class="truncate" title="<?= htmlspecialchars((string) $row['direccion'], ENT_QUOTES, 'UTF-8') ?>">
                            <?= htmlspecialchars((string) $row['direccion'], ENT_QUOTES, 'UTF-8') ?>
                        </td>
                        <td class="mono"><?= htmlspecialchars((string) $row['fec_nacimiento'], ENT_QUOTES, 'UTF-8') ?></td>
                        <td>
                            <span class="pill <?= !empty($row['activo']) ? 'pill--ok' : 'pill--off' ?>">
                                <?= htmlspecialchars((string) $row['estado'], ENT_QUOTES, 'UTF-8') ?>
                            </span>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </section>
</div>
