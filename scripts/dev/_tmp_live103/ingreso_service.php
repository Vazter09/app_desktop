<?php
/**
 * Lógica de registro manual de ingresos (portería).
 * Escritura vía funciones PostgreSQL (prepare.php → $stmt_fun_registrar_ingreso).
 *
 * Documentación línea por línea: docs/porteria-codigo-linea-a-linea.md
 */
require_once dirname(__DIR__, 2) . '/core/helpers.php';
require_once __DIR__ . '/documento_service.php';
require_once __DIR__ . '/parse_captura_service.php';
require_once __DIR__ . '/consulta_service.php';

/** @return numeric-string */
function ingresoNormalizarDocumento(string $raw): string
{
    return accesoNormalizarDocumento($raw);
}

/**
 * @return array{persona: array<string, mixed>|null, ingreso_abierto: array<string, mixed>|null, puede_ingresar: bool}
 */
function ingresoConsultarAcceso(
    PDOStatement $stmtBuscarPersona,
    PDOStatement $stmtIngresoAbierto,
    string $documento,
    string $tipoDoc
): array {
    return porteriaConsultarAcceso($stmtBuscarPersona, $stmtIngresoAbierto, $documento, $tipoDoc);
}

/**
 * Registra ingreso llamando fun_registrar_ingreso_manual en BD.
 * Si viene embedding facial y/o huella y la persona NO existe → tab_novedades_ingreso.
 *
 * @return int id_ingreso o id_novedad creado
 */
function ingresoRegistrarManual(
    PDOStatement $stmtFunRegistrar,
    PDOStatement $stmtIngresoAbierto,
    array $datos,
    ?PDOStatement $stmtNovedad = null,
    ?PDOStatement $stmtBuscarPersona = null
): int {
    $captura = accesoDocumentoDesdePost($datos);
    $doc = $captura['documento'];
    $tipo = $captura['tipo_doc'];
    $nom = $captura['nombres'];
    $ape = $captura['apellidos'];
    $tipoPersona = (int) ($datos['sel_tipo_persona'] ?? 0);
    $puerta = (int) ($datos['sel_entrada'] ?? 0);
    $obs = trim($datos['txt_observaciones'] ?? '');
    $metodoAut = (int) $captura['id_metodo_aut'];
    $capturaPdf417 = $captura['origen'] === 'pdf417';
    $embedding = $datos['embedding'] ?? null;
    $vectorTexto = null;
    $huellaBytea = null;
    $indVehiculo = smartcsetPgBool($datos['hid_ind_vehiculo'] ?? $datos['ind_vehiculo'] ?? false);
    $idVehiculo = strtoupper(trim((string) ($datos['hid_id_vehiculo'] ?? $datos['id_vehiculo'] ?? '')));
    if ($idVehiculo === '' || $idVehiculo === 'AAA000') {
        $idVehiculo = 'AAA000';
        $indVehiculo = false;
    }
    $indEquipo = smartcsetPgBool($datos['hid_ind_equipo'] ?? $datos['ind_equipo'] ?? false);
    $idEquipo = strtoupper(trim((string) ($datos['hid_id_equipo'] ?? $datos['id_equipo'] ?? '')));
    $descEquipo = trim((string) ($datos['hid_descripcion_equipo'] ?? $datos['descripcion_equipo'] ?? ''));
    if ($idEquipo === '111111') {
        $idEquipo = '';
    }
    if ($idEquipo !== '') {
        $indEquipo = true;
        if (strlen($descEquipo) < 5) {
            $descEquipo = 'Pendiente';
        }
    }
    if (strlen($idEquipo) > 50) {
        throw new Exception('El número de serie del equipo no puede superar 50 caracteres.');
    }
    if ($indEquipo) {
        if ($idEquipo === '') {
            throw new Exception('Indique el número de serie del equipo.');
        }
        if (strlen($descEquipo) < 5 || strlen($descEquipo) > 50) {
            throw new Exception('La descripción del equipo debe tener entre 5 y 50 caracteres.');
        }
    } else {
        $idEquipo = '';
        $descEquipo = '';
    }

    if (is_array($embedding) && $embedding !== []) {
        require_once __DIR__ . '/biometria_service.php';
        $vectorTexto = biometriaEmbeddingATexto($embedding);
    }

    $huellaB64 = trim((string) ($datos['huella_template_b64'] ?? ''));
    if ($huellaB64 !== '') {
        require_once __DIR__ . '/biometria_huella_service.php';
        $huellaBytea = biometriaHuellaAByteaLiteral(biometriaHuellaDesdeBase64($huellaB64));
    }

    if ($tipo === '') {
        throw new Exception('Seleccione el tipo de documento.');
    }
    $tieneBiometrico = ($vectorTexto !== null || $huellaBytea !== null);
    if ($tipoPersona < 1 && !$tieneBiometrico) {
        throw new Exception('Seleccione el tipo de persona (aprendiz, instructor, visitante, etc.).');
    }
    if ($nom === '' || strlen($nom) < 2) {
        throw new Exception('Indique los nombres de la persona.');
    }
    if ($ape === '' || strlen($ape) < 2) {
        throw new Exception('Indique los apellidos de la persona.');
    }
    if ($puerta < 1) {
        throw new Exception('Seleccione la puerta de ingreso.');
    }

    // Persona no registrada + biométrico → novedad (no crea tab_personas)
    if ($tieneBiometrico && $stmtNovedad !== null && $stmtBuscarPersona !== null) {
        $persona = ingresoBuscarPersona($stmtBuscarPersona, $doc, $tipo !== '' ? $tipo : 'CC');
        if ($persona === null) {
            $stmtNovedad->execute([
                $nom,
                $ape,
                $puerta,
                $vectorTexto,
                null,
                $huellaBytea,
                null,
            ]);
            $idNovedad = $stmtNovedad->fetchColumn();
            if ($idNovedad === false || (int) $idNovedad < 1) {
                throw new Exception('No se pudo registrar la novedad de ingreso.');
            }

            return (int) $idNovedad;
        }
    }

    if ($tipoPersona < 1) {
        throw new Exception('Seleccione el tipo de persona (aprendiz, instructor, visitante, etc.).');
    }

    $ingresoAbierto = salidaBuscarIngresoAbierto($stmtIngresoAbierto, $doc);
    if ($ingresoAbierto !== null) {
        $idIng = (int) ($ingresoAbierto['id_ingreso'] ?? 0);
        throw new Exception(
            "Esta persona ya tiene un ingreso activo (ingreso #{$idIng}). Registre la salida antes de un nuevo ingreso."
        );
    }

    $stmtFunRegistrar->execute([
        $doc,
        $tipo,
        $tipoPersona,
        $nom,
        $ape,
        $puerta,
        $obs !== '' ? $obs : null,
        $metodoAut,
        $capturaPdf417 ? 'true' : 'false',
        $vectorTexto,
        $huellaBytea,
        $indVehiculo ? 'true' : 'false',
        $indVehiculo ? $idVehiculo : 'AAA000',
        $indEquipo ? 'true' : 'false',
        $indEquipo ? $idEquipo : '111111',
        $indEquipo ? $descEquipo : null,
    ]);

    $idIngreso = $stmtFunRegistrar->fetchColumn();

    if ($idIngreso === false || (int) $idIngreso < 1) {
        throw new Exception('No se pudo registrar el ingreso.');
    }

    return (int) $idIngreso;
}

