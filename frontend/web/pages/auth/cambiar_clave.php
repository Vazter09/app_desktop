<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

$mensaje = '';
$alerta = 'info';
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title><?= htmlspecialchars(AppConfig::nomSistema()) ?> | Cambiar Clave</title>
    <?php smartcsetRenderBasePathBootstrap(); ?>
    <?php
    $bootstrap_vendor_mode = 'head';
    $bootstrap_asset_href = smartcsetAssetHref();
    $bootstrap_vendor_icons = false;
    include smartcsetLayoutPath('partials/bootstrap_vendor.php');
    ?>
    <?php $_v_auth_cc = @filemtime(dirname(__DIR__, 2) . '/public/assets/css/auth-cambiar-clave.css') ?: time(); ?>
    <link rel="stylesheet" href="<?= htmlspecialchars(smartcsetAsset('css/components.css')) ?>">
    <link rel="stylesheet" href="<?= htmlspecialchars(smartcsetAsset('css/auth-cambiar-clave.css')) ?>?v=<?= (int) $_v_auth_cc ?>">
</head>
<body class="bg-light auth-cambiar-clave-page">
<img src="<?= htmlspecialchars(smartcsetLogoUrl()) ?>" alt="Logo" class="logo-derecha">
<div class="container d-flex justify-content-center align-items-center auth-shell">
    <div class="card shadow-sm border-0 auth-card">
        <div class="card-header bg-dark text-white text-center py-3">
            <h5 class="mb-0 fw-bold">CAMBIAR CONTRASEÑA</h5>
        </div>
        <div class="card-body p-4">
            <?php renderPageFlash($mensaje, $alerta); ?>

            <form method="POST" id="form-cambiar-clave" action="#" autocomplete="off">
                <div class="mb-3">
                    <label class="small fw-bold">CONTRASEÑA ANTERIOR</label>
                    <input type="password" name="wpass_antigua" class="form-control" required>
                </div>
                <hr>
                <div class="mb-3">
                    <label class="small fw-bold">NUEVA CONTRASEÑA</label>
                    <input type="password" name="wpass_nueva" class="form-control" minlength="12" required>
                </div>
                <div class="row g-2">
                    <div class="col-6"><a href="<?= htmlspecialchars(smartcsetUrl('/pages/menu/menu_principal.php')) ?>" class="btn btn-secondary w-100">Regresar</a></div>
                    <div class="col-6"><button type="submit" class="btn btn-primary w-100 btn-guardar-institucional">Guardar</button></div>
                </div>
            </form>
        </div>
    </div>
</div>
<?php
$_ar = dirname(__DIR__, 2) . '/public/assets';
$_v_http = @filemtime($_ar . '/js/services/http-client.js') ?: time();
$_v_auth = @filemtime($_ar . '/js/services/auth-router.js') ?: time();
$_v_cc = @filemtime($_ar . '/js/core/auth-cambiar-clave.js') ?: time();
?>
<script src="<?= htmlspecialchars(smartcsetAsset('js/core/smartcset-path.js')) ?>?v=<?= smartcsetAssetVersion('js/core/smartcset-path.js') ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/services/http-client.js')) ?>?v=<?= smartcsetAssetVersion('js/services/http-client.js') ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/services/auth-router.js')) ?>?v=<?= smartcsetAssetVersion('js/services/auth-router.js') ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/core/auth-cambiar-clave.js')) ?>?v=<?= smartcsetAssetVersion('js/core/auth-cambiar-clave.js') ?>"></script>
<?php $ui_assets_prefix = smartcsetAssetHref(); include smartcsetLayoutPath('ui_kit.php'); ?>
</body>
</html>
