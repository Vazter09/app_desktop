<?php
require_once __DIR__ . '/init.php';

registroRequireModuloHabilitado();

if (!registroUsaLoginStandalone()) {
    // El módulo usa la sesión principal + menú asignado — este login separado ya no aplica.
    header('Location: ' . (registroTieneSesionPrincipal() ? registroIndexUrl() : registroMainLoginUrl()));
    exit;
}

if (registroTieneSesionStandalone()) {
    header('Location: ' . registroIndexUrl());
    exit;
}

$href = smartcsetAssetHref();
$vReg = @filemtime(dirname(__DIR__, 3) . '/public/assets/css/registro.css') ?: time();
$nom = htmlspecialchars(AppConfig::nomSistema(), ENT_QUOTES, 'UTF-8');
$logo = htmlspecialchars(smartcsetLogoUrl(), ENT_QUOTES, 'UTF-8');
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $nom ?> — Acceso registro</title>
    <?php smartcsetRenderBasePathBootstrap(); ?>
    <link rel="stylesheet" href="<?= htmlspecialchars(smartcsetAsset('css/registro.css')) ?>?v=<?= (int) $vReg ?>">
    <?php include dirname(__DIR__, 3) . '/layout/theme_vars.php'; ?>
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

            <div class="alert alert-error" id="registro-login-error" style="display:none;" role="alert">
                <span>⚠</span> <span id="registro-login-error-text"></span>
            </div>

            <form method="POST" id="form-registro-login" action="#" autocomplete="off">
                <div class="login-field">
                    <label for="usuario">IDENTIFICADOR DE USUARIO</label>
                    <input type="text" id="usuario" name="usuario" placeholder="Ingrese su usuario" required>
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
    <?php $_ar = dirname(__DIR__, 3) . '/public/assets'; ?>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/core/registro-theme-toggle.js')) ?>"></script>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/core/smartcset-path.js')) ?>"></script>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/services/http-client.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/services/http-client.js') ?: time()) ?>"></script>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/services/registro-router.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/services/registro-router.js') ?: time()) ?>"></script>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/core/registro-login.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/core/registro-login.js') ?: time()) ?>"></script>
</body>
</html>
