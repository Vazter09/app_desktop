<?php
declare(strict_types=1);

/**
 * Conexión PDO y utilidades de acceso a BD compartidas por prepare.php y prepare_login.php.
 */
final class Db
{
    public const SESION_OK = 0;
    public const SESION_INVALID = 1;
    public const SESION_IP_MISMATCH = 2;

    /**
     * Intervalo mínimo entre UPDATE de ult_actividad en navegación (segundos).
     * El heartbeat (`smartcset-presencia.js`) actualiza con la misma cadencia vía AJAX.
     */
    private static function sesionTouchMinInterval(): int
    {
        $heartbeat = defined('SESION_HEARTBEAT_SEG') ? (int) SESION_HEARTBEAT_SEG : 60;

        return max(15, min($heartbeat, 300));
    }

    public static function connect(): PDO
    {
        $dsn = 'pgsql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME;

        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);

        $dbTz = defined('DB_TIMEZONE') ? DB_TIMEZONE : 'UTC';
        if (preg_match('/^[A-Za-z0-9_\/+\-]+$/', $dbTz)) {
            $pdo->exec("SET TIME ZONE '" . str_replace("'", "''", $dbTz) . "'");
        }

        return $pdo;
    }

    /**
     * Valida sesión activa en BD, timeout, IP (opcional) y actualiza ult_actividad/ruta.
     *
     * @return self::SESION_OK|self::SESION_INVALID|self::SESION_IP_MISMATCH
     */
    public static function gestionarSesionEnRequest(
        PDOStatement $stmtConsultarSesion,
        PDOStatement $stmtSalidaSesion,
        PDOStatement $stmtTouchSesion,
        int $sessionTimeoutSeg,
        ?PDOStatement $stmtSesionIp = null
    ): int {
        if (empty($_SESSION['id_sesion']) || empty($_SESSION['id_usuario'])) {
            return self::SESION_INVALID;
        }

        $idSesion = (int) $_SESSION['id_sesion'];
        $idUsuario = (string) $_SESSION['id_usuario'];
        if ($idSesion < 1 || $idUsuario === '') {
            return self::SESION_INVALID;
        }

        try {
            require_once __DIR__ . '/lib/acceso_sesion.php';
            require_once __DIR__ . '/helpers.php';

            $ultActividadStr = accesoValidarSesionActiva($stmtConsultarSesion, $idSesion, $idUsuario);
            if ($ultActividadStr === null) {
                return self::SESION_INVALID;
            }

            if (
                smartcsetSesionValidarIp()
                && $stmtSesionIp !== null
            ) {
                $ipRegistrada = accesoObtenerIpSesionActiva($stmtSesionIp, $idSesion, $idUsuario);
                $ipActual = smartcsetClientIp();
                if (!smartcsetSesionIpCoincide($ipRegistrada, $ipActual)) {
                    accesoSalidaSesion(
                        $stmtSalidaSesion,
                        $idSesion,
                        ACCESO_SESION_CIERRE_IP_MISMATCH,
                        $idUsuario
                    );
                    error_log(
                        'sesion IP_MISMATCH: sesion=' . $idSesion
                        . ' usuario=' . $idUsuario
                        . ' registrada=' . ($ipRegistrada ?? '')
                        . ' actual=' . $ipActual
                    );

                    return self::SESION_IP_MISMATCH;
                }
            }

            $ultActividad = smartcsetDbTimestampEpoch($ultActividadStr);
            if ($ultActividad !== null && $sessionTimeoutSeg > 0) {
                if (time() - $ultActividad > $sessionTimeoutSeg) {
                    accesoSalidaSesion(
                        $stmtSalidaSesion,
                        $idSesion,
                        ACCESO_SESION_CIERRE_TIMEOUT,
                        $idUsuario
                    );

                    return self::SESION_INVALID;
                }
            }

            self::touchSesionSiCorresponde($stmtTouchSesion, $idSesion);

            return self::SESION_OK;
        } catch (Throwable $e) {
            error_log('gestionar sesion: ' . $e->getMessage());

            return self::SESION_INVALID;
        }
    }

    public static function resolverUltRuta(): string
    {
        $script = (string) ($_SERVER['SCRIPT_NAME'] ?? '');
        if ($script === '') {
            return '';
        }

        return substr($script, 0, 255);
    }

    public static function resolverUltMenuId(): ?string
    {
        if (isset($GLOBALS['active_menu_id']) && $GLOBALS['active_menu_id'] !== '') {
            return substr((string) $GLOBALS['active_menu_id'], 0, 20);
        }

        return null;
    }

    /**
     * Actualiza ult_actividad como máximo una vez por intervalo (fun_actualizar_sesion_actividad).
     */
    public static function touchSesionSiCorresponde(PDOStatement $stmt, int $idSesion): void
    {
        if ($idSesion < 1) {
            return;
        }

        $intervalo = max(
            self::sesionTouchMinInterval(),
            (int) (defined('SESSION_TIMEOUT') ? SESSION_TIMEOUT / 6 : 300)
        );
        $ahora = time();
        $ultimo = (int) ($_SESSION['_sesion_touch_at'] ?? 0);

        if ($ahora - $ultimo < $intervalo) {
            return;
        }

        try {
            require_once __DIR__ . '/lib/acceso_sesion.php';

            accesoTouchSesion(
                $stmt,
                $idSesion,
                self::resolverUltRuta(),
                self::resolverUltMenuId()
            );
            $_SESSION['_sesion_touch_at'] = $ahora;
        } catch (Throwable $e) {
            error_log('touch sesion: ' . $e->getMessage());
        }
    }
}
