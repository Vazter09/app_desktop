<?php
declare(strict_types=1);

class ApiAuth
{
    public static function isEnabled(): bool
    {
        $val = $_ENV['PORTERIA_API_ENABLED'] ?? getenv('PORTERIA_API_ENABLED') ?: '1';

        return !in_array(strtolower((string) $val), ['0', 'false', 'no'], true);
    }

    public static function extractBearerToken(): ?string
    {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
        if ($header === '' && function_exists('getallheaders')) {
            foreach (getallheaders() as $name => $value) {
                if (strcasecmp($name, 'Authorization') === 0) {
                    $header = $value;
                    break;
                }
            }
        }
        if (preg_match('/^Bearer\s+(\S+)$/i', trim($header), $m)) {
            return $m[1];
        }

        $alt = trim((string) ($_SERVER['HTTP_X_DEVICE_TOKEN'] ?? ''));
        if ($alt !== '') {
            return $alt;
        }

        return null;
    }

    /**
     * @return array<string, mixed>
     */
    public static function requireDevice(PDO $pdo): array
    {
        if (!self::isEnabled()) {
            ApiResponse::disabled();
        }

        $token = self::extractBearerToken();
        if ($token === null || $token === '') {
            ApiResponse::unauthorized('Falta token de dispositivo.');
        }

        require_once __DIR__ . '/DeviceToken.php';
        $row = DeviceToken::findDeviceByToken($pdo, $token);
        if ($row === null) {
            ApiResponse::unauthorized();
        }

        $upd = $pdo->prepare(
            'UPDATE tab_dispositivos_porteria
                SET fec_ultimo_uso = CURRENT_TIMESTAMP
              WHERE id_dispositivo = ?::INTEGER'
        );
        $upd->execute([(int) $row['id_dispositivo']]);

        return $row;
    }
}
