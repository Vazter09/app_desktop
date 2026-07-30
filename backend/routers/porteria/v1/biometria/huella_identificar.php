<?php

declare(strict_types=1);

/**
 * Identificar persona por plantilla de huella (no registra ingreso/salida).
 * Body JSON: { huella_template_b64 }
 */
require_once dirname(__DIR__, 2) . '/prepare.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session_or_device.php';
require_once dirname(__DIR__, 4) . '/services/porteria/biometria_huella_service.php';
require_once dirname(__DIR__, 4) . '/services/porteria/biometria_photo_service.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$auth = porteriaRequireSessionOrDevice();
$usrAudit = porteriaAuthAuditUser($auth);

$json = PorteriaRouterPayload::readJsonBody();
$templateB64 = trim((string) ($json['huella_template_b64'] ?? ''));

if ($templateB64 === '') {
    RouterResponse::fail('La plantilla de huella (huella_template_b64) es obligatoria.');
}

try {
    global $pdo, $stmt_fun_identificar_persona_por_huella, $stmt_biometria_persona_completa;

    $raw = biometriaHuellaDesdeBase64($templateB64);

    $pdo->exec('SET app.usuario = ' . $pdo->quote($usrAudit));

    $idPersona = biometriaHuellaIdentificarPersona(
        $stmt_fun_identificar_persona_por_huella,
        $raw
    );

    if ($idPersona === null) {
        RouterResponse::ok(['match' => false, 'persona' => null, 'foto_base64' => null]);
        return;
    }

    $stmt_biometria_persona_completa->execute([(string) $idPersona]);
    $persona = $stmt_biometria_persona_completa->fetch();

    $fotoBase64 = null;
    if ($persona !== false) {
        $ruta = (string) ($persona['ruta_foto_facial'] ?? '');
        $fotoBase64 = BiometriaPhotoService::resolverFotoBase64($ruta, (int) $idPersona);
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
