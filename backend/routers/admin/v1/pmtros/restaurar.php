<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Restaurar parámetros generales del centro a valores por defecto",
 *   "tags": ["Admin"],
 *   "responses": {
 *     "200": { "description": "Valores por defecto restaurados", "dataSchema": { "$ref": "#/components/schemas/MessageData" } }
 *   }
 * }
 */
require_once dirname(__DIR__, 4) . '/core/prepare.php';
require_once dirname(__DIR__, 4) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 4) . '/core/ErrorHandler.php';
require_once dirname(__DIR__, 4) . '/core/PmtrosGralesDefaults.php';
require_once dirname(__DIR__, 4) . '/middleware/require_session.php';
require_once dirname(__DIR__, 4) . '/middleware/require_admin.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

if (!$stmt_get_pmtros instanceof PDOStatement) {
    RouterResponse::fail('La tabla de parámetros generales no está disponible.');
}

try {
    global $stmt_get_pmtros, $stmt_fun_upd_pmtros;

    $stmt_get_pmtros->execute();
    $current = $stmt_get_pmtros->fetch(PDO::FETCH_ASSOC) ?: [];

    if ($current === []) {
        RouterResponse::fail('No hay parámetros generales configurados para este centro.');
    }

    $row = PmtrosGralesDefaults::applyDefaults($current);

    $stmt_fun_upd_pmtros->execute(
        PmtrosGralesDefaults::toUpdateParamsFromRow($row, (string) $_SESSION['id_usuario'])
    );
    $res = (string) $stmt_fun_upd_pmtros->fetchColumn();
    if (strpos($res, 'OK') === false) {
        RouterResponse::fail('Error: ' . $res);
    }

    RouterResponse::ok(['message' => 'Se restauraron los parámetros generales del centro.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
