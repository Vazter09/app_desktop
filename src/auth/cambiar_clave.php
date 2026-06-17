<?php
require_once(__DIR__ . '/../core/prepare.php');
require_once(__DIR__ . '/../core/helpers.php');

if (!isset($_SESSION['id_usuario'])) { 
    header("Location: ../../index.php"); 
    exit(); 
}

$mensaje = ""; 
$alerta = "info";

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $wid_usuario   = $_SESSION['id_usuario'];
    $wpass_antigua = $_POST['wpass_antigua'] ?? '';
    $wpass_nueva   = $_POST['wpass_nueva'] ?? '';

    try {
        // 1. Obtener hash actual
        $stmt = $pdo->prepare("SELECT pass_usuario FROM tab_usuarios WHERE id_usuario = ?");
        $stmt->execute([$wid_usuario]);
        $whash_actual = $stmt->fetchColumn();

        // 2. Validar contraseña anterior
        if ($whash_actual && password_verify($wpass_antigua, $whash_actual)) {
            
            // 3. Generar nuevo HASH
            $wnuevo_hash = password_hash($wpass_nueva, PASSWORD_BCRYPT);
            
            // 4. LLAMADA CORRECTA A TU FUNCIÓN: fun_actualizar_password
            $stmt = $pdo->prepare("SELECT fun_actualizar_password(CAST(? AS TEXT), CAST(? AS TEXT))");
            $stmt->execute([$wid_usuario, $wnuevo_hash]);
            
            $res = $stmt->fetchColumn();
            
            if ($res === 'OK') {
                $mensaje = "¡Éxito! Su contraseña ha sido actualizada.";
                $alerta = "success";
            } else {
                $mensaje = "Error del Motor: " . $res;
                $alerta = "danger";
            }
        } else {
            $mensaje = "La contraseña anterior es incorrecta.";
            $alerta = "danger";
        }
    } catch (Exception $e) {
        $mensaje = "Error de sistema: " . $e->getMessage();
        $alerta = "danger";
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>SistNomina | Cambiar Clave</title>
    <?php
    $bootstrap_vendor_mode = 'head';
    $bootstrap_asset_href = '../../';
    $bootstrap_vendor_icons = false;
    include __DIR__ . '/../layout/partials/bootstrap_vendor.php';
    ?>
    <?php $_v_auth_cc = @filemtime(dirname(__DIR__, 2) . '/css/auth-cambiar-clave.css') ?: time(); ?>
    <link rel="stylesheet" href="../../css/components.css">
    <link rel="stylesheet" href="../../css/auth-cambiar-clave.css?v=<?= (int) $_v_auth_cc ?>">
</head>
<body class="bg-light auth-cambiar-clave-page">
<img src="<?=PATH_LOGO?>" alt="Logo" class="logo-derecha">
<div class="container d-flex justify-content-center align-items-center auth-shell">
    <div class="card shadow-sm border-0 auth-card">
        <div class="card-header bg-dark text-white text-center py-3">
            <h5 class="mb-0 fw-bold">CAMBIAR CONTRASEÑA</h5>
        </div>
        <div class="card-body p-4">
            <?php renderPageFlash($mensaje, $alerta); ?>
            
            <form method="POST">
                <div class="mb-3">
                    <label class="small fw-bold">CONTRASEÑA ANTERIOR</label>
                    <input type="password" name="wpass_antigua" class="form-control" required>
                </div>
                <hr>
                <div class="mb-3">
                    <label class="small fw-bold">NUEVA CONTRASEÑA</label>
                    <input type="password" name="wpass_nueva" class="form-control" minlength="12" required>
                </div>
                <div class="row g-2">
                    <div class="col-6"><a href="../menu/menu_principal.php" class="btn btn-secondary w-100">Regresar</a></div>
                    <div class="col-6"><button type="submit" class="btn btn-primary w-100 btn-guardar-institucional">Guardar</button></div>
                </div>
            </form>
        </div>
    </div>
</div>
<?php $_v_cc_js = @filemtime(dirname(__DIR__, 2) . '/js/auth-cambiar-clave.js') ?: time(); ?>
<script src="../../js/auth-cambiar-clave.js?v=<?= (int) $_v_cc_js ?>"></script>
<?php $ui_assets_prefix = '../../'; include __DIR__ . '/../layout/ui_kit.php'; ?>
</body>
</html>