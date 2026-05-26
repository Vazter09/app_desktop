<?php
/**
 * Arranque común de páginas bajo src/modulos/porteria/
 */
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 3) . '/core/helpers.php';

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$smartcset_asset_href = smartcsetModulosAssetHref();

function modulosProjectRoot(): string
{
    return dirname(__DIR__, 4);
}

function modulosLayout(string $relativeFromSrc): string
{
    return dirname(__DIR__, 3) . '/' . ltrim($relativeFromSrc, '/');
}
