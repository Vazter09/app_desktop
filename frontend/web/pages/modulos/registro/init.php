<?php
declare(strict_types=1);

/**
 * Init del módulo registro standalone.
 */
require_once dirname(__DIR__, 3) . '/init.php';
require_once dirname(__DIR__, 5) . '/backend/services/registro/access.php';
require_once dirname(__DIR__, 5) . '/backend/services/registro/catalogos.php';
require_once dirname(__DIR__, 5) . '/backend/services/registro/registro_persistencia.php';

function registroLayout(string $relative): string
{
    return smartcsetLayoutPath(ltrim(str_replace('layout/', '', $relative), '/'));
}

function registroAssetHref(): string
{
    return smartcsetAssetHref();
}

function registroFormsAssetHref(): string
{
    return smartcsetUrl('/pages/modulos/registro/');
}

function registroThemeInitScript(): void
{
    $v = @filemtime(dirname(__DIR__, 3) . '/public/assets/js/core/theme-init.js') ?: time();
    echo '<script src="' . htmlspecialchars(smartcsetAsset('js/core/theme-init.js')) . '?v=' . (int) $v . '"></script>';
}

function registroIncludeHead(string $pageTitle, string $panelAccent = ''): void
{
    $vReg = @filemtime(dirname(__DIR__, 3) . '/public/assets/css/registro.css') ?: time();
    $nom = htmlspecialchars(AppConfig::nomSistema(), ENT_QUOTES, 'UTF-8');
    $title = htmlspecialchars($pageTitle, ENT_QUOTES, 'UTF-8');
    ?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $title ?> | <?= $nom ?></title>
    <?php smartcsetRenderBasePathBootstrap(); ?>
    <link rel="stylesheet" href="<?= htmlspecialchars(smartcsetAsset('css/registro.css')) ?>?v=<?= (int) $vReg ?>">
    <?php include dirname(__DIR__, 3) . '/layout/theme_vars.php'; ?>
</head>
<body class="registro-theme"<?= $panelAccent !== '' ? ' style="--panel-accent:' . htmlspecialchars($panelAccent, ENT_QUOTES, 'UTF-8') . '"' : '' ?>>
<?php registroThemeInitScript(); ?>
    <div class="scanline"></div>
    <?php
}

function registroIncludeHeader(string $currentLabel = ''): void
{
    $indexUrl = registroIndexUrl();
    $logoutUrl = htmlspecialchars(
        registroUsaLoginStandalone() ? (registroIndexUrl() . '?logout=1') : (registroMenuUrl()),
        ENT_QUOTES,
        'UTF-8'
    );
    $nom = htmlspecialchars(AppConfig::nomSistema(), ENT_QUOTES, 'UTF-8');
    ?>
    <header class="sys-header">
        <a href="<?= htmlspecialchars($indexUrl, ENT_QUOTES, 'UTF-8') ?>" class="sys-logo">
            <?= $nom ?> <span>// Sistema de Gestión</span>
        </a>
        <nav class="sys-nav">
            <button id="theme-toggle" class="theme-toggle" type="button" aria-label="Cambiar modo de color">🌙</button>
            <a href="<?= htmlspecialchars($indexUrl, ENT_QUOTES, 'UTF-8') ?>" class="nav-link">Inicio</a>
            <a href="<?= $logoutUrl ?>" class="btn-logout">Salir</a>
        </nav>
    </header>
    <?php
}

function registroIncludeFooterScripts(): void
{
    $ar = dirname(__DIR__, 3) . '/public/assets';
    $vClock = @filemtime($ar . '/js/core/registro-session-clock.js') ?: time();
    ?>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/core/registro-theme-toggle.js')) ?>"></script>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/core/registro-session-clock.js')) ?>?v=<?= (int) $vClock ?>"></script>
    <?php
}

function registroIncludeRouterScripts(): void
{
    $ar = dirname(__DIR__, 3) . '/public/assets';
    ?>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/core/smartcset-path.js')) ?>?v=<?= smartcsetAssetVersion('js/core/smartcset-path.js') ?>"></script>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/services/http-client.js')) ?>?v=<?= smartcsetAssetVersion('js/services/http-client.js') ?>"></script>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/services/registro-router.js')) ?>?v=<?= smartcsetAssetVersion('js/services/registro-router.js') ?>"></script>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/core/registro-form-submit.js')) ?>?v=<?= smartcsetAssetVersion('js/core/registro-form-submit.js') ?>"></script>
    <?php
}
