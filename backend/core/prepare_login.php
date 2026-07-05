<?php
/**
 * Bootstrap mínimo para index.php (login público).
 * Solo conexión + AppConfig + statements de autenticación/sesión.
 */
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/SecurityMiddleware.php';
require_once __DIR__ . '/Db.php';
require_once __DIR__ . '/AppConfig.php';
require_once __DIR__ . '/PrepareAuthSql.php';
require_once __DIR__ . '/lib/acceso_sesion.php';
require_once __DIR__ . '/helpers.php';

try {
    $pdo = Db::connect();

    // Login público: tema/branding sin cargar pass_registro_hash.
    AppConfig::boot($pdo, false);

    $stmt_login = $pdo->prepare(PrepareAuthSql::LOGIN);
    $stmt_fun_ingreso_sesion = $pdo->prepare(PrepareAuthSql::INGRESO_SESION);

    // E3 — Rate limiting: verificar bloqueo y registrar intentos
    $stmt_verificar_bloqueo = $pdo->prepare(
        'SELECT fun_verificar_bloqueo_ip(?::VARCHAR, ?::INTEGER, ?::INTEGER)'
    );
    $stmt_registrar_intento = $pdo->prepare(
        'SELECT fun_registrar_intento_login(?::VARCHAR, ?::VARCHAR, ?::BOOLEAN)'
    );
} catch (PDOException $e) {
    die('Error crítico en prepare_login.php: ' . $e->getMessage());
}
