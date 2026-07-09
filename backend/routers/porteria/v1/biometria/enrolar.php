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
 *         "calidad_facial": { "type": "number", "nullable": true }
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
$embedding = $json['embedding'] ?? null;
$calidad = isset($json['calidad_facial']) ? (float) $json['calidad_facial'] : null;
$fotoBase64 = trim((string) ($json['foto_base64'] ?? ''));

if ($documento === '') {
    RouterResponse::fail('El documento es obligatorio.');
}
if (!is_array($embedding)) {
    RouterResponse::fail('El vector facial (embedding) es obligatorio.');
}

try {
    global $pdo, $stmt_buscar_persona_doc, $stmt_fun_guardar_enrolamiento_facial;

    $stmt_buscar_persona_doc->execute([$documento, 'CC']);
    $persona = $stmt_buscar_persona_doc->fetch();
    if (!$persona) {
        RouterResponse::fail('La persona no está registrada — no se puede enrolar.', 404);
    }

    // Guardar foto si viene (E2, E6: validación)
    $rutaFoto = null;
    if (!empty($fotoBase64)) {
        $rutaFoto = BiometriaPhotoService::guardarFoto(
            (int) $persona['id_persona'],
            (string) ($persona['nom_persona'] ?? 'persona'),
            $fotoBase64
        );
    }

    $pdo->exec('SET app.usuario = ' . $pdo->quote($usrAudit));

    $idEnrolamiento = biometriaGuardarEnrolamiento(
        $stmt_fun_guardar_enrolamiento_facial,
        (int) $persona['id_persona'],
        $embedding,
        $calidad,
        $rutaFoto  // Nuevo parámetro
    );

    RouterResponse::ok(['id_enrolamiento' => $idEnrolamiento]);
} catch (InvalidArgumentException $e) {
    RouterResponse::fail($e->getMessage());
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
