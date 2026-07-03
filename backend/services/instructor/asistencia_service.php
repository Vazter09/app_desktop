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

/**
 * @param array{id_instructor: int|null, es_admin: bool, modo: string} $ctx
 */
function instructorPuedeAccederFicha(
    PDO $pdo,
    PDOStatement $stmtFichasInstructor,
    PDOStatement $stmtFichasAdmin,
    array $ctx,
    int $idFicha
): bool {
    if ($idFicha < 1) {
        return false;
    }

    if (($ctx['modo'] ?? '') === 'admin_lectura') {
        $stmt = $pdo->prepare(
            'SELECT 1 FROM tab_fichas WHERE id_ficha = ?::NUMERIC AND ind_estado = 3 LIMIT 1'
        );
        $stmt->execute([$idFicha]);

        return $stmt->fetchColumn() !== false;
    }

    $idInstructor = (int) ($ctx['id_instructor'] ?? 0);
    if ($idInstructor < 1) {
        return false;
    }

    $fichas = instructorListarFichas($stmtFichasInstructor, $idInstructor);
    foreach ($fichas as $ficha) {
        if ((int) ($ficha['id_ficha'] ?? 0) === $idFicha) {
            return true;
        }
    }

    return false;
}

/**
 * @param array{id_instructor: int|null, es_admin: bool, modo: string} $ctx
 * @return list<array<string, mixed>>
 */
function instructorListarFichasPorContexto(
    PDOStatement $stmtInstructor,
    PDOStatement $stmtAdmin,
    array $ctx
): array {
    if (($ctx['modo'] ?? '') === 'admin_lectura') {
        $stmtAdmin->execute();
        $rows = $stmtAdmin->fetchAll(PDO::FETCH_ASSOC);

        return is_array($rows) ? $rows : [];
    }

    $idInstructor = (int) ($ctx['id_instructor'] ?? 0);
    if ($idInstructor < 1) {
        return [];
    }

    return instructorListarFichas($stmtInstructor, $idInstructor);
}

/**
 * @param array{id_instructor: int|null, es_admin: bool, modo: string} $ctx
 * @return array{
 *   id_ficha: int,
 *   desde: string,
 *   hasta: string,
 *   rows: list<array<string, mixed>>,
 *   por_fecha: array<string, array{Presente: int, Tarde: int, Ausente: int, Pendiente: int, Desconocido: int, total: int}>
 * }
 */
function instructorListarAsistenciaPorContexto(
    PDOStatement $stmtInstructor,
    PDOStatement $stmtAdmin,
    array $ctx,
    int $idFicha,
    string $desde,
    string $hasta
): array {
    if (($ctx['modo'] ?? '') === 'admin_lectura') {
        $stmtAdmin->execute([$idFicha, $desde, $hasta]);
        $rows = $stmtAdmin->fetchAll(PDO::FETCH_ASSOC);
        if (!is_array($rows)) {
            $rows = [];
        }

        return instructorAgregarMetadatosAsistencia($idFicha, $desde, $hasta, $rows);
    }

    $idInstructor = (int) ($ctx['id_instructor'] ?? 0);
    $data = instructorListarAsistenciaFicha($stmtInstructor, $idInstructor, $idFicha, $desde, $hasta);

    return array_merge(['id_ficha' => $idFicha], $data);
}

/**
 * @param list<array<string, mixed>> $rows
 * @return array{
 *   id_ficha: int,
 *   desde: string,
 *   hasta: string,
 *   rows: list<array<string, mixed>>,
 *   por_fecha: array<string, array{Presente: int, Tarde: int, Ausente: int, Pendiente: int, Desconocido: int, total: int}>
 * }
 */
function instructorAgregarMetadatosAsistencia(int $idFicha, string $desde, string $hasta, array $rows): array
{
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
        'id_ficha' => $idFicha,
        'desde' => $desde,
        'hasta' => $hasta,
        'rows' => $rows,
        'por_fecha' => $porFecha,
    ];
}

