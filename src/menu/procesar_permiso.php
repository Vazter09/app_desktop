<?php
require_once(__DIR__ . '/../core/prepare.php');
require_once(__DIR__ . '/../core/ErrorHandler.php');
header('Content-Type: application/json');

function obtenerAncestros($pdo, $id_menu, &$ancestros = []) {
    $stmt = $pdo->prepare("SELECT ind_id_padre FROM tab_menus WHERE id_menu = ?");
    $stmt->execute([$id_menu]);
    $padre = $stmt->fetchColumn();

    if ($padre && (string) $padre !== '0') {
        $ancestros[] = $padre;
        obtenerAncestros($pdo, $padre, $ancestros);
    }
    return $ancestros;
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['id_usuario'])) {
    try {
        $id_user = $_POST['id_usuario'];
        $id_menu = $_POST['id_menu'];
        
        // Validaciones
        ErrorHandler::validateNotEmpty($id_user, 'ID del Usuario');
        ErrorHandler::validateNotEmpty($id_menu, 'ID del Menú');

        // 1. Obtener toda la jerarquía hacia arriba
        $lista_a_insertar = obtenerAncestros($pdo, $id_menu);
        $lista_a_insertar[] = $id_menu; // Incluir el menú seleccionado

        foreach ($lista_a_insertar as $menu_id) {
            // V.1.3: Solo insertamos (id_usuario, id_menu), sin nom_programa
            $sql = "INSERT INTO tab_menu_usuarios (id_usuario, id_menu) 
                    VALUES (?, ?) ON CONFLICT (id_usuario, id_menu) DO NOTHING";
            $pdo->prepare($sql)->execute([$id_user, $menu_id]);
        }
        
        $response = ErrorHandler::createResponse(
            'success',
            'Permiso asignado correctamente',
            'DATABASE'
        );
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        
    } catch (PDOException $e) {
        // Detectar si es error FK
        if ($e->errorInfo[0] === '23503' || stripos($e->getMessage(), 'foreign key') !== false) {
            $response = ErrorHandler::createResponse(
                'error',
                'No se puede asignar permiso. Usuario o menú no existen.',
                'DATABASE',
                '23503'
            );
        } else {
            $response = ErrorHandler::handleDatabaseException($e);
        }
        ErrorHandler::sendJSON($response);
    } catch (Exception $e) {
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