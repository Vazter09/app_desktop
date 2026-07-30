<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Enrolar rostro para una persona ya registrada",
 *   "tags": ["Portería", "Biometría"],
 *   "requestBody": {
 *     "required": ["documento", "embedding"],
 *     "schema": {
 *       "type": "object",
 *       "properties": {
 *         "documento": { "type": "string" },
 *         "embedding": { "type": "array", "items": { "type": "number" }, "minItems": 128, "maxItems": 128 },
 *         "calidad_facial": { "type": "number", "nullable": true },
 *         "forzar": { "type": "boolean", "description": "Si true, reemplaza vector/foto existentes (Capturar Rostro)" }
 *       }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Enrolamiento guardado", "dataSchema": { "type": "object", "properties": { "id_enrolamiento": { "type": "integer" } } } }
 *   }
 * }
 */
require_once dirname(__DIR__, 2) . '/prepare.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session_or_device.php';
require_once dirname(__DIR__, 4) . '/services/porteria/biometria_photo_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$auth = porteriaRequireSessionOrDevice();
$usrAudit = porteriaAuthAuditUser($auth);

$json = PorteriaRouterPayload::readJsonBody();
$documento = trim((string) ($json['documento'] ?? ''));
$tipoDoc = trim((string) ($json['tipo_doc'] ?? 'CC'));
if ($tipoDoc === '') {
    $tipoDoc = 'CC';
}
$embedding = $json['embedding'] ?? null;
$calidad = isset($json['calidad_facial']) ? (float) $json['calidad_facial'] : null;
$fotoBase64 = trim((string) ($json['foto_base64'] ?? ''));
$forzar = filter_var($json['forzar'] ?? false, FILTER_VALIDATE_BOOLEAN);

if ($documento === '') {
    RouterResponse::fail('El documento es obligatorio.');
}
if (!is_array($embedding)) {
    RouterResponse::fail('El vector facial (embedding) es obligatorio.');
}

try {
    global $pdo, $stmt_buscar_persona_doc, $stmt_fun_guardar_enrolamiento_facial;

    $stmt_buscar_persona_doc->execute([$documento, $tipoDoc]);
    $persona = $stmt_buscar_persona_doc->fetch();
    // Fallback: documento == id_persona (flujo desktop frecuente).
    if (!$persona && ctype_digit($documento)) {
        $stmt_buscar_persona_doc->execute([$documento, 'CC']);
        $persona = $stmt_buscar_persona_doc->fetch();
    }
    if (!$persona) {
        RouterResponse::fail('La persona no está registrada — no se puede enrolar.', 404);
    }

    $idPersona = (int) $persona['id_persona'];
    $stmtEstado = $pdo->prepare(
        'SELECT ruta_foto_facial,
                (val_patron_facial IS NOT NULL) AS tiene_vector
           FROM tab_personas
          WHERE id_persona = ?::NUMERIC
          LIMIT 1'
    );
    $stmtEstado->execute([(string) $idPersona]);
    $estado = $stmtEstado->fetch(PDO::FETCH_ASSOC) ?: [];
    $tieneVector = !empty($estado['tiene_vector']);
    $rutaActual = trim((string) ($estado['ruta_foto_facial'] ?? ''));

    // Referencia estable: no reescribir vector/foto en cada ingreso/salida.
    if (!$forzar && $tieneVector) {
        $fotoExistente = BiometriaPhotoService::resolverFotoBase64($rutaActual, $idPersona);
        RouterResponse::ok([
            'id_enrolamiento' => $idPersona,
            'id_persona' => $idPersona,
            'ruta_foto_facial' => $rutaActual !== '' ? $rutaActual : null,
            'foto_base64' => $fotoExistente,
            'ya_enrolado' => true,
            'actualizado' => false,
        ]);
    }

    if ($fotoBase64 === '') {
        RouterResponse::fail(
            'La foto del rostro es obligatoria para enrolar. Capture de nuevo.'
        );
    }
    $rutaFoto = BiometriaPhotoService::guardarFoto(
        $idPersona,
        (string) ($persona['nom_persona'] ?? 'persona'),
        $fotoBase64
    );
    if ($rutaFoto === null || $rutaFoto === '' || !BiometriaPhotoService::esRutaFotoValida($rutaFoto)) {
        RouterResponse::fail('No se pudo guardar la foto de enrolamiento.');
    }

    $pdo->exec('SET app.usuario = ' . $pdo->quote($usrAudit));

    $idPersona = biometriaGuardarEnrolamiento(
        $stmt_fun_guardar_enrolamiento_facial,
        $idPersona,
        $embedding,
        $calidad,
        $rutaFoto
    );

    RouterResponse::ok([
        'id_enrolamiento' => $idPersona,
        'id_persona' => $idPersona,
        'ruta_foto_facial' => $rutaFoto,
        'foto_base64' => BiometriaPhotoService::leerFoto($rutaFoto),
        'ya_enrolado' => false,
        'actualizado' => true,
    ]);
} catch (InvalidArgumentException $e) {
    RouterResponse::fail($e->getMessage());
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
