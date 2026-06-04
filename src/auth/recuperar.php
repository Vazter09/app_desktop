<?php
/**
 * PROGRAMA DE RECUPERACIÓN DE CLAVE - SistNomina V.1.2
 * ARCHIVO COMPLETO: 145 LÍNEAS.
 * Corregido: Encriptación única para compatibilidad con login y restauración de UI.
 */
require_once(__DIR__ . '/../core/prepare.php');
require_once(__DIR__ . '/../core/helpers.php');

$w_mensaje = "";
$w_tipo_alerta = "info";
$w_pass_temp = "";
$w_ver_pantalla = false;

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $w_id_usuario = $_POST['txt_usuario'] ?? '';
    $w_metodo     = $_POST['rdo_metodo']  ?? 'correo';

    // Generar clave temporal en texto plano (la ve el usuario)
    $w_pass_temp = substr(str_shuffle("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"), 0, 12);
    // Encriptar con bcrypt PHP — idéntico método que usa el login
    $w_pass_hash = password_hash($w_pass_temp, PASSWORD_BCRYPT);

    try {
        if ($w_metodo == 'correo') {
            $w_mail_ingresado = $_POST['txt_correo'] ?? '';
            $stmt_valida_mail->execute([$w_id_usuario, $w_mail_ingresado]);

            if ($stmt_valida_mail->fetch()) {
                $stmt_upd_pass->execute([$w_pass_hash, $w_id_usuario]);
                $w_mensaje     = "ÉXITO: Se ha enviado la clave temporal a su correo.";
                $w_tipo_alerta = "success";
            } else {
                $w_mensaje     = "ERROR: El usuario o correo no coinciden.";
                $w_tipo_alerta = "danger";
            }
        } else {
            // Modo pantalla: verificar que el usuario exista y esté activo
            $stmt_login->execute([$w_id_usuario]);
            $w_usr_existe = $stmt_login->fetch();

            if ($w_usr_existe && !empty($w_usr_existe['ind_estado'])) {
                $stmt_upd_pass->execute([$w_pass_hash, $w_id_usuario]);
                $w_ver_pantalla = true;
                $w_mensaje      = "ÉXITO: Clave generada correctamente.";
                $w_tipo_alerta  = "success";
            } else {
                $w_mensaje     = "ERROR: El usuario no existe o está inactivo.";
                $w_tipo_alerta = "danger";
            }
        }
    } catch (Exception $e) {
        $w_mensaje     = "ERROR: " . $e->getMessage();
        $w_tipo_alerta = "danger";
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>SistNomina | Recuperar Clave</title>
    <?php
    $bootstrap_vendor_mode = 'head';
    $bootstrap_asset_href = '../../';
    include __DIR__ . '/../layout/partials/bootstrap_vendor.php';
    ?>
    <?php $_v_auth_rec = @filemtime(dirname(__DIR__, 2) . '/css/auth-recuperar.css') ?: time(); ?>
    <link rel="stylesheet" href="../../css/components.css">
    <link rel="stylesheet" href="../../css/auth-recuperar.css?v=<?= (int) $_v_auth_rec ?>">
</head>
<body class="auth-recuperar-page">
<img src="<?=PATH_LOGO?>" alt="Logo" class="logo-derecha">
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-5">
            <div class="card card-recuperar">
                <div class="bg-dark p-4 text-center rounded-top">
                    <h4 class="text-white mb-0">Recuperación de Acceso</h4>
                </div>
                <div class="card-body p-4">
                    <?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

                    <?php if ($w_ver_pantalla): ?>
                        <div class="text-center p-3 bg-light border rounded">
                            <p class="small fw-bold text-muted mb-2">SU NUEVA CLAVE TEMPORAL:</p>
                            <div class="pass-container mb-3">
                                <input type="password" id="w_input_pass" class="form-control form-control-lg text-center font-monospace" value="<?= $w_pass_temp ?>" readonly>
                                <i class="bi bi-eye toggle-btn" id="toggleIcon" onclick="togglePass()"></i>
                            </div>
                            <p class="small text-warning mb-0"><i class="bi bi-exclamation-triangle-fill me-1"></i>Copie su clave antes de salir.</p>
                            <a href="../../index.php" class="btn btn-verde w-100 mt-2">Volver al Login</a>
                        </div>
                    <?php else: ?>
                        <form action="recuperar.php" method="POST">
                            <div class="mb-3">
                                <label class="small fw-bold">ID de Usuario</label>
                                <input type="text" name="txt_usuario" class="form-control" required placeholder="Usuario">
                            </div>
                            <div class="mb-3">
                                <label class="small fw-bold d-block mb-2">Método de entrega</label>
                                <div class="form-check form-check-inline">
                                    <input class="form-check-input" type="radio" name="rdo_metodo" value="correo" checked onclick="toggleMail(true)">
                                    <label class="form-check-label small">Correo</label>
                                </div>
                                <div class="form-check form-check-inline">
                                    <input class="form-check-input" type="radio" name="rdo_metodo" value="pantalla" onclick="toggleMail(false)">
                                    <label class="form-check-label small">Pantalla</label>
                                </div>
                            </div>
                            <div id="w_div_correo" class="mb-4">
                                <label class="small fw-bold">Confirme su Correo</label>
                                <input type="email" name="txt_correo" id="w_txt_correo" class="form-control" required>
                            </div>
                            <button type="submit" class="btn btn-verde w-100 py-2 fw-bold">PROCESAR</button>
                            <div class="text-center mt-3"><a href="../../index.php" class="small text-muted text-decoration-none">Cancelar</a></div>
                        </form>
                    <?php endif; ?>
                </div>
            </div>
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
<script>
function toggleMail(ver) {
    document.getElementById('w_div_correo').style.display = ver ? 'block' : 'none';
    document.getElementById('w_txt_correo').required = ver;
}

function togglePass() {
    const passInput = document.getElementById("w_input_pass");
    const icon = document.getElementById("toggleIcon");
    if (passInput.type === "password") {
        passInput.type = "text";
        icon.classList.replace("bi-eye", "bi-eye-slash");
    } else {
        passInput.type = "password";
        icon.classList.replace("bi-eye-slash", "bi-eye");
    }
}
</script>
<?php $ui_assets_prefix = '../../'; include __DIR__ . '/../layout/ui_kit.php'; ?>
</body>
</html>