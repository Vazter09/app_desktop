<?php
/**
 * Router de desarrollo (php -S): /routers/* → backend/routers/*
 */
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/backend/core/config.php';
require_once dirname(__DIR__, 3) . '/backend/core/helpers.php';

$uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';

$base = smartcsetBasePath();
if ($base !== '' && str_starts_with($uri, $base)) {
    $uri = substr($uri, strlen($base)) ?: '/';
}

if (str_starts_with($uri, '/routers/')) {
    $relative = substr($uri, strlen('/routers/'));
    $relative = str_replace(['..', "\0"], '', $relative);
    $backendRoot = dirname(__DIR__, 3) . '/backend/routers/';
    $file = $backendRoot . $relative;

    if (is_file($file) && str_starts_with(realpath($file) ?: '', realpath($backendRoot))) {
        require $file;
        return true;
    }

    http_response_code(404);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['ok' => false, 'error' => 'Router no encontrado.'], JSON_UNESCAPED_UNICODE);
    return true;
}

return false;
