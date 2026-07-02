<?php
declare(strict_types=1);

require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 4) . '/middleware/require_registro_session.php';
require_once dirname(__DIR__, 4) . '/services/registro/guardar_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$tipo = trim((string) ($_POST['tipo'] ?? $_POST['registro_tipo'] ?? ''));
if ($tipo === '') {
    RouterResponse::fail('Debe indicar el tipo de formulario.');
}

try {
    $result = registroGuardarFormulario($pdo, $tipo, $_POST);
    RouterResponse::ok($result);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
