<?php
declare(strict_types=1);

/**
 * Admin — nivel 2: fichas de un programa (sin repetir nombre de carrera).
 *
 * @var list<array<string, mixed>> $fichasPrograma
 * @var string $basePath
 * @var string $fechaHoy
 * @var string $programaSel
 */
?>
<nav class="inst-fichas-breadcrumb mb-3" aria-label="Navegación de programas">
    <ol class="breadcrumb mb-0">
        <li class="breadcrumb-item">
            <a href="<?= htmlspecialchars($basePath) ?>">
                <i class="bi bi-mortarboard-fill me-1"></i>Programas
            </a>
        </li>
        <li class="breadcrumb-item active" aria-current="page">
            <?= htmlspecialchars($programaSel) ?>
        </li>
    </ol>
</nav>

<div class="inst-fichas-list-compact">
    <?php foreach ($fichasPrograma as $ficha): ?>
        <?php
        $fid = (int) ($ficha['id_ficha'] ?? 0);
        $href = $basePath . '?id_ficha=' . $fid . '&fecha=' . urlencode($fechaHoy);
        ?>
        <a href="<?= htmlspecialchars($href) ?>" class="inst-ficha-row">
            <div class="inst-ficha-row-id">Ficha <?= htmlspecialchars((string) $fid) ?></div>
            <div class="inst-ficha-row-meta">
                <span><i class="bi bi-clock"></i> <?= htmlspecialchars((string) ($ficha['nom_jornada'] ?? '')) ?></span>
                <span><i class="bi bi-people"></i> <?= (int) ($ficha['num_aprendices'] ?? 0) ?> aprendices</span>
            </div>
            <span class="inst-ficha-row-arrow"><i class="bi bi-arrow-right"></i></span>
        </a>
    <?php endforeach; ?>
</div>
