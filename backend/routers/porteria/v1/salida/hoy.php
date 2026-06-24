<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/prepare.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session_or_device.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

porteriaRequireSessionOrDevice();

try {
    RouterResponse::ok(['items' => porteriaApiListSalidasHoy()]);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
