<?php
$_asset_href = $smartcset_asset_href ?? '../../';
$_asset_root = dirname(__DIR__, 2);
$_v_layout = @filemtime($_asset_root . '/css/layout.css') ?: time();
$_v_crud   = @filemtime($_asset_root . '/css/style_crud.css') ?: time();
$_v_comp   = @filemtime($_asset_root . '/css/components.css') ?: time();
$_v_theme_init = @filemtime($_asset_root . '/js/theme-init.js') ?: time();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($page_title ?? 'SmartCSET') ?> | SmartCSET</title>
    <?php
    $bootstrap_vendor_mode = 'head';
    $bootstrap_asset_href = $_asset_href;
    include __DIR__ . '/partials/bootstrap_vendor.php';
    ?>
    <?php include __DIR__ . '/theme_vars.php'; ?>
    <link rel="stylesheet" href="<?= htmlspecialchars($_asset_href) ?>css/layout.css?v=<?= (int) $_v_layout ?>">
    <link rel="stylesheet" href="<?= htmlspecialchars($_asset_href) ?>css/style_crud.css?v=<?= (int) $_v_crud ?>">
    <link rel="stylesheet" href="<?= htmlspecialchars($_asset_href) ?>css/components.css?v=<?= (int) $_v_comp ?>">
    <?php if (!empty($extra_stylesheets)): ?>
    <?= $extra_stylesheets ?>
    <?php endif; ?>
    <style>
        <?= isset($extra_css) ? $extra_css : '' ?>
    </style>
</head>
<body>
<script src="<?= htmlspecialchars($_asset_href) ?>js/theme-init.js?v=<?= (int) $_v_theme_init ?>"></script>
<div class="app-wrapper">
