<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/core/prepare.php';
require_once dirname(__DIR__) . '/core/RouterResponse.php';
require_once dirname(__DIR__) . '/core/helpers.php';
require_once __DIR__ . '/require_session.php';
require_once dirname(__DIR__) . '/services/instructor/asistencia_service.php';

/**
 * Contexto de acceso al módulo instructor (instructor o admin solo lectura).
 *
 * @return array{
 *   id_instructor: int|null,
 *   es_admin: bool,
 *   modo: 'instructor'|'admin_lectura',
 *   id_usuario: string
 * }
 */
function instructorRequireContext(): array
{
    global $pdo;

    $idUsuario = (string) $_SESSION['id_usuario'];
    $esAdmin = usuarioEsAdministrador($pdo, $idUsuario);
    $idInstructor = instructorResolverIdDesdeSesion($pdo, $idUsuario);

    if ($idInstructor === null && !$esAdmin) {
        RouterResponse::fail('Acceso restringido a instructores registrados o administradores.', 403);
    }

    return [
        'id_instructor' => $idInstructor,
        'es_admin' => $esAdmin,
        'modo' => $idInstructor !== null ? 'instructor' : 'admin_lectura',
        'id_usuario' => $idUsuario,
    ];
}
