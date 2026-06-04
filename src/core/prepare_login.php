<?php
/**
 * Bootstrap mínimo para index.php (login público).
 * Solo conexión + AppConfig + statements de autenticación/sesión.
 */
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/Db.php';
require_once __DIR__ . '/AppConfig.php';
require_once __DIR__ . '/PrepareAuthSql.php';
require_once __DIR__ . '/lib/acceso_sesion.php';

try {
    $pdo = Db::connect();

    // Login público: tema/branding sin cargar pass_registro_hash.
    AppConfig::boot($pdo, false);

    $stmt_login = $pdo->prepare(PrepareAuthSql::LOGIN);
    $stmt_fun_ingreso_sesion = $pdo->prepare(PrepareAuthSql::INGRESO_SESION);
} catch (PDOException $e) {
    die('Error crítico en prepare_login.php: ' . $e->getMessage());
}
