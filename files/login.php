<?php
require_once 'includes/auth.php';

// Si ya está autenticado, redirigir al index
if (isset($_SESSION['authenticated']) && $_SESSION['authenticated'] === true) {
    header('Location: index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $usuario = trim($_POST['usuario'] ?? '');
    $clave   = $_POST['clave'] ?? '';

    if (empty($usuario) || empty($clave)) {
        $error = 'Por favor complete todos los campos.';
    } elseif (!authenticate($usuario, $clave)) {
        $error = 'Credenciales inválidas. Acceso denegado.';
        // Pequeño delay anti-brute force
        sleep(1);
    } else {
        header('Location: index.php');
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CSET SYSTEM — ACCESO SEGURO</title>
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>
    <div class="login-page">
    <div class="scanline"></div>
    <button id="theme-toggle" class="login-theme-toggle" type="button" aria-label="Cambiar modo de color">🌙</button>
    <div class="corner-deco tl"></div>
    <div class="corner-deco tr"></div>
    <div class="corner-deco bl"></div>
    <div class="corner-deco br"></div>

    <div class="login-wrapper">
        <div class="login-brand">
            <img src="img/logo-sena.png" alt="SENA" class="login-logo">
            <span class="login-brand-logo">SMART CSET</span>
            <div class="login-divider"></div>
            <p class="login-brand-sub">Sistema de Gestión de Personas</p>
        </div>

        <div class="login-panel">
            <div class="login-title">Autenticación requerida</div>

            <?php if ($error): ?>
            <div class="alert alert-error">
                <span>⚠</span> <?= htmlspecialchars($error) ?>
            </div>
            <?php endif; ?>

            <form method="POST" action="login.php" autocomplete="off">
                <div class="login-field">
                    <label for="usuario">IDENTIFICADOR DE USUARIO</label>
                    <input
                        type="text"
                        id="usuario"
                        name="usuario"
                        placeholder="ingrese su usuario"
                        value="<?= htmlspecialchars($_POST['usuario'] ?? '') ?>"
                        autocomplete="username"
                        required
                    >
                </div>

                <div class="login-field">
                    <label for="clave">CLAVE DE ACCESO</label>
                    <input
                        type="password"
                        id="clave"
                        name="clave"
                        placeholder="••••••••••••"
                        autocomplete="current-password"
                        required
                    >
                </div>

                <button type="submit" class="login-btn">
                    INICIAR SESIÓN
                </button>
            </form>

            <div class="status-bar">
                <div class="status-row">
                    <div class="status-dot"></div>
                    <span class="status-text">SISTEMA ACTIVO — CONEXIÓN SEGURA</span>
                </div>
                <span class="status-text status-time"><?= date('Y-m-d H:i') ?></span>
            </div>
        </div>
    </div>
    </div>
    <script>
        (function() {
            const toggle = document.getElementById('theme-toggle');
            const body = document.body;
            const storageKey = 'cset-theme-mode';
            const setTheme = theme => {
                body.classList.toggle('light-theme', theme === 'light');
                if (toggle) {
                    toggle.textContent = theme === 'light' ? '✹' : '☾';
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
