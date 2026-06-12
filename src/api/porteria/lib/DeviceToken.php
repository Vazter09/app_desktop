<?php
declare(strict_types=1);

/**
 * Token corto de dispositivo portería (6 caracteres alfanuméricos, mayúsculas).
 * Se almacena en BD como hash bcrypt; el valor en claro solo se muestra al generarlo.
 */
class DeviceToken
{
    public const LENGTH = 6;

    /** A-Z y 0-9 (sin I/O/0/1 para lectura en tablet) */
    private const CHARSET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    public static function normalize(string $token): string
    {
        return strtoupper(trim($token));
    }

    public static function isValidFormat(string $token): bool
    {
        $normalized = self::normalize($token);

        return strlen($normalized) === self::LENGTH
            && (bool) preg_match('/^[A-Z0-9]{' . self::LENGTH . '}$/', $normalized);
    }

    /** Formato legado: {id_dispositivo}.{secreto_largo} */
    public static function isLegacyFormat(string $token): bool
    {
        $parts = explode('.', trim($token), 2);

        return count($parts) === 2 && ctype_digit($parts[0]) && $parts[0] !== '';
    }

    public static function hash(string $token): string
    {
        if (self::isLegacyFormat($token)) {
            return password_hash(trim($token), PASSWORD_BCRYPT);
        }

        return password_hash(self::normalize($token), PASSWORD_BCRYPT);
    }

    public static function generateUnique(PDO $pdo, int $maxAttempts = 100): string
    {
        $stmt = $pdo->query(
            'SELECT token_hash FROM tab_dispositivos_porteria WHERE ind_activo = TRUE'
        );
        $existingHashes = $stmt ? $stmt->fetchAll(PDO::FETCH_COLUMN) : [];
        $charsetLen = strlen(self::CHARSET);

        for ($attempt = 0; $attempt < $maxAttempts; $attempt++) {
            $token = '';
            for ($i = 0; $i < self::LENGTH; $i++) {
                $token .= self::CHARSET[random_int(0, $charsetLen - 1)];
            }

            $hash = self::hash($token);
            $collision = false;
            foreach ($existingHashes as $existingHash) {
                if (password_verify($token, (string) $existingHash)) {
                    $collision = true;
                    break;
                }
            }
            if (!$collision) {
                return $token;
            }
        }

        throw new RuntimeException('No se pudo generar un token único. Intente de nuevo.');
    }

    /**
     * @return array<string, mixed>|null
     */
    public static function findDeviceByToken(PDO $pdo, string $token): ?array
    {
        $token = trim($token);
        if ($token === '') {
            return null;
        }

        if (self::isLegacyFormat($token)) {
            return self::findLegacyDevice($pdo, $token);
        }

        if (!self::isValidFormat($token)) {
            return null;
        }

        $normalized = self::normalize($token);
        $stmt = $pdo->query(
            'SELECT id_dispositivo, nom_dispositivo, token_hash, id_usuario_audit,
                    id_entrada_default, ind_activo
               FROM tab_dispositivos_porteria
              WHERE ind_activo = TRUE'
        );
        if (!$stmt) {
            return null;
        }

        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            if (password_verify($normalized, (string) $row['token_hash'])) {
                return $row;
            }
        }

        return null;
    }

    /**
     * @return array<string, mixed>|null
     */
    private static function findLegacyDevice(PDO $pdo, string $token): ?array
    {
        $parts = explode('.', $token, 2);
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
            return null;
        }
        if (!password_verify($token, (string) $row['token_hash'])) {
            return null;
        }

        return $row;
    }
}
