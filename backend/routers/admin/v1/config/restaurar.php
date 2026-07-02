<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Restaurar sección de configuración",
 *   "tags": ["Admin"],
 *   "requestBody": {
 *     "required": ["section"],
 *     "properties": {
 *       "section": { "type": "string", "description": "general | theme_dark | theme_light" }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Sección restaurada", "dataSchema": { "$ref": "#/components/schemas/MessageData" } }
 *   }
 * }
 */
require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 4) . '/core/ConfigSistemaDefaults.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session.php';
require_once dirname(__DIR__, 4) . '/middleware/require_admin.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

if (!$stmt_get_config instanceof PDOStatement) {
    RouterResponse::fail('Ejecute database/migrations/run_config_sistema.sh antes de restaurar.');
}

$raw = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : $_POST;
if (!is_array($json)) {
    $json = $_POST;
}

$section = (string) ($json['section'] ?? $json['btn_restaurar_seccion'] ?? '');
$allowed = array_keys(ConfigSistemaDefaults::sectionKeys());

if (!in_array($section, $allowed, true)) {
    RouterResponse::fail('Sección de restauración no válida.');
}

try {
    global $stmt_get_config, $stmt_fun_upd_config;

    $stmt_get_config->execute();
    $config = $stmt_get_config->fetch(PDO::FETCH_ASSOC) ?: [];

    $merged = ConfigSistemaDefaults::applySection($config, $section);
    $passHash = null;
    if ($section === ConfigSistemaDefaults::SECTION_GENERAL) {
        $passHash = password_hash('usuariocset', PASSWORD_BCRYPT);
    }

    $stmt_fun_upd_config->execute(
        ConfigSistemaDefaults::toUpdateParamsFromRow($merged, $passHash)
    );
    $res = (string) $stmt_fun_upd_config->fetchColumn();
    if (strpos($res, 'OK') === false) {
        RouterResponse::fail('Error: ' . $res);
    }

    AppConfig::reset();
    AppConfig::boot($pdo);

    RouterResponse::ok([
        'message' => 'Se restauró la ' . ConfigSistemaDefaults::sectionLabel($section) . '.',
    ]);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
