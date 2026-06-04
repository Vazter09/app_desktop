<?php
declare(strict_types=1);

/**
 * Bootstrap 5.3.0 + Bootstrap Icons 1.10.0 (assets locales, sin CDN).
 *
 * Variables de entrada:
 * - $bootstrap_vendor_mode: 'head' | 'scripts' (requerido)
 * - $bootstrap_asset_href: prefijo hacia la raíz del proyecto (ej. '../../', '')
 * - $bootstrap_vendor_icons: incluir CSS de iconos en head (default true)
 */
$_bv_root = dirname(__DIR__, 3);
$_bv_href = (string) ($bootstrap_asset_href ?? $smartcset_asset_href ?? '../../');
$_bv_href_esc = htmlspecialchars($_bv_href, ENT_QUOTES, 'UTF-8');
$_bv_v_bs_css = (int) (@filemtime($_bv_root . '/css/vendor/bootstrap-5.3.0/bootstrap.min.css') ?: time());
$_bv_v_bi_css = (int) (@filemtime($_bv_root . '/css/vendor/bootstrap-icons-1.10.0/bootstrap-icons.css') ?: time());
$_bv_v_bs_js = (int) (@filemtime($_bv_root . '/js/vendor/bootstrap-5.3.0/bootstrap.bundle.min.js') ?: time());
$_bv_icons = $bootstrap_vendor_icons ?? true;
$_bv_mode = $bootstrap_vendor_mode ?? 'head';

if ($_bv_mode === 'head') {
    ?>
    <link rel="stylesheet" href="<?= $_bv_href_esc ?>css/vendor/bootstrap-5.3.0/bootstrap.min.css?v=<?= $_bv_v_bs_css ?>">
    <?php if ($_bv_icons) { ?>
    <link rel="stylesheet" href="<?= $_bv_href_esc ?>css/vendor/bootstrap-icons-1.10.0/bootstrap-icons.css?v=<?= $_bv_v_bi_css ?>">
    <?php } ?>
    <?php
} elseif ($_bv_mode === 'scripts') {
    ?>
    <script src="<?= $_bv_href_esc ?>js/vendor/bootstrap-5.3.0/bootstrap.bundle.min.js?v=<?= $_bv_v_bs_js ?>"></script>
    <?php
}
