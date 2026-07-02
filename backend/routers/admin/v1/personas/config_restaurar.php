<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Restaurar configuración del módulo registro/personas",
 *   "tags": ["Admin"],
 *   "responses": {
 *     "200": { "description": "Valores por defecto restaurados", "dataSchema": { "$ref": "#/components/schemas/MessageData" } }
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

try {
    global $stmt_get_config, $stmt_fun_upd_config;

    $stmt_get_config->execute();
    $row = $stmt_get_config->fetch(PDO::FETCH_ASSOC) ?: [];
    $defaults = ConfigSistemaDefaults::values();

    $row['ind_modulo_registro'] = $defaults['ind_modulo_registro'] ?? true;
    $row['ind_login_registro_standalone'] = $defaults['ind_modulo_registro'] ?? true;
    $row['usr_registro'] = (string) ($defaults['usr_registro'] ?? 'usuariocset');

    $passHash = password_hash('usuariocset', PASSWORD_BCRYPT);
    $stmt_fun_upd_config->execute(
        ConfigSistemaDefaults::toUpdateParamsFromRow($row, (string) $_SESSION['id_usuario'], $passHash)
    );
    $res = (string) $stmt_fun_upd_config->fetchColumn();
    if (strpos($res, 'OK') === false) {
        RouterResponse::fail('Error: ' . $res);
    }

    AppConfig::reset();
    AppConfig::boot($pdo);

    RouterResponse::ok(['message' => 'Se restauró la configuración del módulo de personas.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
