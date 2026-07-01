<?php
declare(strict_types=1);

/**
 * @openapi {
 *   "summary": "Sincronización batch offline (móvil)",
 *   "description": "Máximo 20 operaciones por lote. Requiere token de dispositivo.",
 *   "tags": ["Portería"],
 *   "requestBody": {
 *     "required": ["operaciones"],
 *     "schema": {
 *       "type": "object",
 *       "required": ["operaciones"],
 *       "properties": {
 *         "operaciones": { "type": "array", "maxItems": 20, "items": { "$ref": "#/components/schemas/SyncOperacion" } }
 *       }
 *     }
 *   },
 *   "responses": {
 *     "200": { "description": "Resultados por operación", "dataSchema": { "type": "object", "properties": { "resultados": { "type": "array", "items": { "$ref": "#/components/schemas/SyncResultado" } } } } }
 *   }
 * }
 */
require_once dirname(__DIR__, 2) . '/prepare.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$device = porteriaApiRequireDevice();
$json = PorteriaRouterPayload::readJsonBody();
$operaciones = $json['operaciones'] ?? [];

if (!is_array($operaciones)) {
    RouterResponse::fail('operaciones debe ser un arreglo.');
}
if (count($operaciones) < 1) {
    RouterResponse::fail('No hay operaciones para sincronizar.');
}
if (count($operaciones) > 20) {
    RouterResponse::fail('Máximo 20 operaciones por lote.');
}

$resultados = [];

foreach ($operaciones as $idx => $op) {
    if (!is_array($op)) {
        $resultados[] = [
            'client_id' => null,
            'ok' => false,
            'error' => 'Operación inválida en índice ' . $idx,
        ];
        continue;
    }

    $clientId = trim((string) ($op['client_id'] ?? ''));
    $tipo = trim((string) ($op['tipo'] ?? ''));
    $payload = $op['payload'] ?? [];

    if ($clientId === '' || !PorteriaRouterSync::isValidUuid($clientId)) {
        $resultados[] = [
            'client_id' => $clientId !== '' ? $clientId : null,
            'ok' => false,
            'error' => 'client_id inválido.',
        ];
        continue;
    }
    if (!in_array($tipo, ['ingreso', 'salida'], true)) {
        $resultados[] = [
            'client_id' => $clientId,
            'ok' => false,
            'error' => 'tipo debe ser ingreso o salida.',
        ];
        continue;
    }
    if (!is_array($payload)) {
        $resultados[] = [
            'client_id' => $clientId,
            'ok' => false,
            'error' => 'payload inválido.',
        ];
        continue;
    }

    $payload['client_id'] = $clientId;

    try {
        if ($tipo === 'ingreso') {
            $res = porteriaApiRegistrarIngreso($device, $payload);
        } else {
            $res = porteriaApiRegistrarSalida($device, $payload);
        }
        $resultados[] = [
            'client_id' => $clientId,
            'ok' => true,
            'id_ingreso' => $res['id_ingreso'],
            'tipo' => $tipo,
        ];
    } catch (Throwable $e) {
        $resultados[] = [
            'client_id' => $clientId,
            'ok' => false,
            'error' => ErrorHandler::userMessageFromException($e),
            'tipo' => $tipo,
        ];
    }
}

RouterResponse::ok(['resultados' => $resultados]);
