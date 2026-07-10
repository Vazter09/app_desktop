<?php

declare(strict_types=1);

/**
 * Despliega migración biometría → tab_personas + funciones relacionadas.
 * Uso: php scripts/dev/_deploy_biometria_personas.php
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
    $root . '/database/migrations/migrate_biometria_a_tab_personas.sql',
    $root . '/database/functions/acceso/sesiones/fun_ingreso_sesion.sql',
    $root . '/database/functions/porteria/fun_insert_log_ingreso.sql',
    $root . '/database/functions/porteria/fun_registrar_ingreso_manual.sql',
    $root . '/database/functions/porteria/fun_insert_novedad_ingreso.sql',
    $root . '/database/functions/porteria/fun_guardar_enrolamiento_facial.sql',
    $root . '/database/functions/porteria/fun_identificar_persona_por_rostro.sql',
];

foreach ($files as $path) {
    if (!is_readable($path)) {
        fwrite(STDERR, 'FAIL: no existe ' . $path . PHP_EOL);
        exit(1);
    }
    $sql = file_get_contents($path);
    echo 'Ejecutando ' . basename($path) . ' ...' . PHP_EOL;
    try {
        $pdo->exec($sql);
        echo '  OK' . PHP_EOL;
    } catch (Throwable $e) {
        fwrite(STDERR, '  FAIL: ' . $e->getMessage() . PHP_EOL);
        exit(1);
    }
}

echo PHP_EOL . '=== Verificación ===' . PHP_EOL;

$checks = [
    "SELECT column_name, udt_name FROM information_schema.columns
      WHERE table_name = 'tab_personas'
        AND column_name IN ('val_patron_facial', 'ruta_foto_facial')
      ORDER BY column_name",
    "SELECT column_name, udt_name FROM information_schema.columns
      WHERE table_name = 'tab_log_ingresos' AND column_name = 'facial_embedding'",
    "SELECT EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_name = 'tab_novedades_ingreso'
     ) AS novedades_existe",
    "SELECT oid::regprocedure::text AS firma
       FROM pg_proc
      WHERE proname IN (
            'fun_guardar_enrolamiento_facial',
            'fun_identificar_persona_por_rostro',
            'fun_insert_novedad_ingreso',
            'fun_insert_log_ingreso',
            'fun_registrar_ingreso_manual'
        )
      ORDER BY 1",
];

foreach ($checks as $sql) {
    $stmt = $pdo->query($sql);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($rows as $row) {
        echo implode(' | ', $row) . PHP_EOL;
    }
}

echo PHP_EOL . 'Despliegue completado.' . PHP_EOL;
