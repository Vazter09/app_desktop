#!/usr/bin/env php
<?php
/**
 * Genera un dispositivo portería y token para la app APK.
 *
 * Uso:
 *   php scripts/tools/generate_device_token.php "Tablet Portería 1" porteria
 *   php scripts/tools/generate_device_token.php "Tablet Portería 1" porteria 1
 *
 * El token mostrado solo se imprime una vez (6 caracteres alfanuméricos).
 * Guárdelo en la tablet al configurar la app.
 */
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    fwrite(STDERR, "Ejecutar solo desde CLI.\n");
    exit(1);
}

$nom = $argv[1] ?? '';
$usrAudit = $argv[2] ?? 'porteria';
$idEntradaDefault = isset($argv[3]) ? (int) $argv[3] : null;

if ($nom === '') {
    fwrite(STDERR, "Uso: php scripts/tools/generate_device_token.php \"Nombre tablet\" [id_usuario_audit] [id_entrada_default]\n");
    exit(1);
}

require_once dirname(__DIR__, 2) . '/backend/core/config.php';

try {
    $pdo = new PDO(
        sprintf('pgsql:host=%s;port=%s;dbname=%s', DB_HOST, DB_PORT, DB_NAME),
        DB_USER,
        DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (PDOException $e) {
    fwrite(STDERR, "Error de conexión: " . $e->getMessage() . "\n");
    exit(1);
}

$stmtUser = $pdo->prepare('SELECT id_usuario FROM tab_usuarios WHERE id_usuario = ?::TEXT AND ind_estado = TRUE');
$stmtUser->execute([$usrAudit]);
if (!$stmtUser->fetchColumn()) {
    fwrite(STDERR, "Usuario audit no encontrado o inactivo: {$usrAudit}\n");
    exit(1);
}

if ($idEntradaDefault !== null && $idEntradaDefault > 0) {
    $stmtEnt = $pdo->prepare('SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = ?::NUMERIC');
    $stmtEnt->execute([$idEntradaDefault]);
    if (!$stmtEnt->fetchColumn()) {
        fwrite(STDERR, "Entrada default no existe: {$idEntradaDefault}\n");
        exit(1);
    }
}

require_once dirname(__DIR__, 2) . '/backend/routers/porteria/_lib/DeviceToken.php';

$stmtIns = $pdo->prepare(
    'INSERT INTO tab_dispositivos_porteria
        (nom_dispositivo, token_hash, id_usuario_audit, id_entrada_default, ind_activo, usr_insert)
     VALUES (?::VARCHAR, ?::TEXT, ?::VARCHAR, ?::NUMERIC, TRUE, ?::VARCHAR)
     RETURNING id_dispositivo'
);
$placeholderHash = password_hash('pending', PASSWORD_BCRYPT);
$stmtIns->execute([
    $nom,
    $placeholderHash,
    $usrAudit,
    $idEntradaDefault,
    'generate_device_token',
]);
$idDispositivo = (int) $stmtIns->fetchColumn();

try {
    $token = DeviceToken::generateUnique($pdo);
} catch (RuntimeException $e) {
    fwrite(STDERR, $e->getMessage() . "\n");
    exit(1);
}
$tokenHash = DeviceToken::hash($token);

$stmtUpd = $pdo->prepare(
    'UPDATE tab_dispositivos_porteria
        SET token_hash = ?::TEXT, usr_update = ?::VARCHAR, fec_update = CURRENT_TIMESTAMP
      WHERE id_dispositivo = ?::INTEGER'
);
$stmtUpd->execute([$tokenHash, 'generate_device_token', $idDispositivo]);

echo "Dispositivo creado\n";
echo "  id_dispositivo: {$idDispositivo}\n";
echo "  nom_dispositivo: {$nom}\n";
echo "  id_usuario_audit: {$usrAudit}\n";
echo "  id_entrada_default: " . ($idEntradaDefault ?? 'null') . "\n";
echo "\nTOKEN (copiar en la app, no se vuelve a mostrar):\n";
echo $token . "\n";
