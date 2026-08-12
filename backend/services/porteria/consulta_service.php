<?php
/**
 * Consulta unificada persona + ingreso activo (ingreso y salida portería).
 */
require_once __DIR__ . '/documento_service.php';

/**
 * Segundos mínimos entre ingreso y salida (5 minutos).
 * Por debajo: se actualiza la captura del ingreso abierto (última del rango).
 */
const PORTERIA_SEGUNDOS_MIN_SALIDA = 300;

/** Minutos equivalentes (compat API). */
const PORTERIA_MINUTOS_MIN_SALIDA = 5;

/**
 * Segundos mínimos entre una salida cerrada y un nuevo ingreso (5 minutos).
 */
const PORTERIA_SEGUNDOS_MIN_REINGRESO = 300;

/** Minutos equivalentes reingreso. */
const PORTERIA_MINUTOS_MIN_REINGRESO = 5;

/**
 * Ventana corta de re-captura (s): si re-identifica dentro de este rango
 * tras el ingreso, siempre se actualiza la última captura (no error / no salida).
 */
const PORTERIA_SEGUNDOS_RECAPTURA = 30;

/**
 * @return array<string, mixed>|null
 */
function salidaBuscarIngresoAbierto(PDOStatement $stmtBuscar, string $documento): ?array
{
    $doc = accesoNormalizarDocumento($documento);
    $stmtBuscar->execute([$doc]);
    $row = $stmtBuscar->fetch(PDO::FETCH_ASSOC);

    return $row ?: null;
}

/**
 * @return array<string, mixed>|null
 */
function porteriaBuscarPersona(PDOStatement $stmtBuscar, string $documento, string $tipoDoc): ?array
{
    $doc = accesoNormalizarDocumento($documento);
    $tipo = trim($tipoDoc);
    if ($tipo === '') {
        throw new Exception('Tipo de documento inválido.');
    }
    $stmtBuscar->execute([$doc, $tipo]);
    $row = $stmtBuscar->fetch(PDO::FETCH_ASSOC);

    return $row ?: null;
}

/**
 * Segundos desde un timestamp de BD (hora civil Colombia / DB_TIMEZONE).
 *
 * Si el valor naive queda "en el futuro" al interpretarlo como Bogotá,
 * se reintenta como reloj UTC (filas antiguas antes de smartcset_now_local).
 */
function porteriaSegundosDesdeTimestamp(?string $raw): int
{
    $raw = trim((string) $raw);
    if ($raw === '') {
        return 0;
    }

    $tzName = defined('DB_TIMEZONE') ? (string) DB_TIMEZONE : 'America/Bogota';
    $now = time();

    try {
        $epoch = (new DateTimeImmutable($raw, new DateTimeZone($tzName)))->getTimestamp();
    } catch (Exception) {
        $ts = strtotime($raw);
        if ($ts === false) {
            return 0;
        }
        $epoch = $ts;
    }

    // Naive UTC wall-clock leído como Bogotá → "futuro"; corregir a UTC.
    if ($epoch > $now + 60) {
        try {
            $epochUtc = (new DateTimeImmutable($raw, new DateTimeZone('UTC')))->getTimestamp();
            if ($epochUtc <= $now + 60) {
                $epoch = $epochUtc;
            }
        } catch (Exception) {
            // conservar $epoch original
        }
    }

    return max(0, $now - $epoch);
}

/**
 * Segundos transcurridos desde fec_ingreso del ingreso abierto (0 si no hay).
 */
function porteriaSegundosDesdeIngresoAbierto(?array $ingresoAbierto): int
{
    if ($ingresoAbierto === null) {
        return 0;
    }

    return porteriaSegundosDesdeTimestamp($ingresoAbierto['fec_ingreso'] ?? null);
}

/**
 * Cooldown tras salida cerrada (fec_ultima_salida > fec_ultima_entrada).
 *
 * @return array{
 *   en_espera_reingreso: bool,
 *   segundos_desde_salida: int,
 *   segundos_restantes_reingreso: int,
 *   segundos_min_reingreso: int,
 *   minutos_min_reingreso: int
 * }
 */
