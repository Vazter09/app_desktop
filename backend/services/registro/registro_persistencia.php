<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/core/ErrorHandler.php';

/**
 * Traduce excepciones de guardado en formularios de registro a mensaje de usuario.
 *
 * @return array{msg: string, tipo: string}
 */
function registroHandlePostException(Throwable $e): array
{
    return [
        'msg'  => ErrorHandler::userMessageFromException($e),
        'tipo' => 'danger',
    ];
}
