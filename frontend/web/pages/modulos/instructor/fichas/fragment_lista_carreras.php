<?php
declare(strict_types=1);

/**
 * Admin — nivel 1: programas/carreras con fichas en ejecución.
 *
 * @var list<array{nom_programa: string, total_fichas: int, total_aprendices: int}> $carreras
 * @var string $basePath
 */
?>
<div class="inst-carreras-list">
    <?php foreach ($carreras as $carrera): ?>
        <?php
        $nom = (string) ($carrera['nom_programa'] ?? '');
        $href = $basePath . '?programa=' . rawurlencode($nom);
        $numFichas = (int) ($carrera['total_fichas'] ?? 0);
        $numAprendices = (int) ($carrera['total_aprendices'] ?? 0);
        ?>
        <a href="<?= htmlspecialchars($href) ?>" class="inst-carrera-row">
            <div class="inst-carrera-main">
                <span class="inst-carrera-nombre"><?= htmlspecialchars($nom) ?></span>
                <span class="inst-carrera-meta">
                    <?= $numFichas ?> <?= $numFichas === 1 ? 'ficha' : 'fichas' ?>
                    ·
                    <?= $numAprendices ?> aprendices
                </span>
            </div>
            <span class="inst-carrera-arrow"><i class="bi bi-chevron-right"></i></span>
        </a>
    <?php endforeach; ?>
</div>
