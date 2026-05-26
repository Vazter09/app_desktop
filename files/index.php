<?php
require_once 'includes/auth.php';
requireAuth();

if (isset($_GET['logout'])) {
    logout();
}

$personTypes = [
    [
        'id'    => 'aprendiz',
        'label' => 'Módulo 01',
        'title' => 'Aprendiz',
        'desc'  => 'Registro de aprendices vinculados a fichas de formación del SENA.',
        'icon'  => '🎓',
        'color' => '#00e5b0',
        'dim'   => 'rgba(0,229,176,0.1)',
        'url'   => 'forms/aprendiz.php',
    ],
    [
        'id'    => 'instructor',
        'label' => 'Módulo 02',
        'title' => 'Instructor',
        'desc'  => 'Gestión de instructores de planta y contratistas del centro de formación.',
        'icon'  => '👨🏻‍🏫',
        'color' => '#4a9eff',
        'dim'   => 'rgba(74,158,255,0.1)',
        'url'   => 'forms/instructor.php',
    ],
    [
        'id'    => 'funcionario',
        'label' => 'Módulo 03',
        'title' => 'Funcionario',
        'desc'  => 'Registro de funcionarios administrativos y de apoyo institucional.',
        'icon'  => '🏛️',
        'color' => '#9b6dff',
        'dim'   => 'rgba(155,109,255,0.1)',
        'url'   => 'forms/funcionario.php',
    ],
    [
        'id'    => 'contratista',
        'label' => 'Módulo 04',
        'title' => 'Contratista',
        'desc'  => 'Administración de contratistas y personal externo vinculado al centro.',
        'icon'  => '🛠️',
        'color' => '#ff7b2e',
        'dim'   => 'rgba(255,123,46,0.1)',
        'url'   => 'forms/contratista.php',
    ],
];
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SMART CSET — Panel Principal</title>
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>
    <div class="scanline"></div>

    <header class="sys-header">
        <a href="index.php" class="sys-logo">
            SMART CSET <span>// Sistema de Gestión</span>
        </a>
        <nav class="sys-nav">
            <button id="theme-toggle" class="theme-toggle" type="button" aria-label="Cambiar modo de color">🌙</button>
            <a href="index.php" class="nav-link">Inicio</a>
            <a href="?logout=1" class="btn-logout">Salir</a>
        </nav>
    </header>

    <main class="main-wrapper">
        <div class="welcome-block animate-in">
            <div>
                <p class="section-title">Panel de Control</p>
                <h1 class="section-heading">Módulos de <em>Registro</em></h1>
                <p class="section-sub">
                    Seleccione el tipo de persona para acceder al formulario de registro correspondiente.
                    Todos los datos se almacenan de forma segura en la base de datos institucional.
                </p>
            </div>
        </div>

        <div class="cards-grid animate-in" style="animation-delay:0.1s">
            <?php foreach ($personTypes as $i => $p): ?>
            <a
                href="<?= $p['url'] ?>"
                class="person-card"
                style="
                    --card-accent: <?= $p['color'] ?>;
                    --card-color: <?= $p['dim'] ?>;
                    animation-delay: <?= ($i * 0.08) ?>s;
                "
            >
                <span class="card-icon"><?= $p['icon'] ?></span>
                <div class="card-label"><?= $p['label'] ?></div>
                <div class="card-title"><?= $p['title'] ?></div>
                <div class="card-desc"><?= $p['desc'] ?></div>
                <span class="card-arrow">→</span>
            </a>
            <?php endforeach; ?>
        </div>

        <div class="footer-bar">
            <span class="footer-text">SMART CSET // Centro de Formación</span>
            <span class="footer-text">
                Usuario: <?= htmlspecialchars($_SESSION['username']) ?> //
                Sesión:<span id="session-clock"><?= (new DateTimeImmutable('now', new DateTimeZone('America/Bogota')))->format('H:i:s') ?></span>
            </span>
        </div>
    </main>
    <script>
        (function() {
            const clock = document.getElementById('session-clock');
            if (!clock) return;
            const formatter = new Intl.DateTimeFormat('es-CO', {
                hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false,
                timeZone: 'America/Bogota'
            });
            function updateClock() {
                clock.textContent = formatter.format(new Date());
            }
            updateClock();
            setInterval(updateClock, 1000);
        })();

        (function() {
            const toggle = document.getElementById('theme-toggle');
            const body = document.body;
            const storageKey = 'cset-theme-mode';
            const setTheme = theme => {
                body.classList.toggle('light-theme', theme === 'light');
                if (toggle) {
                    toggle.textContent = theme === 'light' ? '✹' : '☽';
                    toggle.title = theme === 'light' ? 'Cambiar a modo oscuro' : 'Cambiar a modo claro';
                }
                localStorage.setItem(storageKey, theme);
            };
            const savedTheme = localStorage.getItem(storageKey);
            const defaultTheme = savedTheme || (window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark');
            setTheme(defaultTheme);
            if (toggle) {
                toggle.addEventListener('click', () => {
                    setTheme(body.classList.contains('light-theme') ? 'dark' : 'light');
                });
            }
        })();
    </script>
</body>
</html>
