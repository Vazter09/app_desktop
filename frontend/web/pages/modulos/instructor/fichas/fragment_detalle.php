<?php
declare(strict_types=1);

/**
 * Fragmento: filtros + tabla de asistencia de la ficha seleccionada.
 * Requiere: $idFichaSel, $fichaSel, $asistencia, $basePath, $modoRango (opcional), $puedeEscribir (opcional).
 */

if ($idFichaSel === null || $fichaSel === null) {
    return;
}

$desde = (string) ($asistencia['desde'] ?? date('Y-m-d'));
$hasta = (string) ($asistencia['hasta'] ?? $desde);
$rows = is_array($asistencia['rows'] ?? null) ? $asistencia['rows'] : [];
$porFecha = is_array($asistencia['por_fecha'] ?? null) ? $asistencia['por_fecha'] : [];
$esUnDia = $desde === $hasta;
$fechaNav = $desde;

$diaAnterior = date('Y-m-d', strtotime($fechaNav . ' -1 day'));
$diaSiguiente = date('Y-m-d', strtotime($fechaNav . ' +1 day'));
$qBase = 'id_ficha=' . (int) $idFichaSel;

$resumenDia = $porFecha[$desde] ?? [
    'Presente' => 0,
    'Tarde' => 0,
    'Ausente' => 0,
    'Pendiente' => 0,
    'Desconocido' => 0,
    'total' => 0,
];
$puedeEscribir = !empty($puedeEscribir);
$mostrarAcciones = $puedeEscribir && $esUnDia && !$modoRango;
?>
<nav class="inst-fichas-breadcrumb mb-3" aria-label="Navegación de fichas">
    <ol class="breadcrumb mb-0">
        <li class="breadcrumb-item">
            <a href="<?= htmlspecialchars($basePath) ?>"><i class="bi bi-journal-bookmark-fill me-1"></i>Mis Fichas</a>
        </li>
        <li class="breadcrumb-item active" aria-current="page">
            Ficha <?= htmlspecialchars((string) $idFichaSel) ?>
        </li>
    </ol>
</nav>

