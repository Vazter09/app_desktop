<?php
/**
 * GESTIÓN CENTRALIZADA DE ERRORES
 * Traduce errores de BD y otros hacia mensajes amigables para el usuario
 * Categoriza origen: Base de Datos | Validación | Sistema | Red
 */

class ErrorHandler {
    
    /**
     * Mapa de códigos SQLSTATE a mensajes en español
     * Ver: https://www.postgresql.org/docs/current/errcodes-appendix.html
     */
    private static $sqlErrorMap = [
        // Errores de restricción
        '23505' => 'Violación de clave única. Este registro ya existe en la base de datos.',
        '23503' => 'Error de integridad referencial. Este dato está relacionado con otros registros y no puede ser eliminado.',
        '23502' => 'Violación de restricción NOT NULL. Un campo requerido está vacío.',
        '23514' => 'Violación de restricción CHECK. Los datos no cumplen con las reglas de validación.',
        
        // Errores de sintaxis
        '42601' => 'Error de sintaxis SQL. Contacte al administrador.',
        '42883' => 'Función o procedimiento no encontrado.',
        '42P01' => 'Tabla no encontrada en la base de datos.',
        '42P02' => 'Columna no encontrada en la tabla.',
        
        // Errores de permisos
        '42501' => 'Permisos insuficientes para ejecutar esta operación.',
        '28P01' => 'Contraseña incorrecta o usuario no existen.',
        
        // Errores de conexión
        '08000' => 'Error de conexión a base de datos.',
        '08003' => 'Conexión perdida con la base de datos.',
        '08006' => 'Fallo de comunicación con la base de datos.',
        
        // Errores de transacción
        '40P01' => 'Deadlock detectado. Reintente la operación.',
        '40000' => 'Error de transacción. La operación fue cancelada.',
        
        // Errores de tipo de dato
        '22007' => 'Formato de fecha/hora inválido.',
        '22P02' => 'Formato de valor inválido para el tipo de dato.',
        '22012' => 'División por cero.',
    ];

    /**
     * Estructura de respuesta unificada
     * @return array
     */
    public static function createResponse($status, $message, $source = 'UNKNOWN', $sqlstate = null, $debug = null) {
        return [
            'status' => $status,
            'message' => $message,
            'source' => $source,  // DATABASE, VALIDATION, SYSTEM, NETWORK
            'sqlstate' => $sqlstate,
            'timestamp' => date('Y-m-d H:i:s'),
            'debug' => $debug  // Solo se incluye en desarrollo si se habilita
        ];
    }

    /**
     * Mensaje seguro para mostrar al usuario (sin detalles de PostgreSQL).
     */
    public static function userMessageFromException(Throwable $e): string
    {
        if ($e instanceof PDOException) {
            return self::userMessageFromPdo($e);
        }

        $msg = self::extractPostgresBusinessMessage($e->getMessage());
        if ($msg !== '' && !self::looksTechnical($msg)) {
            return $msg;
        }

        return 'No se pudo completar la operación. Intente de nuevo.';
    }

    /**
     * @param PDOException $e
     */
    public static function userMessageFromPdo(PDOException $e): string
    {
        $errorInfo = $e->errorInfo;
        $sqlstate = $errorInfo[0] ?? null;
        $nativeMessage = (string) ($errorInfo[2] ?? $e->getMessage());

        self::logError('DATABASE_ERROR', (string) $sqlstate, $nativeMessage . ' | ' . $e->getMessage());

        $business = self::extractPostgresBusinessMessage($nativeMessage);
        if ($business === '' || self::looksTechnical($business)) {
            $business = self::extractPostgresBusinessMessage($e->getMessage());
        }
        if ($business !== '' && !self::looksTechnical($business)) {
            return $business;
        }

        if ($sqlstate && isset(self::$sqlErrorMap[$sqlstate])) {
            return self::$sqlErrorMap[$sqlstate];
        }

        return self::getGenericDatabaseMessage($sqlstate);
    }

