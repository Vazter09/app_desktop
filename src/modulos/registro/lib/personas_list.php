<?php
declare(strict_types=1);

/**
 * Listado de personas registradas (tab_personas + ubicación).
 *
 * @return list<array<string, mixed>>
 */
function registroFetchPersonasPorTipo(PDO $pdo, int $tipo): array
{
    if ($tipo < 1 || $tipo > 4) {
        return [];
    }

    $sql = "
        SELECT
            p.id_persona,
            p.id_tipo_persona,
            COALESCE(tp.nom_tipo_persona, '') AS nom_tipo_persona,
            p.nom_persona,
            p.ape_persona,
            p.mail_persona,
            p.fec_nacimiento,
            p.ind_estado,
            COALESCE(d.nom_dpto, '') AS nom_dpto,
            COALESCE(c.nom_ciudad, '') AS nom_ciudad,
            p.dir_ciudad_reside
        FROM tab_personas p
        LEFT JOIN tab_tipos_persona tp ON tp.id_tipo_persona = p.id_tipo_persona
        LEFT JOIN tab_dptos d ON d.id_dpto = p.id_dpto_reside
        LEFT JOIN tab_ciudades c ON c.id_ciudad = p.id_ciudad_reside
        WHERE p.id_tipo_persona = :tipo
        ORDER BY p.fec_insert DESC NULLS LAST
        LIMIT 500
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([':tipo' => $tipo]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

    return array_map('registroMapPersonaRow', $rows);
}

/**
 * @param array<string, mixed> $r
 * @return array<string, mixed>
 */
function registroMapPersonaRow(array $r): array
{
    $tipoPersona = trim((string) ($r['nom_tipo_persona'] ?? ''));
    if ($tipoPersona === '') {
        $idTipo = (int) ($r['id_tipo_persona'] ?? 0);
        $tipoPersona = 'Tipo ' . (string) $idTipo;
    }

    $nomDpto = trim((string) ($r['nom_dpto'] ?? ''));
    $nomCiudad = trim((string) ($r['nom_ciudad'] ?? ''));
    $dir = trim((string) ($r['dir_ciudad_reside'] ?? ''));
    $direccion = trim($nomDpto . ($nomCiudad !== '' ? ' / ' . $nomCiudad : ''));
    if ($dir !== '') {
        $direccion = $direccion !== '' ? ($direccion . ' — ' . $dir) : $dir;
    }

    return [
        'tipo' => $tipoPersona,
        'id_persona' => (string) ($r['id_persona'] ?? ''),
        'nombres' => trim((string) ($r['nom_persona'] ?? '') . ' ' . (string) ($r['ape_persona'] ?? '')),
        'correo' => (string) ($r['mail_persona'] ?? ''),
        'direccion' => $direccion,
        'fec_nacimiento' => (string) ($r['fec_nacimiento'] ?? ''),
        'estado' => !empty($r['ind_estado']) ? 'Activo' : 'Inactivo',
        'activo' => !empty($r['ind_estado']),
    ];
}