/**
 * @param array{modo: string} $ctx
 */
function instructorRequireWriteAccess(array $ctx): void
{
    if (($ctx['modo'] ?? '') !== 'instructor') {
        throw new RuntimeException('Solo los instructores pueden registrar o modificar asistencia.');
    }
}

function instructorExisteRegistroAsistencia(PDO $pdo, int $idAprendiz, string $fecha): bool
{
    $stmt = $pdo->prepare(
        'SELECT 1 FROM tab_asistencia_aprendiz
          WHERE id_aprendiz = ?::NUMERIC AND fec_asistencia = ?::DATE LIMIT 1'
    );
    $stmt->execute([$idAprendiz, $fecha]);

    return $stmt->fetchColumn() !== false;
}

/**
 * @param array<string, mixed> $payload
 */
function instructorRegistrarAsistenciaManual(
    PDOStatement $stmt,
    int $idInstructor,
    array $payload,
    string $usrAudit
): void {
    instructorEjecutarGuardarAsistencia($stmt, $idInstructor, $payload, $usrAudit, true);
}

/**
 * @param array<string, mixed> $payload
 */
function instructorActualizarAsistenciaManual(
    PDOStatement $stmt,
    int $idInstructor,
    array $payload,
    string $usrAudit
): void {
    instructorEjecutarGuardarAsistencia($stmt, $idInstructor, $payload, $usrAudit, false);
}

/**
 * @param array<string, mixed> $payload
 */
function instructorEjecutarGuardarAsistencia(
    PDOStatement $stmt,
    int $idInstructor,
    array $payload,
    string $usrAudit,
    bool $soloInsert
): void {
    $idFicha = (int) ($payload['id_ficha'] ?? 0);
    $idAprendiz = (int) ($payload['id_aprendiz'] ?? 0);
    $fecha = trim((string) ($payload['fec_asistencia'] ?? ''));
    $estado = trim((string) ($payload['ind_estado'] ?? ''));

    if ($idFicha < 1 || $idAprendiz < 1 || $fecha === '' || $estado === '') {
        throw new InvalidArgumentException('Complete ficha, aprendiz, fecha y estado.');
    }

    $stmt->execute([
        $idInstructor,
        $idFicha,
        $idAprendiz,
        $fecha,
        $estado,
        $usrAudit,
        $soloInsert ? 'true' : 'false',
    ]);
    $res = (string) $stmt->fetchColumn();
    if ($res !== 'OK') {
        throw new RuntimeException('No se pudo guardar la asistencia.');
    }
}

/**
 * Busca metadatos de una ficha dentro de un listado.
 *
 * @param list<array<string, mixed>> $fichas
 * @return array<string, mixed>|null
 */
function instructorBuscarFichaEnListado(array $fichas, int $idFicha): ?array
{
    foreach ($fichas as $ficha) {
        if ((int) ($ficha['id_ficha'] ?? 0) === $idFicha) {
            return $ficha;
        }
    }

    return null;
}

/**
 * Metadatos de ficha para encabezado de exportación Excel.
 *
 * @return array{
 *   id_ficha: int,
 *   nom_ficha: string,
 *   nom_programa: string,
 *   nom_jornada: string,
 *   nom_instructor: string
 * }
 */
