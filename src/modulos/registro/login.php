<?php
require_once __DIR__ . '/init.php';

registroRequireModuloHabilitado();

if (registroTieneSesionStandalone()) {
    header('Location: ' . registroIndexUrl());
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $usuario = trim($_POST['usuario'] ?? '');
    $clave   = $_POST['clave'] ?? '';

    if ($usuario === '' || $clave === '') {
        $error = 'Por favor complete todos los campos.';
    } elseif (!registroAuthenticateStandalone($usuario, $clave)) {
        $error = 'Credenciales inválidas. Acceso denegado.';
        sleep(1);
    } else {
        header('Location: ' . registroIndexUrl());
        exit;
    }
}

$href = registroAssetHref();
$vReg = @filemtime(dirname(__DIR__, 3) . '/css/registro.css') ?: time();
$nom = htmlspecialchars(AppConfig::nomSistema(), ENT_QUOTES, 'UTF-8');
$logo = htmlspecialchars(smartcsetLogoUrl($href), ENT_QUOTES, 'UTF-8');
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $nom ?> — Acceso registro</title>
    <link rel="stylesheet" href="<?= htmlspecialchars($href) ?>css/registro.css?v=<?= (int) $vReg ?>">
    <?php include dirname(__DIR__, 2) . '/layout/theme_vars.php'; ?>
</head>
<body class="registro-theme">
<?php registroThemeInitScript(); ?>
    <div class="login-page">
    <div class="scanline"></div>
    <button id="theme-toggle" class="login-theme-toggle" type="button" aria-label="Cambiar modo de color">🌙</button>
    <div class="corner-deco tl"></div>
    <div class="corner-deco tr"></div>
    <div class="corner-deco bl"></div>
    <div class="corner-deco br"></div>

    <div class="login-wrapper">
        <div class="login-brand">
            <img src="<?= $logo ?>" alt="Logo" class="login-logo">
            <span class="login-brand-logo"><span>Smart</span><span>CSET</span></span>
            <div class="login-divider"></div>
            <p class="login-brand-sub">Registro de personas</p>
        </div>

        <div class="login-panel">
            <h1 class="login-heading">Autenticación requerida</h1>

            <?php if ($error): ?>
            <div class="alert alert-error">
                <span>⚠</span> <?= htmlspecialchars($error) ?>
            </div>
            <?php endif; ?>

            <form method="POST" action="login.php" autocomplete="off">
                <div class="login-field">
                    <label for="usuario">IDENTIFICADOR DE USUARIO</label>
                    <input type="text" id="usuario" name="usuario" placeholder="Ingrese su usuario"
                        value="<?= htmlspecialchars($_POST['usuario'] ?? '') ?>" required>
                </div>
                <div class="login-field">
                    <label for="clave">CLAVE DE ACCESO</label>
                    <input type="password" id="clave" name="clave" placeholder="••••••••••••" required>
                </div>
                <button type="submit" class="login-btn">Iniciar sesión</button>
            </form>
        </div>
    </div>
    </div>
    <script src="<?= htmlspecialchars($href) ?>js/registro-theme-toggle.js"></script>
</body>
</html>
