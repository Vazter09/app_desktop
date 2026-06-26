<?php
/**
 * LOGIN PRINCIPAL - SmartCSET
 */
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/backend/core/prepare_login.php';
require_once dirname(__DIR__, 3) . '/backend/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/backend/core/helpers.php';

if (defined('APP_ENV') && APP_ENV === 'production' && empty($_SERVER['HTTPS'])) {
    header('Location: https://' . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'], true, 301);
    exit;
}

$w_error = '';
$w_user_value = '';

if (isset($_GET['sesion'])) {
    if ($_GET['sesion'] === 'invalida') {
        $w_error = 'Su sesión ya no está activa. Ingrese nuevamente.';
    } elseif ($_GET['sesion'] === 'ip') {
        $w_error = 'Su sesión se cerró porque la conexión no coincide con la del inicio de sesión. Ingrese nuevamente.';
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars(AppConfig::nomSistema()) ?> | Ingreso</title>
    <?php smartcsetRenderBasePathBootstrap(); ?>
    <?php
    $bootstrap_vendor_mode = 'head';
    $bootstrap_asset_href = smartcsetAssetHref();
    $bootstrap_vendor_icons = false;
    include dirname(__DIR__) . '/layout/partials/bootstrap_vendor.php';
    ?>
    <?php
    $_asset_root = __DIR__ . '/assets';
    $_v_comp = @filemtime($_asset_root . '/css/components.css') ?: time();
    $_v_login = @filemtime($_asset_root . '/css/login.css') ?: time();
    ?>
    <?php include dirname(__DIR__) . '/layout/theme_vars.php'; ?>
    <link rel="stylesheet" href="<?= htmlspecialchars(smartcsetAsset('css/components.css')) ?>?v=<?= (int) $_v_comp ?>">
    <link rel="stylesheet" href="<?= htmlspecialchars(smartcsetAsset('css/login.css')) ?>?v=<?= (int) $_v_login ?>">
</head>
<body class="login-page">
    <div class="scanline" aria-hidden="true"></div>

    <div class="login-shell">
    <img src="<?= htmlspecialchars(smartcsetLogoUrl()) ?>" alt="Logo SENA" class="login-logo" id="login-logo-preview">

    <div class="card card-login shadow-lg">
        <div class="card-body p-4">
            <h4 class="text-center fw-bold mb-4 login-card__title">Control de Acceso</h4>

            <?php if ($w_error !== ''): ?>
            <div class="login-alert" role="alert" aria-live="assertive">
                <span class="login-alert__icon" aria-hidden="true">&#9888;</span>
                <div>
                    <div class="login-alert__title">Acceso denegado</div>
                    <p class="login-alert__message"><?= htmlspecialchars($w_error) ?></p>
                </div>
            </div>
            <?php endif; ?>

            <div id="loginClientError" class="login-inline-error" role="alert"></div>

            <form method="POST" autocomplete="off" id="loginForm">
                <div class="mb-3">
                    <label class="form-label small fw-bold" for="txt_usuario">Identificación</label>
                    <input type="text" id="txt_usuario" name="txt_usuario" class="form-control" required
                        placeholder="ID de usuario" value="<?= htmlspecialchars($w_user_value) ?>">
                </div>
                <div class="mb-4">
                    <label class="form-label small fw-bold" for="txt_clave">Contraseña</label>
                    <input type="password" id="txt_clave" name="txt_clave" class="form-control" required
                        placeholder="••••••••••••" minlength="8">
                </div>
                <button type="submit" class="btn btn-ingresar w-100 py-2" id="loginSubmitBtn">
                    INGRESAR AL SISTEMA
                </button>
            </form>

            <div class="text-center mt-3">
                <a href="<?= htmlspecialchars(smartcsetUrl('/pages/auth/recuperar.php')) ?>" class="text-decoration-none small login-forgot-link">¿Olvidó su contraseña?</a>
            </div>
        </div>
    </div>
    </div>

    <?php $_v_path = smartcsetAssetVersion('js/core/smartcset-path.js'); ?>
    <?php $_v_http = smartcsetAssetVersion('js/services/http-client.js'); ?>
    <?php $_v_auth = smartcsetAssetVersion('js/services/auth-router.js'); ?>
    <?php $_v_login_js = smartcsetAssetVersion('js/core/login-page.js'); ?>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/core/smartcset-path.js')) ?>?v=<?= (int) $_v_path ?>"></script>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/services/http-client.js')) ?>?v=<?= (int) $_v_http ?>"></script>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/services/auth-router.js')) ?>?v=<?= (int) $_v_auth ?>"></script>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/core/login-page.js')) ?>?v=<?= (int) $_v_login_js ?>"></script>
</body>
</html>
