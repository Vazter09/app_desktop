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

    /**
     * Cierra la fila en tab_sesiones (fec_fin) si aún está abierta. Idempotente.
     */
    private static function cerrarSesionEnBd(
        PDOStatement $stmtSalidaSesion,
        int $idSesion,
        string $idUsuario,
        string $codCierre
    ): void {
        if ($idSesion < 1) {
            return;
        }

        try {
            require_once __DIR__ . '/lib/acceso_sesion.php';

            accesoSalidaSesion($stmtSalidaSesion, $idSesion, $codCierre, $idUsuario);
        } catch (Throwable $e) {
            error_log('cerrar sesion bd: ' . $e->getMessage());
        }
    }

    /**
     * Solo administradores (ind_usuario) reciben cierre automático en BD por timeout.
     * Usuarios normales mantienen fec_fin NULL hasta cierre manual del admin o logout.
     */
    private static function cerrarSesionEnBdSiAdministrador(
        PDOStatement $stmtSalidaSesion,
        int $idSesion,
        string $idUsuario,
        string $codCierre
    ): void {
        if (!self::sesionUsuarioEsAdministrador()) {
            return;
        }

        self::cerrarSesionEnBd($stmtSalidaSesion, $idSesion, $idUsuario, $codCierre);
    }

    private static function sesionUsuarioEsAdministrador(): bool
    {
        return !empty($_SESSION['ind_usuario']);
    }

    public static function connect(): PDO
    {
        $dsn = 'pgsql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME;

        $sslmode = defined('DB_SSLMODE') ? trim((string) DB_SSLMODE) : '';
        if ($sslmode !== '') {
            $dsn .= ';sslmode=' . $sslmode;
        }

        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);

        $dbTz = defined('DB_TIMEZONE') ? DB_TIMEZONE : 'America/Bogota';
        if (!preg_match('/^[A-Za-z0-9_\/+\-]+$/', $dbTz)) {
            $dbTz = 'America/Bogota';
        }
        // Obliga a CURRENT_TIMESTAMP / now() de la sesión a hora civil Colombia.
        // Las funciones PL/pgSQL de portería además usan smartcset_now_local().
        $pdo->exec("SET TIME ZONE " . $pdo->quote($dbTz));

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
                self::cerrarSesionEnBdSiAdministrador(
                    $stmtSalidaSesion,
                    $idSesion,
                    $idUsuario,
                    ACCESO_SESION_CIERRE_TIMEOUT
                );

                return self::SESION_INVALID;
            }

            if (
                smartcsetSesionValidarIp()
                && $stmtSesionIp !== null
            ) {
                $ipRegistrada = accesoObtenerIpSesionActiva($stmtSesionIp, $idSesion, $idUsuario);
                $ipActual = smartcsetClientIp();
                if (!smartcsetSesionIpCoincide($ipRegistrada, $ipActual)) {
                    self::cerrarSesionEnBdSiAdministrador(
                        $stmtSalidaSesion,
                        $idSesion,
                        $idUsuario,
                        ACCESO_SESION_CIERRE_IP_MISMATCH
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
                    self::cerrarSesionEnBdSiAdministrador(
                        $stmtSalidaSesion,
                        $idSesion,
                        $idUsuario,
                        ACCESO_SESION_CIERRE_TIMEOUT
                    );

                    return self::SESION_INVALID;
                }
            }

            self::touchSesionSiCorresponde($stmtTouchSesion, $idSesion);

            return self::SESION_OK;
        } catch (Throwable $e) {
            error_log('gestionar sesion: ' . $e->getMessage());

            self::cerrarSesionEnBdSiAdministrador(
                $stmtSalidaSesion,
                $idSesion,
                $idUsuario,
                ACCESO_SESION_CIERRE_TIMEOUT
            );

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
