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
    global $pdo, $stmt_fun_identificar_persona_por_rostro, $stmt_biometria_persona_completa;

    $idPersona = biometriaIdentificarPersona(
        $stmt_fun_identificar_persona_por_rostro,
        $embedding,
        $umbral
    );

    if ($idPersona === null) {
        RouterResponse::ok(['match' => false, 'persona' => null, 'foto_base64' => null]);
        return;
    }

    $stmt_biometria_persona_completa->execute([(string) $idPersona]);
    $persona = $stmt_biometria_persona_completa->fetch();

    // Foto de enrolamiento: tab_personas.ruta_foto_facial (+ fallback carpeta).
    $fotoBase64 = null;
    $idPersonaInt = (int) $idPersona;
    $ruta = ($persona !== false) ? (string) ($persona['ruta_foto_facial'] ?? '') : '';
    if ($persona !== false) {
        $fotoBase64 = BiometriaPhotoService::resolverFotoBase64($ruta, $idPersonaInt);
    }

    RouterResponse::ok([
        'match' => $persona !== false,
        'persona' => $persona !== false ? PorteriaRouterPayload::formatPersonaCompleta($persona) : null,
        'foto_base64' => $fotoBase64,
        'foto_disponible' => $fotoBase64 !== null,
    ]);
} catch (InvalidArgumentException $e) {
    RouterResponse::fail($e->getMessage());
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
