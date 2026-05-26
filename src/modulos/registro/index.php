<?php
require_once __DIR__ . '/init.php';

registroRequireAccess();

if (isset($_GET['logout'])) {
    registroLogout();
}

$accent = AppConfig::themeTokensDark()['--cyan'] ?? '#00e5b0';
$blue = AppConfig::themeTokensDark()['--blue'] ?? '#4a9eff';
$purple = AppConfig::themeTokensDark()['--purple'] ?? '#9b6dff';
$orange = AppConfig::themeTokensDark()['--orange'] ?? '#ff7b2e';

$personTypes = [
    [
        'label' => 'Módulo 01',
        'title' => 'Aprendiz',
        'desc'  => 'Registro de aprendices vinculados a fichas de formación del SENA.',
        'icon'  => '🎓',
        'color' => $accent,
        'dim'   => 'rgba(0,229,176,0.1)',
        'url'   => 'forms/aprendiz.php',
    ],
    [
        'label' => 'Módulo 02',
        'title' => 'Instructor',
        'desc'  => 'Gestión de instructores de planta y contratistas del centro de formación.',
        'icon'  => '👨🏻‍🏫',
        'color' => $blue,
        'dim'   => 'rgba(74,158,255,0.1)',
        'url'   => 'forms/instructor.php',
    ],
    [
        'label' => 'Módulo 03',
        'title' => 'Funcionario',
        'desc'  => 'Registro de funcionarios administrativos y de apoyo institucional.',
        'icon'  => '🏛️',
        'color' => $purple,
        'dim'   => 'rgba(155,109,255,0.1)',
        'url'   => 'forms/funcionario.php',
    ],
    [
        'label' => 'Módulo 04',
        'title' => 'Contratista',
        'desc'  => 'Administración de contratistas y personal externo vinculado al centro.',
        'icon'  => '🛠️',
        'color' => $orange,
        'dim'   => 'rgba(255,123,46,0.1)',
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
