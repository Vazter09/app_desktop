<?php
declare(strict_types=1);

/**
 * Legacy shim — redirige al router JSON.
 */
require_once dirname(__DIR__, 4) . '/init.php';

$query = $_SERVER['QUERY_STRING'] ?? '';
$path = '/routers/registro/v1/ciudades.php' . ($query !== '' ? '?' . $query : '');
$target = smartcsetUrl($path);
header('Location: ' . $target, true, 307);
exit;
