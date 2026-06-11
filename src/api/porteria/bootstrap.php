<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/core/prepare.php';
require_once dirname(__DIR__, 2) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 2) . '/modulos/porteria/lib/ingresos_registro.php';
require_once dirname(__DIR__, 2) . '/modulos/porteria/lib/salidas_registro.php';
require_once dirname(__DIR__, 2) . '/modulos/porteria/lib/porteria_foto.php';
require_once __DIR__ . '/lib/ApiResponse.php';
require_once __DIR__ . '/lib/ApiAuth.php';
require_once __DIR__ . '/lib/ApiPayload.php';
require_once __DIR__ . '/lib/ApiSync.php';

/**
 * @return array<string, mixed>
 */
function porteriaApiRequireDevice(): array
{
    global $pdo;

    return ApiAuth::requireDevice($pdo);
}

/**
 * @return array<string, mixed>
 */
function porteriaApiCatalogos(): array
{
    global $stmt_list_tipos_doc, $stmt_list_tipos_persona, $stmt_list_entradas;

    $stmt_list_tipos_doc->execute();
    $tiposDoc = $stmt_list_tipos_doc->fetchAll(PDO::FETCH_ASSOC);

    $stmt_list_tipos_persona->execute();
    $tiposPersona = $stmt_list_tipos_persona->fetchAll(PDO::FETCH_ASSOC);

    $stmt_list_entradas->execute();
    $entradas = $stmt_list_entradas->fetchAll(PDO::FETCH_ASSOC);

    return [
        'tipos_doc' => array_map(static fn(array $r): array => [
            'id' => (string) ($r['id_tipo_docum'] ?? ''),
            'nombre' => (string) ($r['nom_tipo_docum'] ?? ''),
        ], $tiposDoc),
        'tipos_persona' => array_map(static fn(array $r): array => [
            'id' => (int) ($r['id_tipo_persona'] ?? 0),
            'nombre' => (string) ($r['nom_tipo_persona'] ?? ''),
        ], $tiposPersona),
        'entradas' => array_map(static fn(array $r): array => [
            'id' => (int) ($r['id_entrada'] ?? $r['id_entrada_centro'] ?? 0),
            'nombre' => (string) ($r['nom_entrada'] ?? $r['nom_entrada_centro'] ?? ''),
            'id_centro' => (int) ($r['id_centro'] ?? 0),
            'id_sede' => (int) ($r['id_sede'] ?? 0),
        ], $entradas),
    ];
}

/**
 * @param array<string, mixed> $device
 * @param array<string, mixed> $json
 * @return array{id_ingreso: int, client_id: string|null}
 */
function porteriaApiRegistrarIngreso(array $device, array $json): array
{
    global $pdo, $stmt_fun_registrar_ingreso, $stmt_buscar_ingreso_abierto;

    $clientId = trim((string) ($json['client_id'] ?? ''));
    if ($clientId !== '') {
        if (!ApiSync::isValidUuid($clientId)) {
            throw new Exception('client_id inválido.');
        }
        $existing = ApiSync::findByClientId($pdo, $clientId);
        if ($existing !== null) {
            return [
                'id_ingreso' => (int) $existing['id_ingreso'],
                'client_id' => $clientId,
            ];
        }
    }

    $post = ApiPayload::ingresoToPost($json);
    if ((int) ($post['sel_entrada'] ?? 0) < 1 && !empty($device['id_entrada_default'])) {
        $post['sel_entrada'] = (int) $device['id_entrada_default'];
    }

    $idIngreso = ingresoRegistrarManual(
        $stmt_fun_registrar_ingreso,
        $stmt_buscar_ingreso_abierto,
        $post,
        (string) $device['id_usuario_audit']
    );

    $foto = trim((string) ($json['foto_base64'] ?? $post['hid_foto_data'] ?? ''));
    if ($foto !== '') {
        porteriaGuardarFotoRegistro($pdo, $idIngreso, 'ingreso', $foto);
    }

    if ($clientId !== '') {
        ApiSync::registerClientId(
            $pdo,
            $clientId,
            (int) $device['id_dispositivo'],
            'ingreso',
            $idIngreso
        );
    }

    return ['id_ingreso' => $idIngreso, 'client_id' => $clientId !== '' ? $clientId : null];
}

