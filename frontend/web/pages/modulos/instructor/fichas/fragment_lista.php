<?php
declare(strict_types=1);

/**
 * Nivel 1: listado de fichas del instructor (sin detalle lateral).
 *
 * @var list<array<string, mixed>> $fichas
 * @var string $basePath
 * @var string $fechaHoy
 */
?>
<div class="inst-fichas-grid">
    <?php foreach ($fichas as $ficha): ?>
        <?php
        $fid = (int) ($ficha['id_ficha'] ?? 0);
        $href = $basePath . '?id_ficha=' . $fid . '&fecha=' . urlencode($fechaHoy);
        $origen = instructorEtiquetaOrigen((string) ($ficha['origen_vinculo'] ?? ''));
        ?>
        <a href="<?= htmlspecialchars($href) ?>" class="inst-ficha-card">
            <div class="inst-ficha-card-top">
                <span class="inst-ficha-card-id">Ficha <?= htmlspecialchars((string) $fid) ?></span>
                <span class="inst-ficha-card-count"><?= (int) ($ficha['num_aprendices'] ?? 0) ?> aprendices</span>
            </div>
            <h3 class="inst-ficha-card-programa"><?= htmlspecialchars((string) ($ficha['nom_programa'] ?? 'Sin programa')) ?></h3>
            <div class="inst-ficha-card-meta">
                <span><i class="bi bi-clock"></i> <?= htmlspecialchars((string) ($ficha['nom_jornada'] ?? '')) ?></span>
                <span class="badge rounded-pill bg-<?= ($ficha['origen_vinculo'] ?? '') === 'lider' ? 'primary' : 'info' ?>">
                    <?= htmlspecialchars($origen) ?>
                </span>
            </div>
            <span class="inst-ficha-card-cta">Ver aprendices <i class="bi bi-arrow-right"></i></span>
        </a>
    <?php endforeach; ?>
</div>