    /**
     * Extrae el texto de negocio de un error PostgreSQL (RAISE, cadenas fun_*).
     */
    private static function extractPostgresBusinessMessage(string $raw): string
    {
        if ($raw === '') {
            return '';
        }

        $msg = preg_split('/\b(CONTEXT|CONTEXTO)\b/i', $raw, 2)[0];
        $msg = preg_replace('/^SQLSTATE\[[^\]]+\]:\s*/i', '', $msg);
        $msg = preg_replace('/^(?:Raise exception|ERROR)(?::\s*\d+)?\s*(?:ERROR:\s*)?/i', '', $msg);

        do {
            $prev = $msg;
            $msg = preg_replace('/^fun_[a-z0-9_]+:\s*/i', '', $msg);
            $msg = preg_replace('/\s+fun_[a-z0-9_]+:\s*/i', ' ', $msg);
        } while ($msg !== $prev);

        $msg = preg_replace('/\s*PL\/pgSQL.*$/is', '', $msg);
        $msg = preg_replace('/\s*(?:en la línea|line)\s+\d+.*$/iu', '', $msg);
        $msg = preg_replace('/\s*función\s+PL\/pgSQL.*$/iu', '', $msg);
        $msg = preg_replace('/^ERROR:\s*/i', '', $msg);

        $msg = trim(preg_replace('/\s{2,}/', ' ', $msg) ?? '');
        $msg = preg_replace('/^:\s*/', '', $msg) ?? '';

        return trim($msg);
    }

    private static function looksTechnical(string $msg): bool
    {
        if ($msg === '') {
            return true;
        }

        return (bool) preg_match(
            '/sqlstate|(?:^|\s)(?:tab_|seq_)|\b(?:INSERT|UPDATE|DELETE|SELECT)\s+INTO\b|'
            . 'PL\/pgSQL|pg_catalog|syntax error|undefined function|42883|42P01|42P02|'
            . 'deadlock|connection|fatal:|duplicate key value/i',
            $msg
        );
    }

    /**
     * Procesa excepciones de PDO (errores de base de datos)
     * @param PDOException $e
     * @return array
     */
    public static function handleDatabaseException(PDOException $e) {
        $errorInfo = $e->errorInfo;
        $sqlstate = $errorInfo[0] ?? null;
        $nativeCode = $errorInfo[1] ?? null;
        $nativeMessage = $errorInfo[2] ?? null;

        $userMessage = self::userMessageFromPdo($e);

        $debugInfo = [
            'sqlstate' => $sqlstate,
            'native_code' => $nativeCode,
            'native_message' => $nativeMessage,
            'exception_msg' => $e->getMessage()
        ];

        return self::createResponse(
            'error',
            $userMessage,
            'DATABASE',
            $sqlstate,
            $debugInfo
        );
    }

    /**
     * Procesa excepciones generales (validación, lógica)
     * @param Exception $e
     * @return array
     */
    public static function handleValidationException(Exception $e) {
        $userMessage = self::userMessageFromException($e);

        $debugInfo = [
            'exception_msg' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ];

        self::logError('VALIDATION_ERROR', 'N/A', $e->getMessage());

        return self::createResponse(
            'error',
            $userMessage,
            'VALIDATION',
            null,
            $debugInfo
        );
    }

    /**
     * Construye mensaje genérico para errores de BD sin traducción
     * @return string
     */
    private static function getGenericDatabaseMessage($sqlstate) {
        if (!$sqlstate) {
            return 'No se pudo completar la operación. Intente de nuevo o contacte al administrador.';
        }

        $prefix = substr($sqlstate, 0, 2);
        switch ($prefix) {
            case '08': return 'No hay conexión con el sistema. Verifique la red o intente más tarde.';
            case '23': return 'Los datos no cumplen las reglas del sistema. Revise la información e intente de nuevo.';
            case '42': return 'No se pudo completar la operación. Contacte al administrador.';
            case '40': return 'La operación no se completó. Intente de nuevo en unos segundos.';
            case '22': return 'Algún dato tiene un formato no válido. Revise e intente de nuevo.';
            default:  return 'No se pudo completar la operación. Contacte al administrador si el problema continúa.';
        }
    }

    /**
     * Valida que un ID no esté vacío
     * @param mixed $id
     * @param string $fieldName
     * @throws Exception
     */
    public static function validateNotEmpty($id, $fieldName = 'Campo') {
        if (empty($id)) {
            throw new Exception("$fieldName es requerido y no puede estar vacío.");
        }
    }