/**
 * @param array<string, mixed> $device
 * @param array<string, mixed> $json
 * @return array{id_ingreso: int, client_id: string|null}
 */
function porteriaApiRegistrarSalida(array $device, array $json): array
{
    global $pdo, $stmt_fun_registrar_salida, $stmt_buscar_ingreso_abierto;

    $clientId = trim((string) ($json['client_id'] ?? ''));
    if ($clientId !== '') {
        if (!ApiSync::isValidUuid($clientId)) {
            throw new Exception('client_id inválido.');
        }
        $existing = ApiSync::findByClientId($pdo, $clientId);
        if ($existing !== null) {
            return [
                'id_ingreso' => (int) $existing['id_ingreso'],
                'client_id' => $clientId,
            ];
        }
    }

    $post = ApiPayload::salidaToPost($json);
    $idIngreso = salidaRegistrarManual(
        $stmt_fun_registrar_salida,
        $stmt_buscar_ingreso_abierto,
        $post,
        (string) $device['id_usuario_audit']
    );

    $foto = trim((string) ($json['foto_base64'] ?? $post['hid_foto_data'] ?? ''));
    if ($foto !== '') {
        porteriaGuardarFotoRegistro($pdo, $idIngreso, 'salida', $foto);
    }

    if ($clientId !== '') {
        ApiSync::registerClientId(
            $pdo,
            $clientId,
            (int) $device['id_dispositivo'],
            'salida',
            $idIngreso
        );
    }

    return ['id_ingreso' => $idIngreso, 'client_id' => $clientId !== '' ? $clientId : null];
}

/**
 * @return list<array<string, mixed>>
 */
function porteriaApiListIngresosHoy(): array
{
    global $stmt_list_ingresos_hoy;
    $stmt_list_ingresos_hoy->execute();
    $rows = $stmt_list_ingresos_hoy->fetchAll(PDO::FETCH_ASSOC);

    return array_map(static function (array $r): array {
        return [
            'id_ingreso' => (int) ($r['id_ingreso'] ?? 0),
            'fec_ingreso' => (string) ($r['fec_ingreso'] ?? ''),
            'documento' => (string) ($r['id_persona'] ?? ''),
            'tipo_doc' => (string) ($r['id_tipo_docum'] ?? ''),
            'nombres' => (string) ($r['nom_persona'] ?? ''),
            'apellidos' => (string) ($r['ape_persona'] ?? ''),
            'tipo_persona' => (int) ($r['id_tipo_persona'] ?? 0),
            'nom_tipo_persona' => (string) ($r['nom_tipo_persona'] ?? ''),
            'id_entrada' => (int) ($r['id_entrada_centro'] ?? 0),
            'nom_entrada' => (string) ($r['nom_entrada_centro'] ?? ''),
            'observaciones' => (string) ($r['val_observaciones'] ?? ''),
        ];
    }, $rows);
}

/**
 * @return list<array<string, mixed>>
 */
function porteriaApiListSalidasHoy(): array
{
    global $stmt_list_salidas_hoy;
    $stmt_list_salidas_hoy->execute();
    $rows = $stmt_list_salidas_hoy->fetchAll(PDO::FETCH_ASSOC);

    return array_map(static function (array $r): array {
        return [
            'id_ingreso' => (int) ($r['id_ingreso'] ?? 0),
            'fec_ingreso' => (string) ($r['fec_ingreso'] ?? ''),
            'fec_salida' => (string) ($r['fec_salida'] ?? ''),
            'documento' => (string) ($r['id_persona'] ?? ''),
            'tipo_doc' => (string) ($r['id_tipo_docum'] ?? ''),
            'nombres' => (string) ($r['nom_persona'] ?? ''),
            'apellidos' => (string) ($r['ape_persona'] ?? ''),
            'tipo_persona' => (int) ($r['id_tipo_persona'] ?? 0),
            'nom_tipo_persona' => (string) ($r['nom_tipo_persona'] ?? ''),
            'id_entrada' => (int) ($r['id_entrada_centro'] ?? 0),
            'nom_entrada' => (string) ($r['nom_entrada_centro'] ?? ''),
            'observaciones' => (string) ($r['val_observaciones'] ?? ''),
        ];
    }, $rows);
}
