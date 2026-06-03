<?php
require_once __DIR__ . '/init.php';

registroRequireAccess();

if (isset($_GET['logout'])) {
    registroLogout();
}

$personTypes = [
    [
        'label' => 'Módulo 01',
        'title' => 'Aprendiz',
        'desc'  => 'Registro de aprendices vinculados a fichas de formación del SENA.',
        'icon'  => '🎓',
        'color' => 'var(--cyan)',
        'dim'   => 'var(--cyan-dim)',
        'url'   => 'forms/aprendiz.php',
    ],
    [
        'label' => 'Módulo 02',
        'title' => 'Instructor',
        'desc'  => 'Gestión de instructores de planta y contratistas del centro de formación.',
        'icon'  => '👨‍🏫',
        'color' => 'var(--blue)',
        'dim'   => 'color-mix(in srgb, var(--blue) 14%, transparent)',
        'url'   => 'forms/instructor.php',
    ],
    [
        'label' => 'Módulo 03',
        'title' => 'Funcionario',
        'desc'  => 'Registro de funcionarios administrativos y de apoyo institucional.',
        'icon'  => '🏛️',
        'color' => 'var(--purple)',
        'dim'   => 'color-mix(in srgb, var(--purple) 14%, transparent)',
        'url'   => 'forms/funcionario.php',
    ],
    [
        'label' => 'Módulo 04',
        'title' => 'Contratista',
        'desc'  => 'Administración de contratistas y personal externo vinculado al centro.',
        'icon'  => '🛠️',
        'color' => 'var(--orange)',
        'dim'   => 'color-mix(in srgb, var(--orange) 14%, transparent)',
        'url'   => 'forms/contratista.php',
    ],
];

registroIncludeHead('Panel de registro');
registroIncludeHeader();
?>
    <main class="main-wrapper">
        <div class="welcome-block animate-in">
            <div>
                <p class="section-title">Panel de Control</p>
                <h1 class="section-heading">Módulos de <em>Registro</em></h1>
                <p class="section-sub">
                    Seleccione el tipo de persona para acceder al formulario de registro correspondiente.
                </p>
            </div>
        </div>

        <div class="cards-grid animate-in" style="animation-delay:0.1s">
            <?php foreach ($personTypes as $i => $p): ?>
            <a
                href="<?= htmlspecialchars($p['url']) ?>"
                class="person-card"
                style="
                    --card-accent: <?= htmlspecialchars($p['color']) ?>;
                    --card-color: <?= htmlspecialchars($p['dim']) ?>;
                    animation-delay: <?= ($i * 0.08) ?>s;
                "
            >
                <span class="card-icon"><?= $p['icon'] ?></span>
                <div class="card-label"><?= htmlspecialchars($p['label']) ?></div>
                <div class="card-title"><?= htmlspecialchars($p['title']) ?></div>
                <div class="card-desc"><?= htmlspecialchars($p['desc']) ?></div>
                <span class="card-arrow">→</span>
            </a>
            <?php endforeach; ?>
        </div>

        <div class="footer-bar">
            <span class="footer-text"><?= htmlspecialchars(AppConfig::nomSistema()) ?> // Centro de Formación</span>
            <span class="footer-text">
                Usuario: <?= htmlspecialchars(registroDisplayUsername()) ?> //
                Sesión: <span id="session-clock"><?= (new DateTimeImmutable('now', new DateTimeZone('America/Bogota')))->format('H:i:s') ?></span>
            </span>
        </div>
    </main>
<?php registroIncludeFooterScripts(); ?>
</body>
</html>
