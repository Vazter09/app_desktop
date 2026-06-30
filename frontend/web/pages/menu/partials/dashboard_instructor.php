<?php
declare(strict_types=1);

/** @var array<string, mixed> $instructor_resumen */
/** @var string|null $path_fichas */
/** @var string $kpi_error */

$hoy = $instructor_resumen['hoy'] ?? [];
$presentes = (int) ($hoy['Presente'] ?? 0);
$tarde = (int) ($hoy['Tarde'] ?? 0);
$ausentes = (int) ($hoy['Ausente'] ?? 0);
$pendientes = (int) ($hoy['Pendiente'] ?? 0);
$fechaLabel = smartcsetFormatDbTimestamp($instructor_resumen['fecha'] ?? date('Y-m-d'), 'd/m/Y');
$urlFichas = $path_fichas !== null ? smartcsetUrlNomPrograma($path_fichas) : null;
?>

<header class="dash2-hero">
    <div class="dash2-hero-top">
        <div class="dash2-welcome">
            <span class="dash2-eyebrow"><i class="bi bi-mortarboard-fill"></i> Panel instructor</span>
            <h2>Bienvenido, <span><?= htmlspecialchars($wnom_usuario) ?></span></h2>
            <p>Resumen de asistencia de tus fichas para hoy (<?= htmlspecialchars($fechaLabel) ?>). Consulte el detalle por ficha en Las fichas del instructor.</p>
        </div>
        <?php if ($urlFichas !== null): ?>
        <div class="dash2-chips">
            <a href="<?= htmlspecialchars($urlFichas) ?>" class="dash2-chip">
                <i class="bi bi-journal-bookmark-fill"></i>
                <span>Ver <strong>fichas del instructor</strong></span>
                <i class="bi bi-chevron-right"></i>
            </a>
        </div>
        <?php endif; ?>
    </div>

    <div class="dash2-kpis" aria-label="Indicadores de asistencia">
        <div class="dash2-kpi">
            <span class="dash2-kpi-icon"><i class="bi bi-card-list"></i></span>
            <div class="dash2-kpi-body">
                <span class="dash2-kpi-value"><?= (int) ($instructor_resumen['total_fichas'] ?? 0) ?></span>
                <span class="dash2-kpi-label">Fichas activas</span>
            </div>
        </div>
        <div class="dash2-kpi">
            <span class="dash2-kpi-icon"><i class="bi bi-people-fill"></i></span>
            <div class="dash2-kpi-body">
                <span class="dash2-kpi-value"><?= (int) ($instructor_resumen['total_aprendices'] ?? 0) ?></span>
                <span class="dash2-kpi-label">Aprendices</span>
            </div>
        </div>
        <div class="dash2-kpi dash2-kpi--highlight">
            <span class="dash2-kpi-icon"><i class="bi bi-check-circle-fill"></i></span>
            <div class="dash2-kpi-body">
                <span class="dash2-kpi-value"><?= $presentes + $tarde ?></span>
                <span class="dash2-kpi-label">Asistieron hoy</span>
            </div>
        </div>
        <div class="dash2-kpi">
            <span class="dash2-kpi-icon"><i class="bi bi-x-circle-fill"></i></span>
            <div class="dash2-kpi-body">
                <span class="dash2-kpi-value"><?= $ausentes + $pendientes ?></span>
                <span class="dash2-kpi-label">Sin ingreso / ausentes</span>
            </div>
        </div>
    </div>
</header>

<?php if ($kpi_error !== ''): ?>
<div class="alert alert-danger py-2 px-3" role="alert">
    <i class="bi bi-exclamation-triangle-fill me-1"></i>
    <?= htmlspecialchars($kpi_error) ?>
</div>
<?php endif; ?>

