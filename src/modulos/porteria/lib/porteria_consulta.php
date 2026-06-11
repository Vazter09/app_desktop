<?php
/**
 * Consulta unificada persona + ingreso activo (ingreso y salida portería).
 */
require_once __DIR__ . '/acceso_documento.php';
require_once __DIR__ . '/salidas_registro.php';

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
 * @return array{persona: array<string, mixed>|null, ingreso_abierto: array<string, mixed>|null, puede_ingresar: bool}
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

    return [
        'persona' => $persona,
        'ingreso_abierto' => $ingresoAbierto,
        'puede_ingresar' => $ingresoAbierto === null,
    ];
}
