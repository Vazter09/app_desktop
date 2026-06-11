<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::fail('Método no permitido.', 405);
}

porteriaApiRequireDevice();

try {
    ApiResponse::ok(porteriaApiCatalogos());
} catch (Throwable $e) {
    ApiResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
