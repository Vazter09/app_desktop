<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/init.php';

$w_mensaje = '';
$w_tipo_alerta = 'info';
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title><?= htmlspecialchars(AppConfig::nomSistema()) ?> | Recuperar Clave</title>
    <?php smartcsetRenderBasePathBootstrap(); ?>
    <?php
    $bootstrap_vendor_mode = 'head';
    $bootstrap_asset_href = smartcsetAssetHref();
    include smartcsetLayoutPath('partials/bootstrap_vendor.php');
    ?>
    <?php $_v_auth_rec = @filemtime(dirname(__DIR__, 2) . '/public/assets/css/auth-recuperar.css') ?: time(); ?>
    <link rel="stylesheet" href="<?= htmlspecialchars(smartcsetAsset('css/components.css')) ?>">
    <link rel="stylesheet" href="<?= htmlspecialchars(smartcsetAsset('css/auth-recuperar.css')) ?>?v=<?= (int) $_v_auth_rec ?>">
</head>
<body class="auth-recuperar-page">
<img src="<?= htmlspecialchars(smartcsetLogoUrl()) ?>" alt="Logo" class="logo-derecha">
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-5">
            <div class="card card-recuperar">
                <div class="bg-dark p-4 text-center rounded-top">
                    <h4 class="text-white mb-0">Recuperación de Acceso</h4>
                </div>
                <div class="card-body p-4">
                    <?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

                    <form id="form-recuperar" action="#" method="POST" autocomplete="off">
                        <div class="mb-3">
                            <label class="small fw-bold">ID de Usuario</label>
                            <input type="text" name="txt_usuario" class="form-control" required placeholder="Usuario">
                        </div>
                        <div class="mb-3">
                            <label class="small fw-bold d-block mb-2">Método de entrega</label>
                            <div class="form-check form-check-inline">
                                <input class="form-check-input" type="radio" name="rdo_metodo" value="correo" checked>
                                <label class="form-check-label small">Correo</label>
                            </div>
                            <div class="form-check form-check-inline">
                                <input class="form-check-input" type="radio" name="rdo_metodo" value="pantalla">
                                <label class="form-check-label small">Pantalla</label>
                            </div>
                        </div>
                        <div id="w_div_correo" class="mb-4">
                            <label class="small fw-bold">Confirme su Correo</label>
                            <input type="email" name="txt_correo" id="w_txt_correo" class="form-control" required>
                        </div>
                        <button type="submit" class="btn btn-verde w-100 py-2 fw-bold">PROCESAR</button>
                        <div class="text-center mt-3"><a href="<?= htmlspecialchars(smartcsetUrl('/index.php')) ?>" class="small text-muted text-decoration-none">Cancelar</a></div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<?php
$_ar = dirname(__DIR__, 2) . '/public/assets';
$_v_http = @filemtime($_ar . '/js/services/http-client.js') ?: time();
$_v_auth = @filemtime($_ar . '/js/services/auth-router.js') ?: time();
$_v_rec = @filemtime($_ar . '/js/core/recuperar.js') ?: time();
?>
<script src="<?= htmlspecialchars(smartcsetAsset('js/core/smartcset-path.js')) ?>?v=<?= smartcsetAssetVersion('js/core/smartcset-path.js') ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/services/http-client.js')) ?>?v=<?= smartcsetAssetVersion('js/services/http-client.js') ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/services/auth-router.js')) ?>?v=<?= smartcsetAssetVersion('js/services/auth-router.js') ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/core/recuperar.js')) ?>?v=<?= smartcsetAssetVersion('js/core/recuperar.js') ?>"></script>
<?php $ui_assets_prefix = smartcsetAssetHref(); include smartcsetLayoutPath('ui_kit.php'); ?>
</body>
</html>
