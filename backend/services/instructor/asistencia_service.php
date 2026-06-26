<?php
declare(strict_types=1);

/**
 * Servicio de asistencia para el módulo instructor (Mis fichas).
 */

/** @return positive-int|null */
function instructorResolverIdDesdeSesion(PDO $pdo, string $idUsuario): ?int
{
    $idUsuario = trim($idUsuario);
    if ($idUsuario === '' || !ctype_digit($idUsuario)) {
        return null;
    }

    $idInstructor = (int) $idUsuario;
    if ($idInstructor < 1) {
        return null;
    }

    $stmt = $pdo->prepare(
        'SELECT 1 FROM tab_instructores WHERE id_instructor = ?::NUMERIC LIMIT 1'
    );
    $stmt->execute([$idInstructor]);

    return $stmt->fetchColumn() !== false ? $idInstructor : null;
}

/**
 * @return array{desde: string, hasta: string}
 */
function instructorNormalizarRangoFechas(array $input): array
{
    $hoy = date('Y-m-d');
    $fecha = trim((string) ($input['fecha'] ?? ''));
    $desde = trim((string) ($input['desde'] ?? ''));
    $hasta = trim((string) ($input['hasta'] ?? ''));

    if ($fecha !== '' && preg_match('/^\d{4}-\d{2}-\d{2}$/', $fecha) === 1) {
        return ['desde' => $fecha, 'hasta' => $fecha];
    }

    if ($desde === '' && $hasta === '') {
        return ['desde' => $hoy, 'hasta' => $hoy];
    }

    if ($desde === '') {
        $desde = $hasta;
    }
    if ($hasta === '') {
        $hasta = $desde;
    }

    if (
        preg_match('/^\d{4}-\d{2}-\d{2}$/', $desde) !== 1
        || preg_match('/^\d{4}-\d{2}-\d{2}$/', $hasta) !== 1
    ) {
        throw new InvalidArgumentException('Formato de fecha inválido. Use AAAA-MM-DD.');
    }

    if ($desde > $hasta) {
        throw new InvalidArgumentException('La fecha inicial no puede ser posterior a la final.');
    }

    $dias = (int) ((strtotime($hasta) - strtotime($desde)) / 86400) + 1;
    if ($dias > 31) {
        throw new InvalidArgumentException('El rango máximo permitido es de 31 días.');
    }

    return ['desde' => $desde, 'hasta' => $hasta];
}

/**
 * @return list<array<string, mixed>>
 */
