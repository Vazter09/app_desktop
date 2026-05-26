<?php
/**
 * PROCESADOR DE PERFILES DE USUARIO
 * Recibe lista de menús marcados y los graba en tab_menu_usuarios
 * Implementa transacción ACID con rollback en caso de error
 */
require_once(__DIR__ . '/../core/prepare.php');
require_once(__DIR__ . '/../core/helpers.php');
require_once(__DIR__ . '/../core/ErrorHandler.php');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        $id_u = $_POST['hid_usuario'] ?? null;
        $menus = $_POST['chk_menu'] ?? []; // Array de IDs marcados

        // Validaciones previas
        ErrorHandler::validateNotEmpty($id_u, 'ID del Usuario');

        if (usuarioEsAdministrador($pdo, $id_u)) {
            ErrorHandler::sendJSON(
                ErrorHandler::createResponse(
                    'error',
                    'Los usuarios administrador tienen acceso fijo a todo el catálogo. No requiere asignación manual.',
                    'VALIDATION'
                )
            );
        }

        // Nota: Es válido que menus esté vacío (el usuario puede no tener acceso a ningún menú)
        if (!is_array($menus)) {
            $menus = [];
        }

        // Iniciar transacción
        $pdo->beginTransaction();

        try {
            // 1. LIMPIEZA: Eliminar todos los menús actuales del usuario
            $stmt_del_perfil->execute([$id_u]);

            // 2. GRABADO: Insertar solo los menús marcados
            foreach ($menus as $id_m) {
                // Validar que id_m no esté vacío
                if (!empty($id_m)) {
                    $stmt_ins_perfil->execute([$id_u, $id_m]);
                }
            }

            // Si lleamos aquí, confirmar la transacción
            $pdo->commit();

            // Respuesta exitosa
            $cantidadGuardada = count($menus);
            $msg = $cantidadGuardada === 1 
                ? '1 menú asignado correctamente'
                : "$cantidadGuardada menús asignados correctamente";

            $response = ErrorHandler::createResponse(
                'success',
                $msg,
                'DATABASE'
            );
            $response['cantidadGuardada'] = $cantidadGuardada;

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

        } catch (PDOException $pdoEx) {
            $pdo->rollBack();
            throw $pdoEx; // Re-lanzar para que el catch externo la maneje
        }

    } catch (PDOException $e) {
        // Ya está marcado rollback arriba si estaba en transacción
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        
        // Detectar si es error FK y traducir
        if ($e->errorInfo[0] === '23503' || stripos($e->getMessage(), 'foreign key') !== false) {
            $response = ErrorHandler::createResponse(
                'error',
                'No se puede asignar menú. Referencia inválida en el sistema.',
                'DATABASE',
                '23503'
            );
        } else {
            $response = ErrorHandler::handleDatabaseException($e);
        }
        ErrorHandler::sendJSON($response);
    } catch (Exception $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        ErrorHandler::sendJSON(
            ErrorHandler::handleValidationException($e)
        );
    }
} else {
    ErrorHandler::sendJSON(
        ErrorHandler::createResponse(
            'error',
            'Solo se aceptan solicitudes POST.',
            'VALIDATION'
        )
    );
}