    /**
     * Valida que un array tenga elementos
     * @param array $arr
     * @param string $fieldName
     * @throws Exception
     */
    public static function validateArray($arr, $fieldName = 'Lista') {
        if (!is_array($arr) || empty($arr)) {
            throw new Exception("$fieldName no puede estar vacía.");
        }
    }

    /**
     * Registra errores en archivo de log
     * @param string $errorType
     * @param string $code
     * @param string $message
     */
    private static function logError($errorType, $code, $message) {
        $logFile = __DIR__ . '/../logs/error_handler.log';
        
        // Crear directorio si no existe
        if (!is_dir(dirname($logFile))) {
            mkdir(dirname($logFile), 0755, true);
        }

        $logEntry = sprintf(
            "[%s] %s | Code: %s | Message: %s | IP: %s\n",
            date('Y-m-d H:i:s'),
            $errorType,
            $code,
            $message,
            $_SERVER['REMOTE_ADDR'] ?? 'UNKNOWN'
        );

        file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
    }

    /**
     * Envía respuesta JSON y termina ejecución
     * @param array $response
     */
    public static function sendJSON($response) {
        header('Content-Type: application/json; charset=utf-8');
        http_response_code($response['status'] === 'error' ? 400 : 200);
        echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit;
    }

    /**
     * Retorna mensaje legible para usuario final en alertas
     * @param array $errorResponse
     * @return string
     */
    public static function getUserMessage($errorResponse) {
        $message = trim((string) ($errorResponse['message'] ?? ''));
        return $message !== '' ? $message : 'No se pudo completar la operación.';
    }

    /**
     * Procesa errores de clave foránea con contexto mejorado
     * Detecta la tabla y proporciona mensaje específico
     * @param PDOException $e
     * @param string $operation 'DELETE'|'INSERT'|'UPDATE'
     * @param array $context Información contextual como tabla afectada
     * @return array
     */
    public static function handleForeignKeyViolation(PDOException $e, $operation = 'DELETE', $context = []) {
        $errorInfo = $e->errorInfo;
        $sqlstate = $errorInfo[0] ?? null;
        $nativeMessage = $errorInfo[2] ?? '';
        
        // Mensajes contextualizados según tabla y operación
        if ($operation === 'DELETE') {
            if (strpos($nativeMessage, 'tab_menu_usuarios') !== false) {
                $userMessage = "❌ No se puede eliminar este menú.\n\n" .
                    "Motivo: Está asignado a usuarios.\n\n" .
                    "Acción: Primero debe desasignarlo a todos los usuarios " .
                    "en la sección 'Gestión de Accesos de Usuarios'.";
            } elseif (strpos($nativeMessage, 'tab_usuarios') !== false) {
                $userMessage = "❌ No se puede eliminar este usuario.\n\n" .
                    "Motivo: Tiene registros relacionados en el sistema.\n\n" .
                    "Acción: Primero debe resolver estas relaciones.";
            } elseif (strpos($nativeMessage, 'tab_menus') !== false) {
                $userMessage = "❌ No se puede eliminar este registro.\n\n" .
                    "Motivo: Está relacionado con menús del sistema.\n\n" .
                    "Acción: Verifique las dependencias antes de eliminar.";
            } else {
                // Mensaje genérico para otros casos
                $userMessage = "❌ No se puede eliminar este registro.\n\n" .
                    "Motivo: Está relacionado con otros datos en el sistema.\n\n" .
                    "Acción: Primero debe eliminar o modificar esos datos dependientes.";
            }
        } elseif ($operation === 'INSERT' || $operation === 'UPDATE') {
            $userMessage = "❌ No se puede guardar. Referencia inválida.\n\n" .
                "Motivo: Uno de los datos referenciados no existe en el sistema.\n\n" .
                "Acción: Verifique que todos los IDs referenciados existan.";
        } else {
            $userMessage = "Error de integridad referencial. Contacte al administrador.";
        }

        $debugInfo = [
            'sqlstate' => $sqlstate,
            'operation' => $operation,
            'native_message' => $nativeMessage,
            'context' => $context
        ];

        self::logError('REFERENTIAL_INTEGRITY_ERROR', $sqlstate, $nativeMessage);

        return self::createResponse(
            'error',
            $userMessage,
            'DATABASE',
            $sqlstate,
            $debugInfo
        );
    }
}
?>