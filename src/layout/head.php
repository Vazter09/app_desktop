<?php
$_asset_href = $smartcset_asset_href ?? '../../';
$_asset_root = dirname(__DIR__, 2);
$_v_layout = @filemtime($_asset_root . '/css/layout.css') ?: time();
$_v_crud   = @filemtime($_asset_root . '/css/style_crud.css') ?: time();
$_v_comp   = @filemtime($_asset_root . '/css/components.css') ?: time();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($page_title ?? 'SmartCSET') ?> | SmartCSET</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css">
    <link rel="stylesheet" href="<?= htmlspecialchars($_asset_href) ?>css/layout.css?v=<?= (int) $_v_layout ?>">
    <link rel="stylesheet" href="<?= htmlspecialchars($_asset_href) ?>css/style_crud.css?v=<?= (int) $_v_crud ?>">
    <link rel="stylesheet" href="<?= htmlspecialchars($_asset_href) ?>css/components.css?v=<?= (int) $_v_comp ?>">
    <?php if (!empty($extra_stylesheets)): ?>
    <?= $extra_stylesheets ?>
    <?php endif; ?>
    <?php include __DIR__ . '/theme_vars.php'; ?>
    <style>
        <?= isset($extra_css) ? $extra_css : '' ?>
    </style>
</head>
<body>
<script>
    (function () {
        try {
            if (localStorage.getItem('smartcset_theme') === 'light') {
                document.body.classList.add('light-theme');
            }
        } catch (err) {
            /* noop: fallback a tema oscuro por defecto */
        }
    })();
</script>
<div class="app-wrapper">
