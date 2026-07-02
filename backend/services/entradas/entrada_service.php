<?php
declare(strict_types=1);

/**
 * Servicio de entradas al centro.
 */

/**
 * @return array{0: int, 1: int}
 */
function entradasParseSedeSeleccionada(string $raw): array
{
    $raw = trim($raw);
    if (!preg_match('/^(\d+):(\d+)$/', $raw, $m)) {
        throw new Exception('Seleccione la sede donde queda la entrada.');
    }

    return [(int) $m[1], (int) $m[2]];
}

function entradasResolveIdEntradaPost(?string $raw): ?int
{
    $raw = trim((string) $raw);
    if ($raw === '') {
        return null;
    }

    $id = (int) $raw;
    if ($id < 1 || $id > 9) {
        throw new Exception('El código de entrada no es válido.');
    }

    return $id;
}

function entradasGuardar(PDOStatement $stmtUpsert, ?int $id, string $nombre, int $centro, int $sede): string
{
    $stmtUpsert->bindValue(1, $id, $id === null ? PDO::PARAM_NULL : PDO::PARAM_INT);
    $stmtUpsert->bindValue(2, $nombre);
    $stmtUpsert->bindValue(3, $centro, PDO::PARAM_INT);
    $stmtUpsert->bindValue(4, $sede, PDO::PARAM_INT);
    $stmtUpsert->execute();

    return (string) ($stmtUpsert->fetchColumn() ?: '');
}

function entradasEliminar(PDOStatement $stmtDelete, int $id): void
{
    $stmtDelete->execute([$id]);
    $stmtDelete->fetchColumn();
}
