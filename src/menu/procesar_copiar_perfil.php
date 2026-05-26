<?php
/**
 * PROCESADOR: Copia el perfil de menús de un usuario a otro.
 * Recibe usuario_origen y usuario_destino y replica los menús.
 */
require_once(__DIR__ . '/../core/prepare.php');
require_once(__DIR__ . '/../core/helpers.php');
require_once(__DIR__ . '/../core/ErrorHandler.php');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $usuarioOrigen = $_POST['usuario_origen'] ?? null;
        $usuarioDestino = $_POST['usuario_destino'] ?? null;

        ErrorHandler::validateNotEmpty($usuarioOrigen, 'Usuario origen');
        ErrorHandler::validateNotEmpty($usuarioDestino, 'Usuario destino');

        if (usuarioEsAdministrador($pdo, $usuarioOrigen) || usuarioEsAdministrador($pdo, $usuarioDestino)) {
            throw new Exception('No se permite copiar el perfil de un usuario administrador.');
        }

        if ($usuarioOrigen === $usuarioDestino) {
            throw new Exception('El usuario origen y el usuario destino no pueden ser el mismo.');
        }

        // Iniciar transacción
        $pdo->beginTransaction();

        // 1) Limpiar perfil existente del destino
        $stmt_del_perfil->execute([$usuarioDestino]);

        // 2) Obtener menús del usuario origen
        $sql_menus_origen = "SELECT id_menu FROM tab_menu_usuarios WHERE id_usuario = ? ORDER BY id_menu";
        $stmt_menus_origen = $pdo->prepare($sql_menus_origen);
        $stmt_menus_origen->execute([$usuarioOrigen]);
        $menusOrigen = $stmt_menus_origen->fetchAll(PDO::FETCH_COLUMN);

        // 3) Insertar los menús en el destino
        $copiados = 0;
        foreach ($menusOrigen as $idMenu) {
            if (!empty($idMenu)) {
                $stmt_ins_perfil->execute([$usuarioDestino, $idMenu]);
                $copiados++;
            }
        }

        $pdo->commit();

        $msg = $copiados === 1
            ? "Se copió 1 menú de $usuarioOrigen a $usuarioDestino"
            : "Se copiaron $copiados menús de $usuarioOrigen a $usuarioDestino";

        $response = ErrorHandler::createResponse(
            'success',
            $msg,
            'DATABASE'
        );
        $response['copiados'] = $copiados;

        echo json_encode($response, JSON_UNESCAPED_UNICODE);

    } catch (PDOException $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        ErrorHandler::sendJSON(
            ErrorHandler::handleDatabaseException($e)
        );
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
