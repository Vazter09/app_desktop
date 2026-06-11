<?php
/**
 * Lógica de registro manual de salidas (portería).
 */
require_once __DIR__ . '/acceso_documento.php';
require_once __DIR__ . '/acceso_parse_captura.php';

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
 * @return array{persona: array<string, mixed>|null, ingreso_abierto: array<string, mixed>|null, puede_salir: bool}
 */
function salidaConsultarAcceso(
    PDOStatement $stmtBuscarPersona,
    PDOStatement $stmtIngresoAbierto,
    string $documento,
    string $tipoDoc
): array {
    require_once __DIR__ . '/porteria_consulta.php';

    $resultado = porteriaConsultarAcceso($stmtBuscarPersona, $stmtIngresoAbierto, $documento, $tipoDoc);

    return [
        'persona' => $resultado['persona'],
        'ingreso_abierto' => $resultado['ingreso_abierto'],
        'puede_salir' => $resultado['ingreso_abierto'] !== null,
    ];
}

/**
 * @return int id_ingreso con salida registrada
 */
function salidaRegistrarManual(
    PDOStatement $stmtFunRegistrar,
    PDOStatement $stmtIngresoAbierto,
    array $post,
    string $usrAudit
): int {
    $captura = accesoDocumentoDesdePost($post);
    $doc = $captura['documento'];
    $tipo = $captura['tipo_doc'];
    $obs = trim($post['txt_observaciones'] ?? '');

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