function instructorObtenerMetadatosFichaExport(PDO $pdo, int $idFicha): array
{
    if ($idFicha < 1) {
        throw new InvalidArgumentException('Debe indicar la ficha.');
    }

    $stmt = $pdo->prepare(
        'SELECT f.id_ficha,
                pr.nom_programa,
                j.nom_jornada,
                TRIM(p.nom_persona) || \' \' || TRIM(p.ape_persona) AS nom_instructor
           FROM tab_fichas f
           INNER JOIN tab_programas pr ON pr.id_programa = f.id_programa
           INNER JOIN tab_jornadas j ON j.id_jornada = f.id_jornada
           INNER JOIN tab_personas p ON p.id_persona = f.id_instructor_lider
          WHERE f.id_ficha = ?::NUMERIC
          LIMIT 1'
    );
    $stmt->execute([$idFicha]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!is_array($row)) {
        throw new InvalidArgumentException('La ficha indicada no existe.');
    }

    $id = (int) ($row['id_ficha'] ?? 0);
    $nomInstructor = trim((string) ($row['nom_instructor'] ?? ''));
    if ($nomInstructor === '') {
        $nomInstructor = 'Sin instructor';
    }

    return [
        'id_ficha' => $id,
        'nom_ficha' => 'Ficha ' . $id,
        'nom_programa' => trim((string) ($row['nom_programa'] ?? '')),
        'nom_jornada' => trim((string) ($row['nom_jornada'] ?? '')),
        'nom_instructor' => $nomInstructor,
    ];
}

function instructorFormatearFechaExport(string $iso): string
{
    if ($iso === '' || preg_match('/^\d{4}-\d{2}-\d{2}$/', $iso) !== 1) {
        return $iso;
    }

    $ts = strtotime($iso);

    return $ts !== false ? date('d/m/Y', $ts) : $iso;
}

function instructorFormatearHoraExport(array $row): string
{
    $estado = (string) ($row['ind_estado'] ?? '');
    $hora = (string) ($row['hora_asistencia'] ?? '');

    if ($hora === '' || $hora === '00:00:00' || in_array($estado, ['Pendiente', 'Ausente'], true)) {
        return '';
    }

    return substr($hora, 0, 5);
}

function instructorFormatearRetardoExport(array $row): int|string
{
    $retardo = (int) ($row['minutos_retraso'] ?? 0);

    return $retardo > 0 ? $retardo : '';
}

/**
 * Construye filas para exportación Excel de asistencia.
 *
 * @param array{
 *   desde: string,
 *   hasta: string,
 *   rows: list<array<string, mixed>>,
 *   por_fecha: array<string, array{Presente: int, Tarde: int, Ausente: int, Pendiente: int, Desconocido: int, total: int}>
 * } $asistencia
 * @param array{id_ficha: int, nom_ficha: string, nom_programa: string, nom_jornada: string, nom_instructor: string} $meta
 * @return array{
 *   detalle: list<list<scalar|null>>,
 *   detalle_bold_rows: list<int>,
 *   resumen: list<list<scalar|null>>|null,
 *   resumen_bold_rows: list<int>
 * }
 */
function instructorConstruirFilasExportacion(array $asistencia, array $meta, bool $modoRango): array
{
    $desde = (string) ($asistencia['desde'] ?? '');
    $hasta = (string) ($asistencia['hasta'] ?? '');
    $rows = is_array($asistencia['rows'] ?? null) ? $asistencia['rows'] : [];
    $porFecha = is_array($asistencia['por_fecha'] ?? null) ? $asistencia['por_fecha'] : [];
    $esUnDia = $desde === $hasta && !$modoRango;

    $periodo = instructorFormatearFechaExport($desde);
    if (!$esUnDia) {
        $periodo = instructorFormatearFechaExport($desde) . ' — ' . instructorFormatearFechaExport($hasta);
    }

    $detalle = [
        ['Ficha', (string) ($meta['id_ficha'] ?? '')],
        ['Nombre ficha', (string) ($meta['nom_ficha'] ?? '')],
        ['Carrera', (string) ($meta['nom_programa'] ?? '')],
        ['Jornada ficha', (string) ($meta['nom_jornada'] ?? '')],
        ['Instructor', (string) ($meta['nom_instructor'] ?? '')],
        ['Período', $periodo],
        [],
    ];
    $detalleBoldRows = [1, 2, 3, 4, 5, 6];

    if ($esUnDia) {
        $detalle[] = ['Aprendiz', 'Documento', 'Jornada', 'Hora', 'Retardo (min)', 'Estado'];
    } else {
        $detalle[] = ['Fecha', 'Aprendiz', 'Documento', 'Jornada', 'Hora', 'Retardo (min)', 'Estado'];
    }
    $detalleBoldRows[] = count($detalle);

    foreach ($rows as $row) {
        $fila = [];
        if (!$esUnDia) {
            $fila[] = instructorFormatearFechaExport((string) ($row['fec_asistencia'] ?? ''));
        }
        $fila[] = (string) ($row['nom_completo'] ?? '');
        $fila[] = (string) ($row['id_aprendiz'] ?? '');
        $fila[] = (string) ($row['nom_jornada'] ?? '');
        $fila[] = instructorFormatearHoraExport($row);
        $fila[] = instructorFormatearRetardoExport($row);
        $fila[] = (string) ($row['ind_estado'] ?? '');
        $detalle[] = $fila;
    }

    $resumen = null;
    $resumenBoldRows = [1];
    if (!$esUnDia && $porFecha !== []) {
        $resumen = [
            ['Fecha', 'Presente', 'Tarde', 'Ausente', 'Pendiente', 'Total'],
        ];
        foreach ($porFecha as $fec => $tot) {
            $resumen[] = [
                instructorFormatearFechaExport((string) $fec),
                (int) ($tot['Presente'] ?? 0),
                (int) ($tot['Tarde'] ?? 0),
                (int) ($tot['Ausente'] ?? 0),
                (int) ($tot['Pendiente'] ?? 0),
                (int) ($tot['total'] ?? 0),
            ];
        }
    }

    return [
        'detalle' => $detalle,
        'detalle_bold_rows' => $detalleBoldRows,
        'resumen' => $resumen,
        'resumen_bold_rows' => $resumenBoldRows,
    ];
}

