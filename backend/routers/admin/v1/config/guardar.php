<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Guardar configuración del sistema",
 *   "description": "Acepta multipart/form-data (logo) o campos de formulario.",
 *   "tags": ["Admin"],
 *   "requestBody": {
 *     "contentType": "multipart/form-data",
 *     "properties": {
 *       "txt_nom_sistema": { "type": "string" },
 *       "txt_color_primario": { "type": "string" },
 *       "txt_color_secundario": { "type": "string" },
 *       "chk_modulo_registro": { "type": "boolean" },
 *       "logo_file": { "type": "string", "format": "binary" }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Configuración guardada", "dataSchema": { "$ref": "#/components/schemas/MessageData" } }
 *   }
 * }
 */
require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 4) . '/core/LogoUpload.php';
require_once dirname(__DIR__, 4) . '/core/ConfigSistemaDefaults.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session.php';
require_once dirname(__DIR__, 4) . '/middleware/require_admin.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

if (!$stmt_get_config instanceof PDOStatement) {
    RouterResponse::fail('Ejecute database/migrations/run_config_sistema.sh antes de guardar.');
}

try {
    global $stmt_get_config, $stmt_fun_upd_config;

    $stmt_get_config->execute();
    $config = $stmt_get_config->fetch(PDO::FETCH_ASSOC) ?: [];

    $indModulo = isset($_POST['chk_modulo_registro']);
    $indStandalone = $indModulo;
    $passHash = null;
    $nuevaClave = trim((string) ($_POST['txt_pass_registro'] ?? ''));

    if ($nuevaClave !== '') {
        validarLongitudPassword($nuevaClave, true);
        $passHash = password_hash($nuevaClave, PASSWORD_BCRYPT);
    }

    $pathLogo = trim((string) ($_POST['txt_path_logo'] ?? ($config['path_logo'] ?? 'assets/img/logo-sena.png')));
    $logoError = (int) ($_FILES['logo_file']['error'] ?? UPLOAD_ERR_NO_FILE);
    if ($logoError !== UPLOAD_ERR_NO_FILE) {
        $pathLogo = LogoUpload::store($_FILES['logo_file']);
    }

    $stmt_fun_upd_config->execute([
        $indModulo ? 'true' : 'false',
        $indStandalone ? 'true' : 'false',
        trim((string) ($_POST['txt_nom_sistema'] ?? '')),
        $pathLogo,
        trim((string) ($_POST['txt_color_primario'] ?? '')),
        trim((string) ($_POST['txt_color_secundario'] ?? '')),
        trim((string) ($_POST['txt_theme_bg_deep'] ?? '')),
        trim((string) ($_POST['txt_theme_bg_card'] ?? '')),
        trim((string) ($_POST['txt_theme_bg_panel'] ?? 'rgba(6, 15, 36, 0.85)')),
        trim((string) ($_POST['txt_theme_accent'] ?? '')),
        trim((string) ($_POST['txt_theme_accent_dim'] ?? 'rgba(0, 245, 255, 0.15)')),
        trim((string) ($_POST['txt_theme_blue'] ?? '#4a9eff')),
        trim((string) ($_POST['txt_theme_purple'] ?? '#9b6dff')),
        trim((string) ($_POST['txt_theme_orange'] ?? '#ff7b2e')),
        trim((string) ($_POST['txt_theme_text_primary'] ?? '')),
        trim((string) ($_POST['txt_theme_text_muted'] ?? '')),
        trim((string) ($_POST['txt_theme_border'] ?? 'rgba(0,245,255,0.2)')),
        trim((string) ($_POST['txt_theme_error'] ?? '#ff3c6e')),
        trim((string) ($_POST['txt_theme_success'] ?? '#00e5b0')),
        trim((string) ($_POST['txt_theme_font_display'] ?? 'Orbitron')),
        trim((string) ($_POST['txt_theme_font_body'] ?? 'Rajdhani')),
        trim((string) ($_POST['txt_theme_light_bg_deep'] ?? '')),
        trim((string) ($_POST['txt_theme_light_bg_card'] ?? '#ffffff')),
        trim((string) ($_POST['txt_theme_light_accent'] ?? '')),
        trim((string) ($_POST['txt_theme_light_text_primary'] ?? '')),
        trim((string) ($_POST['txt_theme_light_text_muted'] ?? '')),
        trim((string) ($_POST['txt_usr_registro'] ?? '')),
        $passHash,
    ]);

    $res = (string) $stmt_fun_upd_config->fetchColumn();
    if (strpos($res, 'OK') === false) {
        RouterResponse::fail('Error: ' . $res);
    }

    AppConfig::reset();
    AppConfig::boot($pdo);

    RouterResponse::ok(['message' => 'Configuración guardada correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
