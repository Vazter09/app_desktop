<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

ApiResponse::ok([
    'service' => 'smartcset-porteria-api',
    'version' => 'v1',
    'time' => date('c'),
    'api_enabled' => ApiAuth::isEnabled(),
]);