function instructorListarFichas(PDOStatement $stmt, int $idInstructor): array
{
    $stmt->execute([$idInstructor]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    return is_array($rows) ? $rows : [];
}

/**
 * @return array{
 *   desde: string,
 *   hasta: string,
 *   rows: list<array<string, mixed>>,
 *   por_fecha: array<string, array{Presente: int, Tarde: int, Ausente: int, Pendiente: int, Desconocido: int, total: int}>
 * }
 */
function instructorListarAsistenciaFicha(
    PDOStatement $stmt,
    int $idInstructor,
    int $idFicha,
    string $desde,
    string $hasta
): array {
    $stmt->execute([$idInstructor, $idFicha, $desde, $hasta]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (!is_array($rows)) {
        $rows = [];
    }

    $porFecha = [];
    foreach ($rows as $row) {
        $fec = (string) ($row['fec_asistencia'] ?? '');
        if ($fec === '') {
            continue;
        }
        if (!isset($porFecha[$fec])) {
            $porFecha[$fec] = [
                'Presente' => 0,
                'Tarde' => 0,
                'Ausente' => 0,
                'Pendiente' => 0,
                'Desconocido' => 0,
                'total' => 0,
            ];
        }
        $estado = (string) ($row['ind_estado'] ?? 'Desconocido');
        if (!isset($porFecha[$fec][$estado])) {
            $estado = 'Desconocido';
        }
        $porFecha[$fec][$estado]++;
        $porFecha[$fec]['total']++;
    }

    krsort($porFecha);

    return [
        'desde' => $desde,
        'hasta' => $hasta,
        'rows' => $rows,
        'por_fecha' => $porFecha,
    ];
}

/**
 * @param list<array<string, mixed>> $fichas
 */
function instructorResolverFichaSeleccionada(array $fichas, array $input): ?int
{
    $idFicha = (int) ($input['id_ficha'] ?? 0);
    if ($idFicha > 0) {
        foreach ($fichas as $ficha) {
            if ((int) ($ficha['id_ficha'] ?? 0) === $idFicha) {
                return $idFicha;
            }
        }
        return null;
    }

    if (count($fichas) === 1) {
        return (int) ($fichas[0]['id_ficha'] ?? 0) ?: null;
    }

    return null;
}

function instructorEtiquetaOrigen(string $origen): string
{
    return match ($origen) {
        'lider' => 'Líder',
        'programacion' => 'Transversal',
        default => $origen,
    };
}

function instructorBadgeEstado(string $estado): string
{
    return match ($estado) {
        'Presente' => 'success',
        'Tarde' => 'warning',
        'Ausente' => 'danger',
        'Pendiente' => 'secondary',
        default => 'light text-dark',
    };
}

/**
 * Resumen del día para el panel de inicio del instructor.
 *
 * @param list<array<string, mixed>> $fichas
 * @return array{
 *   fecha: string,
 *   total_fichas: int,
 *   total_aprendices: int,
 *   hoy: array{Presente: int, Tarde: int, Ausente: int, Pendiente: int, Desconocido: int, total: int},
 *   por_ficha: list<array{ficha: array<string, mixed>, resumen: array{Presente: int, Tarde: int, Ausente: int, Pendiente: int, Desconocido: int, total: int}}>
 * }
 */
function instructorDashboardResumen(
    PDOStatement $stmtAsistencia,
    int $idInstructor,
    array $fichas,
    string $fechaHoy = ''
): array {
    $fechaHoy = $fechaHoy !== '' ? $fechaHoy : date('Y-m-d');

    $hoy = [
        'Presente' => 0,
        'Tarde' => 0,
        'Ausente' => 0,
        'Pendiente' => 0,
        'Desconocido' => 0,
        'total' => 0,
    ];

    $porFicha = [];
    $totalAprendices = 0;

    foreach ($fichas as $ficha) {
        $idFicha = (int) ($ficha['id_ficha'] ?? 0);
        if ($idFicha < 1) {
            continue;
        }

        $totalAprendices += (int) ($ficha['num_aprendices'] ?? 0);

        $resumenFicha = [
            'Presente' => 0,
            'Tarde' => 0,
            'Ausente' => 0,
            'Pendiente' => 0,
            'Desconocido' => 0,
            'total' => 0,
        ];

        $data = instructorListarAsistenciaFicha(
            $stmtAsistencia,
            $idInstructor,
            $idFicha,
            $fechaHoy,
            $fechaHoy
        );
        $resumenDia = $data['por_fecha'][$fechaHoy] ?? null;
        if (is_array($resumenDia)) {
            foreach (['Presente', 'Tarde', 'Ausente', 'Pendiente', 'Desconocido'] as $estado) {
                $cant = (int) ($resumenDia[$estado] ?? 0);
                $resumenFicha[$estado] = $cant;
                $hoy[$estado] += $cant;
            }
            $resumenFicha['total'] = (int) ($resumenDia['total'] ?? 0);
            $hoy['total'] += (int) ($resumenDia['total'] ?? 0);
        }

        $porFicha[] = [
            'ficha' => $ficha,
            'resumen' => $resumenFicha,
        ];
    }

    return [
        'fecha' => $fechaHoy,
        'total_fichas' => count($fichas),
        'total_aprendices' => $totalAprendices,
        'hoy' => $hoy,
        'por_ficha' => $porFicha,
    ];
}
