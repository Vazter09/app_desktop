<?php
/**
 * Lógica de registro manual de salidas (portería).
 */
require_once __DIR__ . '/documento_service.php';
require_once __DIR__ . '/parse_captura_service.php';
require_once __DIR__ . '/consulta_service.php';

/**
 * @return array{persona: array<string, mixed>|null, ingreso_abierto: array<string, mixed>|null, puede_salir: bool}
 */
function salidaConsultarAcceso(
    PDOStatement $stmtBuscarPersona,
    PDOStatement $stmtIngresoAbierto,
    string $documento,
    string $tipoDoc
): array {
    $resultado = porteriaConsultarAcceso($stmtBuscarPersona, $stmtIngresoAbierto, $documento, $tipoDoc);

    return [
        'persona' => $resultado['persona'],
        'ingreso_abierto' => $resultado['ingreso_abierto'],
        'puede_salir' => $resultado['ingreso_abierto'] !== null,
    ];
}

/**
 * Registra salida llamando fun_registrar_salida_manual en BD.
 *
 * @return int id_ingreso actualizado
 */
function salidaRegistrarManual(
    PDOStatement $stmtFunRegistrar,
    PDOStatement $stmtIngresoAbierto,
    array $datos,
    string $usrAudit
): int {
    $captura = accesoDocumentoDesdePost($datos);
    $doc = $captura['documento'];
    $tipo = $captura['tipo_doc'];
    $obs = trim($datos['txt_observaciones'] ?? '');

    if ($tipo === '') {
        throw new Exception('Seleccione el tipo de documento.');
    }

    $ingresoAbierto = salidaBuscarIngresoAbierto($stmtIngresoAbierto, $doc);
    if ($ingresoAbierto === null) {
        throw new Exception(
            'No tiene un ingreso activo para registrar salida. Verifique el documento o registre primero el ingreso.'
        );
    }

    $stmtFunRegistrar->execute([
        $doc,
        $tipo,
        $obs !== '' ? $obs : null,
        $usrAudit,
    ]);

    $idIngreso = $stmtFunRegistrar->fetchColumn();

    if ($idIngreso === false || (int) $idIngreso < 1) {
        throw new Exception('No se pudo registrar la salida.');
    }

    return (int) $idIngreso;
}