/**
 * Agrupa fichas por nombre de programa (carrera).
 *
 * @param list<array<string, mixed>> $fichas
 * @return list<array{nom_programa: string, fichas: list<array<string, mixed>>, total_fichas: int, total_aprendices: int}>
 */
function instructorAgruparFichasPorPrograma(array $fichas): array
{
    $grupos = [];
    foreach ($fichas as $ficha) {
        $nom = trim((string) ($ficha['nom_programa'] ?? 'Sin programa'));
        if ($nom === '') {
            $nom = 'Sin programa';
        }
        if (!isset($grupos[$nom])) {
            $grupos[$nom] = [
                'nom_programa' => $nom,
                'fichas' => [],
                'total_fichas' => 0,
                'total_aprendices' => 0,
            ];
        }
        $grupos[$nom]['fichas'][] = $ficha;
        $grupos[$nom]['total_fichas']++;
        $grupos[$nom]['total_aprendices'] += (int) ($ficha['num_aprendices'] ?? 0);
    }

    $lista = array_values($grupos);
    usort($lista, static fn(array $a, array $b): int => strcasecmp($a['nom_programa'], $b['nom_programa']));

    return $lista;
}

/**
 * @param list<array{nom_programa: string, fichas: list<array<string, mixed>>}> $carreras
 * @return list<array<string, mixed>>
 */
