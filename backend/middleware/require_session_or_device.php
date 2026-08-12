<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/core/prepare.php';
require_once dirname(__DIR__) . '/core/RouterResponse.php';
require_once dirname(__DIR__) . '/core/lib/acceso_sesion.php';
require_once dirname(__DIR__) . '/routers/porteria/_lib/Auth.php';

/**
 * Portería: sesión web O token de dispositivo móvil.
 *
 * @return array<string, mixed> contexto auth (device row o usuario web)
 */
function porteriaRequireSessionOrDevice(): array
{
    global $pdo;

    $bearer = PorteriaRouterAuth::extractBearerToken();
    if ($bearer !== null && $bearer !== '') {
        return ['type' => 'device', 'row' => PorteriaRouterAuth::requireDevice($pdo)];
    }

    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    if (empty($_SESSION['id_usuario'])) {
        RouterResponse::unauthorized('Sesión no válida.');
    }

    $idUsuario = (string) $_SESSION['id_usuario'];

    return [
        'type' => 'web',
        'id_usuario' => $idUsuario,
        'usr_audit' => $idUsuario,
        'origen_cliente' => (string) ($_SESSION['origen_cliente'] ?? 'web'),
    ];
}

function porteriaAuthAuditUser(array $auth): string
{
    if (($auth['type'] ?? '') === 'device') {
        return (string) ($auth['row']['id_usuario_audit'] ?? 'device');
    }

    return (string) ($auth['usr_audit'] ?? accesoUsuarioAuditoriaSesion());
}
