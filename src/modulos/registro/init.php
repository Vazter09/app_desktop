<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/core/prepare.php';
require_once dirname(__DIR__, 2) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 2) . '/core/helpers.php';
require_once __DIR__ . '/lib/access.php';
require_once __DIR__ . '/lib/catalogos.php';

/** @var PDO $pdo */
/** @var PDOStatement $stmt_fun_registrar_persona */
/** @var PDOStatement $stmt_fun_registrar_contratista */
/** @var PDOStatement $stmt_fun_registrar_aprendiz */
/** @var PDOStatement $stmt_fun_registrar_instructor */
/** @var PDOStatement $stmt_fun_registrar_funcionario */

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$smartcset_asset_href = smartcsetModulosAssetHref();

function registroAssetHref(): string
{
    global $smartcset_asset_href;
    return $smartcset_asset_href;
}

function registroFormsAssetHref(): string
{
    return registroAssetHref() . '../';
}

function registroThemeInitScript(): void
{
    $href = registroAssetHref();
    $v = @filemtime(dirname(__DIR__, 3) . '/js/theme-init.js') ?: time();
    ?>
<script src="<?= htmlspecialchars($href) ?>js/theme-init.js?v=<?= (int) $v ?>"></script>
    <?php
}

function registroIncludeHead(string $pageTitle, string $panelAccent = ''): void
{
    $href = registroAssetHref();
    $vReg = @filemtime(dirname(__DIR__, 3) . '/css/registro.css') ?: time();
    $nom = htmlspecialchars(AppConfig::nomSistema(), ENT_QUOTES, 'UTF-8');
    $title = htmlspecialchars($pageTitle, ENT_QUOTES, 'UTF-8');
    ?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $title ?> | <?= $nom ?></title>
    <link rel="stylesheet" href="<?= htmlspecialchars($href) ?>css/registro.css?v=<?= (int) $vReg ?>">
    <?php include dirname(__DIR__, 2) . '/layout/theme_vars.php'; ?>
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
    $href = registroAssetHref();
    $vClock = @filemtime(dirname(__DIR__, 3) . '/js/registro-session-clock.js') ?: time();
    ?>
    <script src="<?= htmlspecialchars($href) ?>js/registro-theme-toggle.js"></script>
    <script src="<?= htmlspecialchars($href) ?>js/registro-session-clock.js?v=<?= (int) $vClock ?>"></script>
    <?php
}
