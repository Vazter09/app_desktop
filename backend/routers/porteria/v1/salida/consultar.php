<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Consultar persona e ingreso abierto para salida",
 *   "tags": ["Portería"],
 *   "parameters": [
 *     { "name": "documento", "in": "query", "required": true, "schema": { "type": "string" } },
 *     { "name": "tipo_doc", "in": "query", "schema": { "type": "string", "default": "CC" } }
 *   ],
 *   "responses": {
 *     "200": { "description": "Estado de acceso para salida", "dataSchema": { "type": "object", "properties": { "persona": { "type": "object" }, "ingreso_abierto": { "type": "object", "nullable": true }, "puede_salir": { "type": "boolean" }, "foto_base64": { "type": "string", "nullable": true } } } }
 *   }
 * }
 */
require_once dirname(__DIR__, 2) . '/prepare.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session_or_device.php';
require_once dirname(__DIR__, 4) . '/services/porteria/biometria_photo_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

porteriaRequireSessionOrDevice();

$documento = trim((string) ($_GET['documento'] ?? ''));
$tipoDoc = trim((string) ($_GET['tipo_doc'] ?? 'CC'));

try {
    global $pdo, $stmt_buscar_persona_doc, $stmt_buscar_ingreso_abierto;
    $resultado = salidaConsultarAcceso(
        $stmt_buscar_persona_doc,
        $stmt_buscar_ingreso_abierto,
        $documento,
        $tipoDoc
    );
    $resultado['persona'] = porteriaAdjuntarEquipoAsignado($pdo, $resultado['persona']);

    $fotoBase64 = null;
    $tienePatronFacial = false;
    if ($resultado['persona'] !== null) {
        $idPersona = (int) ($resultado['persona']['id_persona'] ?? 0);
        $stmtRuta = $pdo->prepare(
            'SELECT ruta_foto_facial,
                    (val_patron_facial IS NOT NULL) AS tiene_vector
               FROM tab_personas
              WHERE id_persona = ?::NUMERIC
              LIMIT 1'
        );
        $stmtRuta->execute([(string) $idPersona]);
        $rowBio = $stmtRuta->fetch(PDO::FETCH_ASSOC) ?: [];
        $ruta = (string) ($rowBio['ruta_foto_facial'] ?? '');
        $tienePatronFacial = !empty($rowBio['tiene_vector']);
        $fotoBase64 = BiometriaPhotoService::resolverFotoBase64($ruta, $idPersona);
    }

    $personaFmt = PorteriaRouterPayload::formatPersona($resultado['persona']);
    if ($personaFmt !== null) {
        $personaFmt['foto_base64'] = $fotoBase64;
        $personaFmt['foto_disponible'] = $fotoBase64 !== null;
        $personaFmt['tiene_patron_facial'] = $tienePatronFacial;
    }

    RouterResponse::ok([
        'persona' => $personaFmt,
        'ingreso_abierto' => PorteriaRouterPayload::formatIngresoAbierto($resultado['ingreso_abierto']),
        'puede_salir' => (bool) $resultado['puede_salir'],
        'segundos_restantes_salida' => (int) ($resultado['segundos_restantes_salida'] ?? 0),
        'minutos_min_salida' => (int) ($resultado['minutos_min_salida'] ?? PORTERIA_MINUTOS_MIN_SALIDA),
        'foto_base64' => $fotoBase64,
        'foto_disponible' => $fotoBase64 !== null,
        'tiene_patron_facial' => $tienePatronFacial,
    ]);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
