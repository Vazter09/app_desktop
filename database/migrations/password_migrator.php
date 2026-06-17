<?php
/**
 * MIGRADOR DE CONTRASEÑAS - SistNomina
 * Convierte todas las claves de crypt() PostgreSQL a password_hash() PHP (bcrypt).
 * ⚠️ ARCHIVO PRIVADO - Solo para administradores
 * ¡BORRAR ESTE ARCHIVO DESPUÉS DE USAR!
 */

// Verificar acceso local solamente (RECOMENDADO: eliminar o proteger con autenticación)
if (!in_array($_SERVER['REMOTE_ADDR'], ['127.0.0.1', '::1', 'localhost'])) {
    http_response_code(403);
    die("Acceso Denegado: Solo acceso local permitido");
}

require_once('../../src/core/config.php');

$dsn = "pgsql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME;
$pdo = new PDO($dsn, DB_USER, DB_PASS, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

// ---------------------------------------------------------------
// MODO 1: Listar usuarios y ver si sus hashes son bcrypt PHP
// ---------------------------------------------------------------
$usuarios = $pdo->query("SELECT id_usuario, nom_usuario, pass_usuario, ind_estado FROM tab_usuarios ORDER BY id_usuario")->fetchAll(PDO::FETCH_ASSOC);

echo "<!DOCTYPE html><html><head><meta charset='UTF-8'>
<link href='../../css/vendor/bootstrap-5.3.0/bootstrap.min.css' rel='stylesheet'>
<link rel='stylesheet' href='../../css/components.css'>
</head><body class='container mt-4'>";
echo "<h3 class='mb-3'>🔐 Migrador de Contraseñas — SistNomina</h3>";
echo "<div class='alert alert-danger'><strong>⚠️ Borrar este archivo después de usarlo.</strong></div>";

// ---------------------------------------------------------------
// MODO 2: Resetear clave de un usuario con nueva clave en bcrypt PHP
// ---------------------------------------------------------------
$mensaje = "";
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['btn_resetear'])) {
    $uid = $_POST['hid_uid'];
    $newpass = $_POST['txt_nueva_clave'];
    if (strlen($newpass) >= 12) {
        $hash = password_hash($newpass, PASSWORD_BCRYPT);
        $stmt = $pdo->prepare("UPDATE tab_usuarios SET pass_usuario = ? WHERE id_usuario = ?");
        $stmt->execute([$hash, $uid]);
        $mensaje = "<div class='alert alert-success'>✅ Clave del usuario <strong>{$uid}</strong> actualizada correctamente con bcrypt PHP.</div>";
    }
    else {
        $mensaje = "<div class='alert alert-danger'>❌ La clave debe tener al menos 12 caracteres.</div>";
    }
    // Recargar lista
    $usuarios = $pdo->query("SELECT id_usuario, nom_usuario, pass_usuario, ind_estado FROM tab_usuarios ORDER BY id_usuario")->fetchAll(PDO::FETCH_ASSOC);
}
echo $mensaje;

// ---------------------------------------------------------------
// TABLA DE USUARIOS CON DIAGNÓSTICO DE HASH
// ---------------------------------------------------------------
echo "<table class='table table-bordered table-hover align-middle'>
<thead class='table-dark'><tr>
  <th>ID</th><th>Nombre</th><th>Estado</th><th>Tipo de Hash</th><th>Acción</th>
</tr></thead><tbody>";

foreach ($usuarios as $u) {
    $hash = $u['pass_usuario'];
    $es_bcrypt_php = (strpos($hash, '$2y$') === 0 || strpos($hash, '$2a$') === 0);
    $tipo_badge = $es_bcrypt_php
        ? "<span class='badge bg-success'>✅ bcrypt PHP</span>"
        : "<span class='badge bg-danger'>❌ Incompatible ({$hash})</span>";
    $estado = $u['ind_estado'] ? "<span class='badge bg-success'>Activo</span>" : "<span class='badge bg-secondary'>Inactivo</span>";

    echo "<tr>
      <td><strong>{$u['id_usuario']}</strong></td>
      <td>{$u['nom_usuario']}</td>
      <td>{$estado}</td>
      <td>{$tipo_badge}</td>
      <td>
        <form method='POST' class='d-flex gap-2 align-items-center'>
          <input type='hidden' name='hid_uid' value='{$u['id_usuario']}'>
          <input type='text' name='txt_nueva_clave' class='form-control form-control-sm' placeholder='Nueva clave' style='width:150px' required minlength='12'>
          <button type='submit' name='btn_resetear' class='btn btn-warning btn-sm'>Resetear</button>
        </form>
      </td>
    </tr>";
}
echo "</tbody></table>";
echo "<hr><p class='text-danger'><strong>IMPORTANTE:</strong> Elimina este archivo después de completar la migración.</p>";
echo "<a href='../../index.php' class='btn btn-primary'>Ir al Login</a></body></html>";
?>
