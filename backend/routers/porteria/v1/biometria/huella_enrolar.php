<?php

declare(strict_types=1);

/**
 * Enrolar huella para persona ya registrada.
 * Body JSON: { documento, huella_template_b64, calidad_huella? }
 */
require_once dirname(__DIR__, 2) . '/prepare.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session_or_device.php';
require_once dirname(__DIR__, 4) . '/services/porteria/biometria_huella_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$auth = porteriaRequireSessionOrDevice();
$usrAudit = porteriaAuthAuditUser($auth);

$json = PorteriaRouterPayload::readJsonBody();
$documento = trim((string) ($json['documento'] ?? ''));
$templateB64 = trim((string) ($json['huella_template_b64'] ?? ''));
$calidad = isset($json['calidad_huella']) ? (float) $json['calidad_huella'] : null;

if ($documento === '') {
    RouterResponse::fail('El documento es obligatorio.');
}
if ($templateB64 === '') {
    RouterResponse::fail('La plantilla de huella (huella_template_b64) es obligatoria.');
}

try {
    global $pdo, $stmt_buscar_persona_doc, $stmt_fun_guardar_enrolamiento_huella;

    $stmt_buscar_persona_doc->execute([$documento, 'CC']);
    $persona = $stmt_buscar_persona_doc->fetch();
    if (!$persona) {
        RouterResponse::fail('La persona no está registrada — no se puede enrolar la huella.', 404);
    }

    $raw = biometriaHuellaDesdeBase64($templateB64);

    $pdo->exec('SET app.usuario = ' . $pdo->quote($usrAudit));

    $idPersona = biometriaHuellaGuardarEnrolamiento(
        $stmt_fun_guardar_enrolamiento_huella,
        (int) $persona['id_persona'],
        $raw,
        $calidad
    );

    RouterResponse::ok(['id_persona' => $idPersona]);
} catch (InvalidArgumentException $e) {
    RouterResponse::fail($e->getMessage());
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
