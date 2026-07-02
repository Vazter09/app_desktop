<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/core/prepare.php';
require_once dirname(__DIR__, 2) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 2) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 2) . '/services/porteria/ingreso_service.php';
require_once dirname(__DIR__, 2) . '/services/porteria/salida_service.php';
require_once dirname(__DIR__, 2) . '/services/porteria/foto_service.php';
require_once dirname(__DIR__, 2) . '/services/porteria/biometria_service.php';
require_once __DIR__ . '/_lib/Payload.php';
require_once __DIR__ . '/_lib/Sync.php';
require_once __DIR__ . '/_lib/Auth.php';

/**
 * @return array<string, mixed>
 */
function porteriaApiRequireDevice(): array
{
    global $pdo;

    return PorteriaRouterAuth::requireDevice($pdo);
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
        if (!PorteriaRouterSync::isValidUuid($clientId)) {
            throw new Exception('client_id inválido.');
        }
        $existing = PorteriaRouterSync::findByClientId($pdo, $clientId);
        if ($existing !== null) {
            return [
                'id_ingreso' => (int) $existing['id_ingreso'],
                'client_id' => $clientId,
            ];
        }
    }

    $post = PorteriaRouterPayload::ingresoToPost($json);
    if ((int) ($post['sel_entrada'] ?? 0) < 1 && !empty($device['id_entrada_default'])) {
        $post['sel_entrada'] = (int) $device['id_entrada_default'];
    }

    $usrAudit = (string) ($device['id_usuario_audit'] ?? $device['usr_audit'] ?? 'system');
    $pdo->exec("SET app.usuario = " . $pdo->quote($usrAudit));
    $idIngreso = ingresoRegistrarManual(
        $stmt_fun_registrar_ingreso,
        $stmt_buscar_ingreso_abierto,
        $post
    );

    $foto = trim((string) ($json['foto_base64'] ?? $post['hid_foto_data'] ?? ''));
    if ($foto !== '') {
        porteriaGuardarFotoRegistro($pdo, $idIngreso, 'ingreso', $foto);
    }

    if ($clientId !== '' && !empty($device['id_dispositivo'])) {
        PorteriaRouterSync::registerClientId(
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
        if (!PorteriaRouterSync::isValidUuid($clientId)) {
            throw new Exception('client_id inválido.');
        }
        $existing = PorteriaRouterSync::findByClientId($pdo, $clientId);
        if ($existing !== null) {
            return [
                'id_ingreso' => (int) $existing['id_ingreso'],
                'client_id' => $clientId,
            ];
        }
    }

    $post = PorteriaRouterPayload::salidaToPost($json);
    $usrAudit = (string) ($device['id_usuario_audit'] ?? $device['usr_audit'] ?? 'system');
    $pdo->exec("SET app.usuario = " . $pdo->quote($usrAudit));
    $idIngreso = salidaRegistrarManual(
        $stmt_fun_registrar_salida,
        $stmt_buscar_ingreso_abierto,
        $post
    );

    $foto = trim((string) ($json['foto_base64'] ?? $post['hid_foto_data'] ?? ''));
    if ($foto !== '') {
        porteriaGuardarFotoRegistro($pdo, $idIngreso, 'salida', $foto);
    }

    if ($clientId !== '' && !empty($device['id_dispositivo'])) {
        PorteriaRouterSync::registerClientId(
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

/**
 * Enrola biometría facial de una persona ya registrada en tab_personas.
 *
 * @param array<string, mixed> $json {documento: string, vector_facial: float[], foto_base64?: string, calidad_facial?: float}
 * @return array{id_persona: int}
 */
function porteriaApiEnrolarBiometria(array $device, array $json): array
{
    global $pdo, $stmt_fun_guardar_biometria;

    $idPersona = (int) trim((string) ($json['documento'] ?? ''));
    $vector = $json['vector_facial'] ?? null;
    if (!is_array($vector)) {
        throw new Exception('Falta el vector facial.');
    }

    $uriFoto = null;
    $foto = trim((string) ($json['foto_base64'] ?? ''));
    if ($foto !== '') {
        $uriFoto = biometriaGuardarFoto($idPersona, $foto);
    }

    $usrAudit = (string) ($device['id_usuario_audit'] ?? $device['usr_audit'] ?? 'system');
    $pdo->exec("SET app.usuario = " . $pdo->quote($usrAudit));

    biometriaEnrolar(
        $stmt_fun_guardar_biometria,
        $idPersona,
        array_map('floatval', $vector),
        $uriFoto,
        (float) ($json['calidad_facial'] ?? 0.0)
    );

    return ['id_persona' => $idPersona];
}

/**
 * Identifica a la persona más parecida al vector facial recibido.
 *
 * @param array<string, mixed> $json {vector_facial: float[]}
 * @return array{id_persona: int|null, distancia: float|null}
 */
function porteriaApiIdentificarBiometria(array $json): array
{
    global $stmt_fun_identificar_rostro;

    $vector = $json['vector_facial'] ?? null;
    if (!is_array($vector)) {
        throw new Exception('Falta el vector facial.');
    }

    $match = biometriaIdentificar($stmt_fun_identificar_rostro, array_map('floatval', $vector));
    if ($match === null) {
        return ['id_persona' => null, 'distancia' => null];
    }

    return $match;
}