/**
 * Actualiza facial/huella del ingreso abierto (re-captura sin nuevo ingreso).
 *
 * @return int id_ingreso
 */
function ingresoActualizarCapturaAbierto(
    PDOStatement $stmtFunActualizar,
    PDOStatement $stmtIngresoAbierto,
    array $datos
): int {
    $captura = accesoDocumentoDesdePost($datos);
    $doc = $captura['documento'];
    $metodoAut = (int) $captura['id_metodo_aut'];
    $embedding = $datos['embedding'] ?? null;
    $vectorTexto = null;
    $huellaBytea = null;

    if (is_array($embedding) && $embedding !== []) {
        require_once __DIR__ . '/biometria_service.php';
        $vectorTexto = biometriaEmbeddingATexto($embedding);
    }

    $huellaB64 = trim((string) ($datos['huella_template_b64'] ?? ''));
    if ($huellaB64 !== '') {
        require_once __DIR__ . '/biometria_huella_service.php';
        $huellaBytea = biometriaHuellaAByteaLiteral(biometriaHuellaDesdeBase64($huellaB64));
    }

    if ($vectorTexto === null && $huellaBytea === null) {
        throw new Exception('Debe enviar una captura facial o de huella.');
    }

    $ingresoAbierto = salidaBuscarIngresoAbierto($stmtIngresoAbierto, $doc);
    if ($ingresoAbierto === null) {
        throw new Exception('No tiene un ingreso activo para actualizar la captura.');
    }

    $stmtFunActualizar->execute([
        $doc,
        $vectorTexto,
        $huellaBytea,
        $metodoAut > 0 ? $metodoAut : null,
    ]);

    $idIngreso = $stmtFunActualizar->fetchColumn();
    if ($idIngreso === false || (int) $idIngreso < 1) {
        throw new Exception('No se pudo actualizar la captura del ingreso.');
    }

    return (int) $idIngreso;
}

/**
 * @return array<string, mixed>|null
 */
function ingresoBuscarPersona(PDOStatement $stmtBuscar, string $documento, string $tipoDoc): ?array
{
    return porteriaBuscarPersona($stmtBuscar, $documento, $tipoDoc);
}
