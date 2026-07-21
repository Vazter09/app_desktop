<?php

declare(strict_types=1);

/**
 * Diagnóstico: firmas ingreso + reproducir fallo para ver DETAIL real.
 * Uso: php scripts/dev/_diag_ingreso_facial.php
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
$pdo = new PDO($dsn, $env['DB_USER'] ?? 'postgres', $env['DB_PASS'] ?? '', [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]);
echo "OK conexion\n\n";

echo "=== FIRMAS ===\n";
$st = $pdo->query(
    "SELECT p.oid::regprocedure::text AS sig
       FROM pg_proc p
       JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname IN (
            'fun_registrar_ingreso_manual',
            'fun_insert_log_ingreso',
            'fun_verify_retardo_aprendiz',
            'fun_upsert_persona_visitante',
            'fun_update_persona_tras_ingreso'
        )
      ORDER BY 1"
);
foreach ($st as $r) {
    echo 'SIG: ' . $r['sig'] . PHP_EOL;
}

echo "\n=== TIPOS COLUMNAS ===\n";
$st = $pdo->query(
    "SELECT a.attrelid::regclass::text AS tbl, a.attname,
            format_type(a.atttypid, a.atttypmod) AS typ
       FROM pg_attribute a
      WHERE a.attname IN ('facial_embedding', 'val_patron_facial', 'huella_template')
        AND NOT a.attisdropped AND a.attnum > 0
      ORDER BY 1, 2"
);
foreach ($st as $r) {
    echo 'TYP: ' . $r['tbl'] . '.' . $r['attname'] . ' = ' . $r['typ'] . PHP_EOL;
}

echo "\n=== PERSONA JOSE GREGORIO / ALVAREZ DULCEY ===\n";
$st = $pdo->prepare(
    "SELECT id_persona, id_tipo_docum, id_tipo_persona, nom_persona, ape_persona
       FROM tab_personas
      WHERE upper(nom_persona) LIKE '%JOSE%GREGORIO%'
         OR upper(ape_persona) LIKE '%DULCEY%'
         OR upper(ape_persona) LIKE '%ALVAREZ%'
      ORDER BY id_persona
      LIMIT 10"
);
$st->execute();
$personas = $st->fetchAll(PDO::FETCH_ASSOC);
foreach ($personas as $r) {
    echo json_encode($r, JSON_UNESCAPED_UNICODE) . PHP_EOL;
}

echo "\n=== METODOS AUT ===\n";
foreach ($pdo->query('SELECT id_metodo_aut, nom_metodo_aut FROM tab_metodos_aut ORDER BY 1') as $r) {
    echo 'MET: ' . $r['id_metodo_aut'] . ' ' . $r['nom_metodo_aut'] . PHP_EOL;
}

// Elegir persona aprendiz para reproducir
$target = null;
foreach ($personas as $p) {
    $full = strtoupper(($p['nom_persona'] ?? '') . ' ' . ($p['ape_persona'] ?? ''));
    if (str_contains($full, 'GREGORIO') || str_contains($full, 'DULCEY')) {
        $target = $p;
        break;
    }
}
if ($target === null && $personas !== []) {
    $target = $personas[0];
}

if ($target === null) {
    echo "\nNo hay persona objetivo; fin.\n";
    exit(0);
}

echo "\n=== REPRODUCIR INGRESO (rollback) target=" . $target['id_persona'] . " ===\n";

// Vector 128 sintético
$vals = [];
for ($i = 0; $i < 128; $i++) {
    $vals[] = '0.01';
}
$vec = '[' . implode(',', $vals) . ']';

$pdo->beginTransaction();
try {
    // Cerrar ingreso abierto si existe (solo en esta tx de prueba)
    $st = $pdo->prepare(
        "UPDATE tab_log_ingresos
            SET fec_salida = CURRENT_TIMESTAMP + interval '1 second'
          WHERE id_visitante = ?::NUMERIC
            AND fec_salida = fec_ingreso"
    );
    $st->execute([$target['id_persona']]);

    $sql = "SELECT fun_registrar_ingreso_manual(
        ?::NUMERIC, ?::VARCHAR, ?::NUMERIC, ?::VARCHAR, ?::VARCHAR,
        ?::NUMERIC, ?::TEXT, ?::DECIMAL, ?::BOOLEAN, ?::VECTOR, ?::BYTEA
    )";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        $target['id_persona'],
        $target['id_tipo_docum'],
        $target['id_tipo_persona'],
        $target['nom_persona'],
        $target['ape_persona'],
        1,
        'diag_ingreso_facial',
        4,
        'false',
        $vec,
        null,
    ]);
    $id = $stmt->fetchColumn();
    echo "OK ingreso id=" . var_export($id, true) . PHP_EOL;
    $pdo->rollBack();
    echo "Rollback OK (no se deja dato de prueba)\n";
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo "FAIL class=" . get_class($e) . PHP_EOL;
    echo "FAIL msg=" . $e->getMessage() . PHP_EOL;
    if ($e instanceof PDOException) {
        echo "FAIL errorInfo=" . json_encode($e->errorInfo, JSON_UNESCAPED_UNICODE) . PHP_EOL;
    }
}
