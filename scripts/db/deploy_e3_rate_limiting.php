<?php
/**
 * Despliega E3 (rate limiting login) en la BD configurada en .env.
 * Uso (desde la raíz del repo, en la máquina con acceso a la BD):
 *   php scripts/db/deploy_e3_rate_limiting.php
 *
 * MSPI Eje 3 / Fase 1 E3 — no imprime credenciales.
 */
declare(strict_types=1);

$root = dirname(__DIR__, 2);
require $root . '/backend/core/config.php';

$files = [
    $root . '/database/migrations/add_tab_intentos_login.sql',
    $root . '/database/functions/acceso/usuarios/fun_registrar_intento_login.sql',
    $root . '/database/functions/acceso/usuarios/fun_verificar_bloqueo_ip.sql',
];

foreach ($files as $f) {
    if (!is_readable($f)) {
        fwrite(STDERR, "No se puede leer: {$f}\n");
        exit(1);
    }
}

$dsn = sprintf('pgsql:host=%s;port=%s;dbname=%s', DB_HOST, DB_PORT, DB_NAME);
if (defined('DB_SSLMODE') && DB_SSLMODE !== '') {
    $dsn .= ';sslmode=' . DB_SSLMODE;
}

try {
    $pdo = new PDO($dsn, DB_USER, DB_PASS, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
} catch (PDOException $e) {
    fwrite(STDERR, "Conexión fallida (host=" . DB_HOST . " db=" . DB_NAME . "): " . $e->getMessage() . "\n");
    exit(1);
}

foreach ($files as $f) {
    $sql = file_get_contents($f);
    if ($sql === false || trim($sql) === '') {
        fwrite(STDERR, "SQL vacío: {$f}\n");
        exit(1);
    }
    $pdo->exec($sql);
    echo 'OK ' . basename($f) . PHP_EOL;
}

$funcs = $pdo->query(
    "SELECT oid::regprocedure::text
     FROM pg_proc
     WHERE proname IN ('fun_verificar_bloqueo_ip', 'fun_registrar_intento_login')
     ORDER BY 1"
)->fetchAll(PDO::FETCH_COLUMN);

$tabla = $pdo->query("SELECT to_regclass('public.tab_intentos_login')")->fetchColumn();

echo 'tabla=' . ($tabla ?: '(null)') . PHP_EOL;
echo 'funcs=' . ($funcs ? implode(' | ', $funcs) : '(ninguna)') . PHP_EOL;
echo "Despliegue E3 completado.\n";
