<?php
declare(strict_types=1);

/**
 * Conexión PDO y utilidades de acceso a BD compartidas por prepare.php y prepare_login.php.
 */
final class Db
{
    /** Intervalo mínimo entre UPDATE de ult_actividad (segundos). */
    private const SESION_TOUCH_MIN_INTERVAL = 60;

    public static function connect(): PDO
    {
        $dsn = 'pgsql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME;

        return new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            // Preparaciones nativas en PostgreSQL (menos overhead, mejor plan cache por conexión).
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
    }

    /**
     * Actualiza ult_actividad como máximo una vez por intervalo (evita un round-trip por cada request).
     */
    public static function touchSesionSiCorresponde(PDOStatement $stmt, string $idUsuario): void
    {
        if ($idUsuario === '') {
            return;
        }

        $intervalo = max(
            self::SESION_TOUCH_MIN_INTERVAL,
            (int) (defined('SESSION_TIMEOUT') ? SESSION_TIMEOUT / 6 : 300)
        );
        $ahora = time();
        $ultimo = (int) ($_SESSION['_sesion_touch_at'] ?? 0);

        if ($ahora - $ultimo < $intervalo) {
            return;
        }

        try {
            $stmt->execute([$idUsuario]);
            $_SESSION['_sesion_touch_at'] = $ahora;
        } catch (Throwable $e) {
            error_log('touch sesion: ' . $e->getMessage());
        }
    }
}
