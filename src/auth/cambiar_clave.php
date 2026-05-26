<?php
session_start();
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
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="../../css/components.css">
    <style>
        .logo-derecha { position: fixed; top: 15px; right: 15px; max-width: 120px; z-index: 1050; }
    </style>
</head>
<body class="bg-light">
<img src="<?=PATH_LOGO?>" alt="Logo" class="logo-derecha">
<div class="container d-flex justify-content-center align-items-center" style="min-height: 80vh;">
    <div class="card shadow-sm border-0" style="width: 400px;">
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
                    <div class="col-6"><button type="submit" class="btn btn-primary w-100" style="background-color:#003366;">Guardar</button></div>
                </div>
            </form>
        </div>
    </div>
</div>
<script>
    // Bloquear navegación hacia atrás
    history.pushState(null, null, location.href);
    window.onpopstate = function () {
        history.go(1);
    };
    
    // Confirmación solo si hay cambios sin guardar
    let hasChanges = false;
    document.addEventListener('input', function(e) {
        if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') {
            hasChanges = true;
        }
    });
    window.addEventListener('beforeunload', function (e) {
        if (hasChanges) {
            e.preventDefault();
            e.returnValue = '';
        }
    });
    document.addEventListener('submit', function() {
        hasChanges = false;
    });
</script>
<?php $ui_assets_prefix = '../../'; include __DIR__ . '/../layout/ui_kit.php'; ?>
</body>
</html>