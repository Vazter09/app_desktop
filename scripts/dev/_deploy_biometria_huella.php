<?php

declare(strict_types=1);

/**
 * Despliega funciones/migración de biometría por huella.
 * Uso: php scripts/dev/_deploy_biometria_huella.php
 */

$root = dirname(__DIR__, 2);
$envPath = $root . DIRECTORY_SEPARATOR . '.env';
$env = [];
foreach (file($envPath, FILE_IGNORE_NEW_LINES) as $line) {
    $line = trim($line);
    if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
        continue;
    }
    [$key, $value] = explode('=', $line, 2);
    $env[trim($key)] = trim($value);
}

$dsn = sprintf(
    'pgsql:host=%s;port=%s;dbname=%s;sslmode=%s',
    $env['DB_HOST'] ?? 'localhost',
    $env['DB_PORT'] ?? '5432',
    $env['DB_NAME'] ?? 'db_smartcset2',
    $env['DB_SSLMODE'] ?? 'require'
);

echo 'Conectando a ' . ($env['DB_HOST'] ?? '') . '/' . ($env['DB_NAME'] ?? '') . PHP_EOL;

try {
    $pdo = new PDO($dsn, $env['DB_USER'] ?? 'postgres', $env['DB_PASS'] ?? '', [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
} catch (Throwable $e) {
    fwrite(STDERR, 'FAIL conexión: ' . $e->getMessage() . PHP_EOL);
    exit(1);
}

echo 'OK conexión' . PHP_EOL;

$files = [
    $root . '/database/migrations/add_metodos_aut_biometricos.sql',
    $root . '/database/functions/porteria/fun_insert_log_ingreso.sql',
    $root . '/database/functions/porteria/fun_registrar_ingreso_manual.sql',
    $root . '/database/functions/porteria/fun_insert_novedad_ingreso.sql',
    $root . '/database/functions/porteria/fun_guardar_enrolamiento_huella.sql',
    $root . '/database/functions/porteria/fun_identificar_persona_por_huella.sql',
];

foreach ($files as $file) {
    if (!is_file($file)) {
        fwrite(STDERR, 'FAIL no existe: ' . $file . PHP_EOL);
        exit(1);
    }
    echo 'Ejecutando ' . basename($file) . '...' . PHP_EOL;
    $sql = file_get_contents($file);
    if ($sql === false || trim($sql) === '') {
        fwrite(STDERR, 'FAIL vacío: ' . $file . PHP_EOL);
        exit(1);
    }
    try {
        $pdo->exec($sql);
        echo '  OK' . PHP_EOL;
    } catch (Throwable $e) {
        fwrite(STDERR, '  FAIL: ' . $e->getMessage() . PHP_EOL);
        exit(1);
    }
}

$check = $pdo->query(
    "SELECT p.proname FROM pg_proc p
     JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname IN (
         'fun_guardar_enrolamiento_huella',
         'fun_identificar_persona_por_huella'
       )
     ORDER BY 1"
)->fetchAll(PDO::FETCH_COLUMN);

echo 'Funciones: ' . implode(', ', $check) . PHP_EOL;
echo 'DONE' . PHP_EOL;