<div class="card shadow-sm inst-detalle-card">
    <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
        <div>
            <span class="fw-semibold">Aprendices</span>
            <span class="text-muted ms-2 small"><?= htmlspecialchars((string) ($fichaSel['nom_programa'] ?? '')) ?></span>
        </div>
        <span class="badge bg-primary"><?= htmlspecialchars((string) ($fichaSel['nom_jornada'] ?? '')) ?></span>
    </div>
    <div class="card-body">
        <form method="get" class="inst-filtros-form row g-2 align-items-end mb-3" id="inst-filtros-form">
            <input type="hidden" name="id_ficha" value="<?= (int) $idFichaSel ?>">
            <div class="col-md-4">
                <label class="form-label small mb-1" for="inst_fecha">Fecha</label>
                <input type="date" class="form-control form-control-sm" id="inst_fecha" name="fecha"
                       value="<?= htmlspecialchars($esUnDia && !$modoRango ? $desde : '') ?>">
            </div>
            <div class="col-md-3">
                <label class="form-label small mb-1" for="inst_desde">Desde</label>
                <input type="date" class="form-control form-control-sm" id="inst_desde" name="desde"
                       value="<?= htmlspecialchars($modoRango ? $desde : '') ?>">
            </div>
            <div class="col-md-3">
                <label class="form-label small mb-1" for="inst_hasta">Hasta</label>
                <input type="date" class="form-control form-control-sm" id="inst_hasta" name="hasta"
                       value="<?= htmlspecialchars($modoRango ? $hasta : '') ?>">
            </div>
            <div class="col-md-2">
                <button type="submit" class="btn btn-sm btn-success w-100">Consultar</button>
            </div>
        </form>

        <?php if ($esUnDia && !$modoRango): ?>
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
                <div class="btn-group btn-group-sm">
                    <a class="btn btn-outline-secondary"
                       href="<?= htmlspecialchars($basePath . '?' . $qBase . '&fecha=' . $diaAnterior) ?>">
                        <i class="bi bi-chevron-left"></i> Anterior
                    </a>
                    <span class="btn btn-light disabled"><?= htmlspecialchars(date('d/m/Y', strtotime($desde))) ?></span>
                    <a class="btn btn-outline-secondary"
                       href="<?= htmlspecialchars($basePath . '?' . $qBase . '&fecha=' . $diaSiguiente) ?>">
                        Siguiente <i class="bi bi-chevron-right"></i>
                    </a>
                </div>
                <div class="inst-resumen-chips d-flex flex-wrap gap-2">
                    <span class="badge bg-success">Presente <?= (int) $resumenDia['Presente'] ?></span>
                    <span class="badge bg-warning text-dark">Tarde <?= (int) $resumenDia['Tarde'] ?></span>
                    <span class="badge bg-danger">Ausente <?= (int) $resumenDia['Ausente'] ?></span>
                    <span class="badge bg-secondary">Pendiente <?= (int) $resumenDia['Pendiente'] ?></span>
                </div>
            </div>
        <?php endif; ?>

        <div class="table-responsive">
            <table class="table table-sm table-hover align-middle inst-asistencia-table mb-0">
                <thead class="table-light">
                    <tr>
                        <?php if (!$esUnDia || $modoRango): ?>
                            <th>Fecha</th>
                        <?php endif; ?>
                        <th>Aprendiz</th>
                        <th>Documento</th>
                        <th>Jornada</th>
                        <th>Hora</th>
                        <th>Retardo</th>
                        <th>Estado</th>
                        <?php if ($mostrarAcciones): ?>
                            <th class="text-end">Marcar</th>
                        <?php endif; ?>
                    </tr>
                </thead>
                <tbody>
                    <?php if ($rows === []): ?>
                        <tr>
                            <td colspan="<?= (!$esUnDia || $modoRango) ? ($mostrarAcciones ? 8 : 7) : ($mostrarAcciones ? 7 : 6) ?>" class="text-center text-muted py-4">
                                Sin aprendices activos en esta ficha para el período consultado.
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($rows as $row): ?>
                            <?php
                            $estado = (string) ($row['ind_estado'] ?? '');
                            $badge = instructorBadgeEstado($estado);
                            $hora = (string) ($row['hora_asistencia'] ?? '');
                            $horaFmt = ($hora !== '' && $hora !== '00:00:00' && !in_array($estado, ['Pendiente', 'Ausente'], true))
                                ? substr($hora, 0, 5)
                                : '—';
                            $retardo = (int) ($row['minutos_retraso'] ?? 0);
                            ?>
                            <tr>
                                <?php if (!$esUnDia || $modoRango): ?>
                                    <td><?= htmlspecialchars(date('d/m/Y', strtotime((string) $row['fec_asistencia']))) ?></td>
                                <?php endif; ?>
                                <td><?= htmlspecialchars((string) ($row['nom_completo'] ?? '')) ?></td>
                                <td><?= htmlspecialchars((string) ($row['id_aprendiz'] ?? '')) ?></td>
                                <td><?= htmlspecialchars((string) ($row['nom_jornada'] ?? '')) ?></td>
                                <td><?= htmlspecialchars($horaFmt) ?></td>
                                <td><?= $retardo > 0 ? (int) $retardo . ' min' : '—' ?></td>
                                <td><span class="badge bg-<?= htmlspecialchars($badge) ?>"><?= htmlspecialchars($estado) ?></span></td>
                                <?php if ($mostrarAcciones): ?>
                                    <td class="text-end inst-asistencia-acciones">
                                        <div class="btn-group btn-group-sm" role="group" aria-label="Marcar asistencia">
                                            <?php foreach (['Presente', 'Tarde', 'Ausente'] as $opcion): ?>
                                                <button type="button"
                                                        class="btn btn-outline-secondary inst-btn-marcar"
                                                        data-aprendiz="<?= (int) ($row['id_aprendiz'] ?? 0) ?>"
                                                        data-fecha="<?= htmlspecialchars($desde) ?>"
                                                        data-estado="<?= htmlspecialchars($opcion) ?>"
                                                        data-estado-actual="<?= htmlspecialchars($estado) ?>">
                                                    <?= htmlspecialchars($opcion) ?>
                                                </button>
                                            <?php endforeach; ?>
                                        </div>
                                    </td>
                                <?php endif; ?>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>

        <?php if ($modoRango && $porFecha !== []): ?>
            <div class="mt-4">
                <h3 class="h6 text-muted mb-2">Resumen por día</h3>
                <div class="table-responsive">
                    <table class="table table-sm table-bordered mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Fecha</th>
                                <th>Presente</th>
                                <th>Tarde</th>
                                <th>Ausente</th>
                                <th>Pendiente</th>
                                <th>Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($porFecha as $fec => $tot): ?>
                                <tr>
                                    <td><?= htmlspecialchars(date('d/m/Y', strtotime((string) $fec))) ?></td>
                                    <td><?= (int) $tot['Presente'] ?></td>
                                    <td><?= (int) $tot['Tarde'] ?></td>
                                    <td><?= (int) $tot['Ausente'] ?></td>
                                    <td><?= (int) $tot['Pendiente'] ?></td>
                                    <td><?= (int) $tot['total'] ?></td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        <?php endif; ?>
    </div>
</div>