function instructorFichasDePrograma(array $carreras, string $nomPrograma): array
{
    $nomPrograma = trim($nomPrograma);
    foreach ($carreras as $grupo) {
        if ((string) ($grupo['nom_programa'] ?? '') === $nomPrograma) {
            return is_array($grupo['fichas'] ?? null) ? $grupo['fichas'] : [];
        }
    }

    return [];
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
    PDOStatement $stmtAsistenciaInstructor,
    PDOStatement $stmtAsistenciaAdmin,
    array $ctx,
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

        $data = instructorListarAsistenciaPorContexto(
            $stmtAsistenciaInstructor,
            $stmtAsistenciaAdmin,
            $ctx,
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

/** Menús de sistema permitidos para instructores (no administradores). */
function instructorMenusPermitidosIds(): array
{
    return [
        '20', '202', '20201',
        '205', '20501', '20502',
        '206', '20601',
    ];
}

/** Instructor registrado sin perfil administrador: solo módulo Mis Fichas. */
function instructorEsSoloFichas(PDO $pdo, string $idUsuario): bool
{
    return instructorResolverIdDesdeSesion($pdo, $idUsuario) !== null
        && !usuarioEsAdministrador($pdo, $idUsuario);
}

/**
 * Deja solo menús operativos SGA para instructores no admin (sidebar y permisos efectivos).
 *
 * @param list<array<string, mixed>> $menuRaw
 * @return list<array<string, mixed>>
 */
function instructorFiltrarMenusUsuario(PDO $pdo, string $idUsuario, array $menuRaw): array
{
    if (usuarioEsAdministrador($pdo, $idUsuario) || !instructorEsSoloFichas($pdo, $idUsuario)) {
        return $menuRaw;
    }

    $permitidos = array_flip(instructorMenusPermitidosIds());
    $filtrado = [];
    foreach ($menuRaw as $item) {
        $idMenu = (string) ($item['id_menu'] ?? '');
        if (isset($permitidos[$idMenu]) || str_starts_with($idMenu, '20601-')) {
            $filtrado[] = $item;
        }
    }

    return $filtrado;
}

/** ID de menú lateral sintético por ficha (no existe en tab_menus). */
function instructorMenuIdFicha(int $idFicha): string
{
    return '20601-' . $idFicha;
}

/**
 * Ítems hijos dinámicos bajo menú 206 (Mis Fichas) para el sidebar del instructor.
 *
 * @return array<string, array{id_menu: string, nom_menu: string, ind_id_padre: string, nom_programa: string}>
 */
function instructorSidebarMenusFichas(PDOStatement $stmt, int $idInstructor): array
{
    $programaBase = 'pages/modulos/instructor/fichas/index.php';
    $fechaHoy = date('Y-m-d');
    $fichas = instructorListarFichas($stmt, $idInstructor);
    $items = [];

    if (count($fichas) > 1) {
        $items['20601'] = [
            'id_menu' => '20601',
            'nom_menu' => 'Todas las fichas',
            'ind_id_padre' => '206',
            'nom_programa' => $programaBase,
        ];
    }

    foreach ($fichas as $ficha) {
        $idFicha = (int) ($ficha['id_ficha'] ?? 0);
        if ($idFicha < 1) {
            continue;
        }

        $menuId = instructorMenuIdFicha($idFicha);
        $programaNom = trim((string) ($ficha['nom_programa'] ?? ''));
        $items[$menuId] = [
            'id_menu' => $menuId,
            'nom_menu' => 'Ficha ' . $idFicha,
            'ind_id_padre' => '206',
            'nom_programa' => $programaBase . '?id_ficha=' . $idFicha . '&fecha=' . urlencode($fechaHoy),
            'menu_tooltip' => $programaNom !== '' ? 'Ficha ' . $idFicha . ' — ' . $programaNom : 'Ficha ' . $idFicha,
        ];
    }

    return $items;
}

/**
 * Reemplaza hijos estáticos de Mis Fichas (206) por las fichas del instructor.
 *
 * @param array<string, array<string, mixed>> $menuJerarquia
 * @return array<string, array<string, mixed>>
 */
function instructorExpandirMenuSidebar(PDO $pdo, PDOStatement $stmtFichas, string $idUsuario, array $menuJerarquia): array
{
    if (!isset($menuJerarquia['20']['hijos']['206'])) {
        return $menuJerarquia;
    }

    if (usuarioEsAdministrador($pdo, $idUsuario)) {
        return $menuJerarquia;
    }

    $idInstructor = instructorResolverIdDesdeSesion($pdo, $idUsuario);
    if ($idInstructor === null) {
        return $menuJerarquia;
    }

    try {
        $hijosDinamicos = instructorSidebarMenusFichas($stmtFichas, $idInstructor);
        if ($hijosDinamicos !== []) {
            $menuJerarquia['20']['hijos']['206']['hijos'] = $hijosDinamicos;
        }
    } catch (PDOException) {
        /* Mantener menú estático si falla la consulta */
    }

    return $menuJerarquia;
}
