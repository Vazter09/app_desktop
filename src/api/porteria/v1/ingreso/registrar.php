<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::fail('Método no permitido.', 405);
}

$device = porteriaApiRequireDevice();
$json = ApiPayload::readJsonBody();

try {
    $result = porteriaApiRegistrarIngreso($device, $json);
    ApiResponse::ok($result);
} catch (PDOException $e) {
    ApiResponse::fail(ErrorHandler::userMessageFromException($e));
} catch (Throwable $e) {
    ApiResponse::fail(ErrorHandler::userMessageFromException($e));
}
