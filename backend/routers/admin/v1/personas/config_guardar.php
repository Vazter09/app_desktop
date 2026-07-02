<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Guardar configuración del módulo registro/personas",
 *   "tags": ["Admin"],
 *   "requestBody": {
 *     "contentType": "application/x-www-form-urlencoded",
 *     "properties": {
 *       "chk_modulo_registro": { "type": "boolean" },
 *       "txt_usr_registro": { "type": "string" },
 *       "txt_pass_registro": { "type": "string" }
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
    $row = $stmt_get_config->fetch(PDO::FETCH_ASSOC) ?: [];

    $indModulo = isset($_POST['chk_modulo_registro']);
    $row['ind_modulo_registro'] = $indModulo;
    $row['ind_login_registro_standalone'] = $indModulo;
    $row['usr_registro'] = trim((string) ($_POST['txt_usr_registro'] ?? ''));

    $passHash = null;
    $nuevaClave = trim((string) ($_POST['txt_pass_registro'] ?? ''));
    if ($nuevaClave !== '') {
        validarLongitudPassword($nuevaClave, true);
        $passHash = password_hash($nuevaClave, PASSWORD_BCRYPT);
    }

    $stmt_fun_upd_config->execute(
        ConfigSistemaDefaults::toUpdateParamsFromRow($row, (string) $_SESSION['id_usuario'], $passHash)
    );
    $res = (string) $stmt_fun_upd_config->fetchColumn();
    if (strpos($res, 'OK') === false) {
        RouterResponse::fail('Error: ' . $res);
    }

    AppConfig::reset();
    AppConfig::boot($pdo);

    RouterResponse::ok(['message' => 'Configuración del módulo guardada correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
