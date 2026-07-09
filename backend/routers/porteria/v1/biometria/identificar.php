<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Identificar persona por vector facial",
 *   "tags": ["Portería", "Biometría"],
 *   "description": "Solo identifica — NO decide ni registra ingreso/salida. El cliente reutiliza ingreso/consultar.php o salida/consultar.php con el documento devuelto para decidir cuál corresponde (mismo patrón que la captura manual), y registra con id_metodo_aut=4 (Biométrico facial).",
 *   "requestBody": {
 *     "required": ["embedding"],
 *     "schema": {
 *       "type": "object",
 *       "properties": {
 *         "embedding": { "type": "array", "items": { "type": "number" }, "minItems": 128, "maxItems": 128 },
 *         "umbral_distancia": { "type": "number", "nullable": true }
 *       }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Resultado de identificación", "dataSchema": { "type": "object", "properties": { "match": { "type": "boolean" }, "persona": { "type": "object", "nullable": true } } } }
 *   }
 * }
 */
require_once dirname(__DIR__, 2) . '/prepare.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session_or_device.php';
require_once dirname(__DIR__, 4) . '/services/porteria/biometria_photo_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

porteriaRequireSessionOrDevice();

$json = PorteriaRouterPayload::readJsonBody();
$embedding = $json['embedding'] ?? null;
$umbral = isset($json['umbral_distancia'])
    ? (float) $json['umbral_distancia']
    : BIOMETRIA_UMBRAL_DISTANCIA_DEFAULT;

if (!is_array($embedding)) {
    RouterResponse::fail('El vector facial (embedding) es obligatorio.');
}

try {
    global $pdo, $stmt_fun_identificar_persona_por_rostro, $stmt_buscar_persona_doc;

    $idPersona = biometriaIdentificarPersona(
        $stmt_fun_identificar_persona_por_rostro,
        $embedding,
        $umbral
    );

    if ($idPersona === null) {
        RouterResponse::ok(['match' => false, 'persona' => null, 'foto_base64' => null]);
        return;
    }

    $stmt_buscar_persona_doc->execute([(string) $idPersona, 'CC']);
    $persona = $stmt_buscar_persona_doc->fetch();

    // Obtener ruta de foto del enrolamiento (2026-07-09)
    $fotoBase64 = null;
    if ($persona !== false) {
        $stmt = $pdo->prepare(
            'SELECT ruta_foto_enrolamiento FROM tab_enrolamiento_facial
             WHERE id_persona = ?::NUMERIC
             ORDER BY fec_insert DESC LIMIT 1'
        );
        $stmt->execute([(string) $idPersona]);
        $enrolamiento = $stmt->fetch();

        if ($enrolamiento && !empty($enrolamiento['ruta_foto_enrolamiento'])) {
            $fotoBase64 = BiometriaPhotoService::leerFoto($enrolamiento['ruta_foto_enrolamiento']);
        }
    }

    RouterResponse::ok([
        'match' => $persona !== false,
        'persona' => $persona !== false ? PorteriaRouterPayload::formatPersona($persona) : null,
        'foto_base64' => $fotoBase64,
    ]);
} catch (InvalidArgumentException $e) {
    RouterResponse::fail($e->getMessage());
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