<?php if (!empty($instructor_resumen['por_ficha'])): ?>
<div class="dash2-main dash2-main--instructor">
    <section class="dash2-panel dash2-fichas-hoy" aria-label="Asistencia por ficha">
        <div class="dash2-section-title">
            <i class="bi bi-calendar-check"></i>
            Asistencia por ficha
            <span class="dash2-section-meta">hoy</span>
        </div>
        <div class="dash2-fichas-grid">
            <?php foreach ($instructor_resumen['por_ficha'] as $item): ?>
            <?php
                $ficha = $item['ficha'] ?? [];
                $resumen = $item['resumen'] ?? [];
                $idFicha = (int) ($ficha['id_ficha'] ?? 0);
                $detalleUrl = $urlFichas !== null && $idFicha > 0
                    ? $urlFichas . '?id_ficha=' . $idFicha
                    : null;
            ?>
            <article class="dash2-ficha-card">
                <div class="dash2-ficha-card-head">
                    <div>
                        <span class="dash2-ficha-num">Ficha <?= htmlspecialchars((string) ($ficha['id_ficha'] ?? '')) ?></span>
                        <h3 class="dash2-ficha-programa" title="<?= htmlspecialchars((string) ($ficha['nom_programa'] ?? '')) ?>">
                            <?= htmlspecialchars((string) ($ficha['nom_programa'] ?? 'Sin programa')) ?>
                        </h3>
                    </div>
                    <span class="badge bg-<?= ($ficha['origen_vinculo'] ?? '') === 'lider' ? 'primary' : 'info' ?>">
                        <?= htmlspecialchars(instructorEtiquetaOrigen((string) ($ficha['origen_vinculo'] ?? ''))) ?>
                    </span>
                </div>
                <p class="dash2-ficha-meta">
                    <i class="bi bi-clock"></i>
                    <?= htmlspecialchars((string) ($ficha['nom_jornada'] ?? 'Sin jornada')) ?>
                    · <?= (int) ($ficha['num_aprendices'] ?? 0) ?> aprendices
                </p>
                <div class="dash2-ficha-stats">
                    <span class="dash2-ficha-stat dash2-ficha-stat--ok">
                        <strong><?= (int) ($resumen['Presente'] ?? 0) ?></strong> Presente
                    </span>
                    <span class="dash2-ficha-stat dash2-ficha-stat--warn">
                        <strong><?= (int) ($resumen['Tarde'] ?? 0) ?></strong> Tarde
                    </span>
                    <span class="dash2-ficha-stat dash2-ficha-stat--danger">
                        <strong><?= (int) ($resumen['Ausente'] ?? 0) ?></strong> Ausente
                    </span>
                    <span class="dash2-ficha-stat dash2-ficha-stat--muted">
                        <strong><?= (int) ($resumen['Pendiente'] ?? 0) ?></strong> Pendiente
                    </span>
                </div>
                <?php if ($detalleUrl !== null): ?>
                <a href="<?= htmlspecialchars($detalleUrl) ?>" class="dash2-ficha-link">
                    Ver detalle <i class="bi bi-arrow-right"></i>
                </a>
                <?php endif; ?>
            </article>
            <?php endforeach; ?>
        </div>
    </section>

    <?php if (!empty($quick_actions)): ?>
    <section class="dash2-panel dash2-actions" aria-label="Acciones rápidas">
        <div class="dash2-section-title"><i class="bi bi-lightning-charge-fill"></i> Acciones rápidas</div>
        <div class="dash2-actions-list">
            <?php foreach ($quick_actions as $cta): ?>
            <a href="<?= htmlspecialchars($cta['url']) ?>" class="dash2-action <?= htmlspecialchars($cta['class']) ?>">
                <span class="dash2-action-icon"><i class="bi <?= htmlspecialchars($cta['icon']) ?>"></i></span>
                <span class="dash2-action-label"><?= htmlspecialchars($cta['label']) ?></span>
                <i class="bi bi-arrow-right dash2-action-arrow"></i>
            </a>
            <?php endforeach; ?>
        </div>
    </section>
    <?php endif; ?>
</div>
<?php elseif ($urlFichas !== null): ?>
<div class="card guide-card guide-card--warning guide-card--compact border-0 shadow-sm">
    <div class="guide-card-header py-2">
        <div class="guide-card-icon" style="width:2rem;height:2rem;font-size:0.95rem;">
            <i class="bi bi-journal-x"></i>
        </div>
        <div>
            <p class="guide-card-title mb-0" style="font-size:0.9rem;">Sin fichas asignadas</p>
            <p class="guide-card-subtitle mb-0" style="font-size:0.8rem;">No tiene fichas en ejecución ni programación vigente.</p>
        </div>
    </div>
</div>
<?php endif; ?>
