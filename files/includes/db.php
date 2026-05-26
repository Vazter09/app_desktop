<?php
/**
 * Conexión a la base de datos PostgreSQL mediante PDO
 * Sistema CSET - Centro de Formación
 */

define('DB_HOST', 'localhost');
define('DB_PORT', '5432');
define('DB_NAME', 'cset_db');
define('DB_USER', 'postgres');
define('DB_PASS', 'tu_password_aqui');
define('DB_SCHEMA', 'public');

function getDBConnection(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = "pgsql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME;
        try {
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_PERSISTENT         => false,
            ]);
            $pdo->exec("SET search_path TO " . DB_SCHEMA);
        } catch (PDOException $e) {
            // En producción, registrar en log en vez de mostrar el error
            error_log("DB Connection Error: " . $e->getMessage());
            die(json_encode(['error' => 'No se pudo conectar a la base de datos.']));
        }
    }
    return $pdo;
}

/**
 * Obtiene todos los tipos de documento
 */
function getTiposDocumento(): array {
    $pdo = getDBConnection();
    $stmt = $pdo->query("SELECT id_tipo_docum, nom_tipo_docum FROM tab_tipos_docum ORDER BY nom_tipo_docum");
    return $stmt->fetchAll();
}

/**
 * Obtiene todos los tipos de persona
 */
function getTiposPersona(): array {
    $pdo = getDBConnection();
    $stmt = $pdo->query("SELECT id_tipo_persona, nom_tipo_persona FROM tab_tipos_persona ORDER BY nom_tipo_persona");
    return $stmt->fetchAll();
}

/**
 * Obtiene niveles de estudio
 */
function getNivelesEstudio(): array {
    $pdo = getDBConnection();
    $stmt = $pdo->query("SELECT id_nivel_estudio, nom_nivel_estudio FROM tab_niveles_estudio ORDER BY nom_nivel_estudio");
    return $stmt->fetchAll();
}

/**
 * Obtiene profesiones
 */
function getProfesiones(): array {
    $pdo = getDBConnection();
    $stmt = $pdo->query("SELECT id_profesion, nom_profesion FROM tab_profesiones ORDER BY nom_profesion");
    return $stmt->fetchAll();
}

/**
 * Obtiene departamentos
 */
function getDepartamentos(): array {
    $pdo = getDBConnection();
    $stmt = $pdo->query("SELECT id_dpto, nom_dpto FROM tab_dptos ORDER BY nom_dpto");
    return $stmt->fetchAll();
}

/**
 * Obtiene ciudades por departamento
 */
function getCiudadesByDpto(string $idDpto): array {
    $pdo = getDBConnection();
    $stmt = $pdo->prepare("SELECT id_ciudad, nom_ciudad FROM tab_ciudades WHERE id_dpto = :id_dpto ORDER BY nom_ciudad");
    $stmt->execute([':id_dpto' => $idDpto]);
    return $stmt->fetchAll();
}

/**
 * Obtiene centros disponibles
 */
function getCentros(): array {
    $pdo = getDBConnection();
    $stmt = $pdo->query("SELECT id_centro, nom_centro FROM tab_centros ORDER BY nom_centro");
    return $stmt->fetchAll();
}

/**
 * Obtiene redes de conocimiento
 */
function getRedes(): array {
    $pdo = getDBConnection();
    $stmt = $pdo->query("SELECT id_red, nom_red FROM tab_redes ORDER BY nom_red");
    return $stmt->fetchAll();
}

/**
 * Obtiene fichas activas
 */
function getFichas(): array {
    $pdo = getDBConnection();
    $stmt = $pdo->query("SELECT id_ficha FROM tab_fichas WHERE ind_abierta = TRUE ORDER BY id_ficha");
    return $stmt->fetchAll();
}
