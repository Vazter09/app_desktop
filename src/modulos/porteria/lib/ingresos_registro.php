<?php
/**
 * Lógica de registro manual de ingresos (portería).
 * Escritura vía funciones PostgreSQL (prepare.php → $stmt_fun_registrar_ingreso).
 *
 * Documentación línea por línea: docs/porteria-codigo-linea-a-linea.md
 */
require_once __DIR__ . '/acceso_documento.php';
require_once __DIR__ . '/acceso_parse_captura.php';
require_once __DIR__ . '/porteria_consulta.php';
require_once __DIR__ . '/salidas_registro.php';

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
 *
 * @return int id_ingreso creado
 */
function ingresoRegistrarManual(
    PDOStatement $stmtFunRegistrar,
    PDOStatement $stmtIngresoAbierto,
    array $datos,
    string $usrAudit
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

    if ($tipo === '') {
        throw new Exception('Seleccione el tipo de documento.');
    }
    if ($tipoPersona < 1) {
        throw new Exception('Seleccione el tipo de persona (aprendiz, instructor, visitante, etc.).');
    }
    if ($nom === '' || strlen($nom) < 2) {
        throw new Exception('Indique los nombres de la persona.');
    }
    if ($ape === '' || strlen($ape) < 2) {
        throw new Exception('Indique los apellidos de la persona.');
    }

    $ingresoAbierto = salidaBuscarIngresoAbierto($stmtIngresoAbierto, $doc, $tipo);
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
        $usrAudit,
        $metodoAut,
        // PDO(pgsql) puede convertir `false` a string vacío; Postgres no acepta ""::boolean.
        $capturaPdf417 ? 'true' : 'false',
    ]);

    $idIngreso = $stmtFunRegistrar->fetchColumn();

    if ($idIngreso === false || (int) $idIngreso < 1) {
        throw new Exception('No se pudo registrar el ingreso.');
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
