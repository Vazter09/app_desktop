<?php
declare(strict_types=1);

/**
 * Sesiones: PHP orquesta funciones PL/pgSQL (retorno TEXT).
 * Listados admin usan SELECT en prepare.php, igual que portería.
 */

const ACCESO_SESION_CIERRE_LOGOUT      = 'LOGOUT';
const ACCESO_SESION_CIERRE_ADMIN       = 'ADMIN';
const ACCESO_SESION_CIERRE_TIMEOUT     = 'TIMEOUT';
const ACCESO_SESION_CIERRE_IP_MISMATCH = 'IP_MISMATCH';

const ACCESO_PRESENCIA_ACTIVO       = 'ACTIVO';
const ACCESO_PRESENCIA_AUSENTE      = 'AUSENTE';
const ACCESO_PRESENCIA_DESCONECTADO = 'DESCONECTADO';

/** Minutos sin actividad tras los cuales la sesión abierta se muestra como Ausente. */
function accesoMinutosPresenciaActivo(): int
{
    return defined('SESION_PRESENCIA_ACTIVO_MIN')
        ? max(1, (int) SESION_PRESENCIA_ACTIVO_MIN)
        : 5;
}

/**
 * Estado de presencia a partir de sesión BD y ult_actividad.
 * Sesión cerrada (fec_fin) → DESCONECTADO; abierta sin touch reciente → AUSENTE.
 */
function accesoEstadoPresencia(bool $sesionActiva, ?string $ultActividadDb): string
{
    if (!$sesionActiva) {
        return ACCESO_PRESENCIA_DESCONECTADO;
    }

    $ultActividadDb = $ultActividadDb !== null ? trim($ultActividadDb) : '';
    if ($ultActividadDb === '') {
        return ACCESO_PRESENCIA_AUSENTE;
    }

    if (!function_exists('smartcsetDbTimestampEpoch')) {
        require_once dirname(__DIR__) . '/helpers.php';
    }

    $epoch = smartcsetDbTimestampEpoch($ultActividadDb);
    if ($epoch === null) {
        return ACCESO_PRESENCIA_AUSENTE;
    }

    $umbralSeg = accesoMinutosPresenciaActivo() * 60;

    return (time() - $epoch) <= $umbralSeg
        ? ACCESO_PRESENCIA_ACTIVO
        : ACCESO_PRESENCIA_AUSENTE;
}

function accesoPresenciaEtiqueta(string $estado): string
{
    return match (strtoupper($estado)) {
        ACCESO_PRESENCIA_ACTIVO       => 'Activo',
        ACCESO_PRESENCIA_AUSENTE      => 'Ausente',
        ACCESO_PRESENCIA_DESCONECTADO => 'Desconectado',
        default                       => 'Desconocido',
    };
}

function accesoPresenciaClaseCss(string $estado): string
{
    return match (strtoupper($estado)) {
        ACCESO_PRESENCIA_ACTIVO       => 'presencia-activo',
        ACCESO_PRESENCIA_AUSENTE      => 'presencia-ausente',
        ACCESO_PRESENCIA_DESCONECTADO => 'presencia-desconectado',
        default                       => 'presencia-desconocido',
    };
}

/**
 * Login → fun_ingreso_sesion (retorna id_sesion como TEXT).
 *
 * @throws PDOException
 */
function accesoIngresoSesion(
    PDOStatement $stmtFunIngreso,
    string $idUsuario,
    ?string $ipCliente = null
): int {
    $idUsuario = trim($idUsuario);
    if ($idUsuario === '') {
        throw new InvalidArgumentException('El usuario de sesión es obligatorio.');
    }

    $ip = $ipCliente !== null ? substr(trim($ipCliente), 0, 45) : null;

    $stmtFunIngreso->execute([$idUsuario, $ip]);
    $idSesion = (int) $stmtFunIngreso->fetchColumn();

    if ($idSesion < 1) {
        throw new RuntimeException('No se recibió un identificador de sesión válido.');
    }

    return $idSesion;
}

/**
 * Cierre → fun_salida_sesion (retorna TEXT 'OK').
 *
 * @throws PDOException
 */
function accesoSalidaSesion(
    PDOStatement $stmtFunSalida,
    int $idSesion,
    string $codCierre,
    ?string $usrCierre = null
): void {
    if ($idSesion < 1) {
        return;
    }

    $stmtFunSalida->execute([$idSesion, $codCierre, $usrCierre ?? '']);
    $stmtFunSalida->fetchColumn();
}

/**
 * Touch → fun_actualizar_sesion_actividad (retorna TEXT 'OK').
 *
 * @throws PDOException
 */
function accesoTouchSesion(
    PDOStatement $stmtFunTouch,
    int $idSesion,
    ?string $ultRuta = null,
    ?string $ultMenuId = null
): void {
    if ($idSesion < 1) {
        return;
    }

    $stmtFunTouch->execute([$idSesion, $ultRuta ?? '', $ultMenuId ?? '']);
    $stmtFunTouch->fetchColumn();
}

/**
 * Valida sesión activa del usuario → fun_validar_sesion_activa.
 * Retorna ult_actividad (TEXT) o null si no hay sesión activa.
 *
 * @throws PDOException
 */
function accesoValidarSesionActiva(
    PDOStatement $stmtFunValidar,
    int $idSesion,
    string $idUsuario
): ?string {
    if ($idSesion < 1 || trim($idUsuario) === '') {
        return null;
    }

    $stmtFunValidar->execute([$idSesion, $idUsuario]);
    $ultActividad = $stmtFunValidar->fetchColumn();

    if ($ultActividad === false || $ultActividad === null || $ultActividad === '') {
        return null;
    }

    return (string) $ultActividad;
}

/**
 * IP registrada al abrir la sesión (ip_cliente), o null si no hay fila activa.
 *
 * @throws PDOException
 */
function accesoObtenerIpSesionActiva(
    PDOStatement $stmtIpSesion,
    int $idSesion,
    string $idUsuario
): ?string {
    if ($idSesion < 1 || trim($idUsuario) === '') {
        return null;
    }

    $stmtIpSesion->execute([$idSesion, $idUsuario]);
    $ip = $stmtIpSesion->fetchColumn();

    if ($ip === false || $ip === null) {
        return null;
    }

    $ip = trim((string) $ip);

    return $ip === '' ? null : $ip;
}