function porteriaReglasReingresoTrasSalida(?array $persona): array
{
    $segundosMin = PORTERIA_SEGUNDOS_MIN_REINGRESO;
    $entrada = trim((string) ($persona['fec_ultima_entrada'] ?? ''));
    $salida = trim((string) ($persona['fec_ultima_salida'] ?? ''));

    $tsEntrada = $entrada !== '' ? strtotime($entrada) : false;
    $tsSalida = $salida !== '' ? strtotime($salida) : false;

    // Salida cerrada: fec_salida estrictamente posterior a fec_entrada.
    $tieneSalidaCerrada = $tsEntrada !== false && $tsSalida !== false && $tsSalida > $tsEntrada;
    $desde = $tieneSalidaCerrada ? max(0, time() - $tsSalida) : 0;
    $restantes = $tieneSalidaCerrada ? max(0, $segundosMin - $desde) : 0;

    return [
        'en_espera_reingreso' => $tieneSalidaCerrada && $restantes > 0,
        'segundos_desde_salida' => $desde,
        'segundos_restantes_reingreso' => $restantes,
        'segundos_min_reingreso' => $segundosMin,
        'minutos_min_reingreso' => PORTERIA_MINUTOS_MIN_REINGRESO,
    ];
}

/**
 * @return array{
 *   puede_salir: bool,
 *   segundos_desde_ingreso: int,
 *   segundos_restantes_salida: int,
 *   segundos_min_salida: int,
 *   minutos_min_salida: int
 * }
 */
function porteriaReglasSalidaTiempo(?array $ingresoAbierto): array
{
    $segundosMin = PORTERIA_SEGUNDOS_MIN_SALIDA;
    $desde = porteriaSegundosDesdeIngresoAbierto($ingresoAbierto);
    $restantes = max(0, $segundosMin - $desde);

    return [
        'puede_salir' => $ingresoAbierto !== null && $restantes === 0,
        'segundos_desde_ingreso' => $desde,
        'segundos_restantes_salida' => $restantes,
        'segundos_min_salida' => $segundosMin,
        'minutos_min_salida' => PORTERIA_MINUTOS_MIN_SALIDA,
    ];
}

/**
 * @return array{
 *   persona: array<string, mixed>|null,
 *   ingreso_abierto: array<string, mixed>|null,
 *   puede_ingresar: bool,
 *   puede_salir: bool,
 *   puede_actualizar_captura: bool,
 *   en_espera_reingreso: bool,
 *   segundos_restantes_reingreso: int,
 *   segundos_restantes_salida: int,
 *   segundos_min_salida: int,
 *   minutos_min_salida: int,
 *   minutos_min_reingreso: int
 * }
 */
function porteriaConsultarAcceso(
    PDOStatement $stmtBuscarPersona,
    PDOStatement $stmtIngresoAbierto,
    string $documento,
    string $tipoDoc
): array {
    $doc = accesoNormalizarDocumento($documento);
    $tipo = trim($tipoDoc);
    if ($tipo === '') {
        throw new Exception('Tipo de documento inválido.');
    }

    $persona = porteriaBuscarPersona($stmtBuscarPersona, $doc, $tipo);
    $ingresoAbierto = salidaBuscarIngresoAbierto($stmtIngresoAbierto, $doc);
    $tiempo = porteriaReglasSalidaTiempo($ingresoAbierto);
    $reingreso = porteriaReglasReingresoTrasSalida($persona);
    $tieneAbierto = $ingresoAbierto !== null;
    $desde = $tiempo['segundos_desde_ingreso'];

    // Actualizar captura: ingreso abierto y aún no puede salir.
    $puedeActualizar = $tieneAbierto && !$tiempo['puede_salir'];
    // Nuevo ingreso solo si no hay abierto y ya pasó el cooldown post-salida.
    $puedeIngresar = !$tieneAbierto && !$reingreso['en_espera_reingreso'];

    return [
        'persona' => $persona,
        'ingreso_abierto' => $ingresoAbierto,
        'puede_ingresar' => $puedeIngresar,
        'puede_salir' => $tiempo['puede_salir'],
        'puede_actualizar_captura' => $puedeActualizar,
        'en_espera_reingreso' => $reingreso['en_espera_reingreso'],
        'segundos_desde_ingreso' => $desde,
        'segundos_restantes_salida' => $tiempo['segundos_restantes_salida'],
        'segundos_restantes_reingreso' => $reingreso['segundos_restantes_reingreso'],
        'segundos_min_salida' => $tiempo['segundos_min_salida'],
        'minutos_min_salida' => $tiempo['minutos_min_salida'],
        'minutos_min_reingreso' => $reingreso['minutos_min_reingreso'],
        'en_ventana_recaptura' => $tieneAbierto && $desde < PORTERIA_SEGUNDOS_RECAPTURA,
    ];
}
