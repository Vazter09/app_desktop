<?php
declare(strict_types=1);

/**
 * Init de vistas web — carga prepare y variables de presentación.
 */
require_once dirname(__DIR__, 2) . '/backend/core/prepare.php';
require_once dirname(__DIR__, 2) . '/backend/core/ErrorHandler.php';
require_once dirname(__DIR__, 2) . '/backend/core/helpers.php';

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$smartcset_asset_href = smartcsetProjectAssetHref();

function smartcsetLayoutPath(string $relativeFromLayout = ''): string
{
    return __DIR__ . '/layout/' . ltrim($relativeFromLayout, '/');
}

function smartcsetProjectRoot(): string
{
    return dirname(__DIR__, 2);
}
