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

        $parts = explode('.', $token, 2);
        if (count($parts) !== 2 || !ctype_digit($parts[0])) {
            ApiResponse::unauthorized();
        }

        $idDispositivo = (int) $parts[0];
        $stmt = $pdo->prepare(
            'SELECT id_dispositivo, nom_dispositivo, token_hash, id_usuario_audit,
                    id_entrada_default, ind_activo
               FROM tab_dispositivos_porteria
              WHERE id_dispositivo = ?::INTEGER'
        );
        $stmt->execute([$idDispositivo]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row || !(bool) $row['ind_activo']) {
            ApiResponse::unauthorized();
        }
        if (!password_verify($token, (string) $row['token_hash'])) {
            ApiResponse::unauthorized();
        }

        $upd = $pdo->prepare(
            'UPDATE tab_dispositivos_porteria
                SET fec_ultimo_uso = CURRENT_TIMESTAMP
              WHERE id_dispositivo = ?::INTEGER'
        );
        $upd->execute([$idDispositivo]);

        return $row;
    }
}
