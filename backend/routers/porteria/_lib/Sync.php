<?php
declare(strict_types=1);

class PorteriaRouterSync
{
    /**
     * @return array{id_ingreso: int, tipo_operacion: string}|null
     */
    public static function findByClientId(PDO $pdo, string $clientId): ?array
    {
        if ($clientId === '') {
            return null;
        }
        $stmt = $pdo->prepare(
            'SELECT client_id, id_ingreso, tipo_operacion
               FROM tab_porteria_sync_client
              WHERE client_id = ?::UUID'
        );
        $stmt->execute([$clientId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row ?: null;
    }

    public static function registerClientId(
        PDO $pdo,
        string $clientId,
        int $idDispositivo,
        string $tipoOperacion,
        int $idIngreso
    ): void {
        if ($clientId === '') {
            return;
        }
        $stmt = $pdo->prepare(
            'INSERT INTO tab_porteria_sync_client (client_id, id_dispositivo, tipo_operacion, id_ingreso)
             VALUES (?::UUID, ?::INTEGER, ?::VARCHAR, ?::NUMERIC)
             ON CONFLICT (client_id) DO NOTHING'
        );
        $stmt->execute([$clientId, $idDispositivo, $tipoOperacion, $idIngreso]);
    }

    public static function isValidUuid(string $clientId): bool
    {
        return (bool) preg_match(
            '/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i',
            $clientId
        );
    }
}
