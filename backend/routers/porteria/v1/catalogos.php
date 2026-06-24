<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/prepare.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

porteriaApiRequireDevice();

try {
    RouterResponse::ok(porteriaApiCatalogos());
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
