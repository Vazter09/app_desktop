<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Guardar parámetros generales del centro",
 *   "tags": ["Admin"],
 *   "requestBody": {
 *     "contentType": "application/x-www-form-urlencoded",
 *     "properties": {
 *       "txt_id_centro": { "type": "integer" },
 *       "txt_dir_centro": { "type": "string" },
 *       "txt_tel_centro": { "type": "integer" },
 *       "num_ano_academico": { "type": "integer" },
 *       "num_mes_academico": { "type": "integer" },
 *       "num_nota_minima_rap": { "type": "integer" },
 *       "num_horas_instructor": { "type": "integer" },
 *       "num_porcent_icfes_raps": { "type": "integer" },
 *       "num_tiempo_gracia_aprendiz": { "type": "integer" },
 *       "num_tiempo_gracia_instru": { "type": "integer" },
 *       "num_max_llamados_aprendiz": { "type": "integer" },
 *       "txt_nom_administrador": { "type": "string" },
 *       "txt_tel_administrador": { "type": "integer" }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Parámetros guardados", "dataSchema": { "$ref": "#/components/schemas/MessageData" } }
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

    $row = PmtrosGralesDefaults::rowFromPost($_POST, $current);

    $stmt_fun_upd_pmtros->execute(
        PmtrosGralesDefaults::toUpdateParamsFromRow($row, (string) $_SESSION['id_usuario'])
    );
    $res = (string) $stmt_fun_upd_pmtros->fetchColumn();
    if (strpos($res, 'OK') === false) {
        RouterResponse::fail('Error: ' . $res);
    }

    RouterResponse::ok(['message' => 'Parámetros generales guardados correctamente.']);
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
