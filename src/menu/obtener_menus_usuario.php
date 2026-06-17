<?php
/**
 * AJAX: Obtener menús asignados a un usuario
 * Devuelve un JSON con los IDs de menús que ya tiene asignados
 */
require_once(__DIR__ . '/../core/prepare.php');
require_once(__DIR__ . '/../core/helpers.php');
require_once(__DIR__ . '/../core/ErrorHandler.php');
header('Content-Type: application/json');

// A01 (OWASP) — Broken Access Control: consultar menús de otros usuarios exige sesión y privilegio admin del solicitante.
if (!isset($_SESSION['id_usuario']) || !usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])) {
    http_response_code(403);
    echo json_encode(
        ErrorHandler::createResponse('error', 'Acceso denegado. Esta operación requiere privilegios de administrador.', 'VALIDATION'),
        JSON_UNESCAPED_UNICODE
    );
    exit;
}

if ($_SERVER['REQUEST_METHOD'] == 'GET' && isset($_GET['usuario'])) {
    try {
        $id_usuario = $_GET['usuario'];

        // Validar parámetro
        ErrorHandler::validateNotEmpty($id_usuario, 'ID de Usuario');

        if (usuarioEsAdministrador($pdo, $id_usuario)) {
            $stmt_todos = $pdo->query('SELECT id_menu FROM tab_menus ORDER BY id_menu');
            $menusAsignados = $stmt_todos->fetchAll(PDO::FETCH_COLUMN);
        } else {
            $sql_menus_usuario = 'SELECT id_menu FROM tab_menu_usuarios WHERE id_usuario = ? ORDER BY id_menu';
            $stmt_menus_usuario = $pdo->prepare($sql_menus_usuario);
            $stmt_menus_usuario->execute([$id_usuario]);
            $menusAsignados = $stmt_menus_usuario->fetchAll(PDO::FETCH_COLUMN);
        }

        // Respuesta exitosa
        $response = ErrorHandler::createResponse(
            'success',
            'Menús cargados correctamente',
            'DATABASE'
        );
        $response['menusAsignados'] = $menusAsignados;
        $response['cantidad'] = count($menusAsignados);
        $response['esAdministrador'] = usuarioEsAdministrador($pdo, $id_usuario);

        echo json_encode($response, JSON_UNESCAPED_UNICODE);

    } catch (PDOException $e) {
        ErrorHandler::sendJSON(
            ErrorHandler::handleDatabaseException($e)
        );
    } catch (Exception $e) {
        ErrorHandler::sendJSON(
            ErrorHandler::handleValidationException($e)
        );
    }
} else {
    ErrorHandler::sendJSON(
        ErrorHandler::createResponse(
            'error',
            'Parámetro "usuario" es requerido en la URL.',
            'VALIDATION'
        )
    );
}
?>
