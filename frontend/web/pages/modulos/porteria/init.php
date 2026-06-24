<?php
declare(strict_types=1);

/**
 * Arranque de vistas portería bajo pages/modulos/porteria/
 */
require_once dirname(__DIR__, 3) . '/init.php';

function modulosLayout(string $relativeFromLayout): string
{
    $path = ltrim($relativeFromLayout, '/');
    if (str_starts_with($path, 'layout/')) {
        $path = substr($path, strlen('layout/'));
    }

    return smartcsetLayoutPath($path);
}

function modulosProjectRoot(): string
{
    return smartcsetProjectRoot();
}
