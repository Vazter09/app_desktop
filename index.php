<?php
/**
 * LOGIN PRINCIPAL - SmartCSET V.1.0
 * Validación de ind_estado, Estética Corporativa y Seguridad
 */

// Agregar headers de seguridad
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: SAMEORIGIN");
header("X-XSS-Protection: 1; mode=block");
header("Referrer-Policy: strict-origin-when-cross-origin");

// Forzar HTTPS en producción (comentar en desarrollo)
// if (APP_ENV === 'production' && empty($_SERVER['HTTPS'])) {
//     header("Location: https://" . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI']);
//     exit();
// }

session_start();

// Invocamos el cerebro del sistema
require_once('src/core/prepare.php');
require_once('src/core/helpers.php');

$w_error = "";

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $w_user = $_POST['txt_usuario'] ?? '';
    $w_pass = $_POST['txt_clave'] ?? '';

    try {
        // 1. Buscamos al usuario usando el prepare centralizado
        $stmt_login->execute([$w_user]);
        $w_reg = $stmt_login->fetch();

        if ($w_reg) {
            // 2. VALIDACIÓN CRÍTICA DE ESTADO: inhabilitado no ingresa (aunque sea admin)
            if ($w_reg['ind_estado'] == false) {
                $w_error = "ACCESO DENEGADO: Su usuario se encuentra inhabilitado por el administrador.";
            } else {
                // 3. VALIDACIÓN DE CONTRASEÑA (Compatible con crypt bf de tu SQL)
                if (password_verify($w_pass, $w_reg['pass_usuario'])) {

                    // Creamos la sesión
                    $_SESSION['id_usuario']   = $w_reg['id_usuario'];
                    $_SESSION['nom_usuario'] = $w_reg['nom_usuario'];
                    $_SESSION['ind_usuario'] = !empty($w_reg['ind_usuario']);

                    // Redirección al Menú Principal
                    header("Location: src/menu/menu_principal.php");
                    exit();
                } else {
                    $w_error = "ID de usuario o contraseña incorrectos.";
                }
            }
        } else {
            $w_error = "ID de usuario o contraseña incorrectos.";
        }
    } catch (Exception $e) {
        $w_error = "Error técnico: " . $e->getMessage();
    }
}
?>
<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars(AppConfig::nomSistema()) ?> | Ingreso</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <?php $_v_comp = @filemtime(__DIR__ . '/css/components.css') ?: time(); ?>
    <link rel="stylesheet" href="css/components.css?v=<?= (int) $_v_comp ?>">
    <?php include __DIR__ . '/src/layout/theme_vars.php'; ?>
    <style>
        :root {
            --verde-oscuro: var(--v-oscuro);
            --verde-oliva: var(--v-oliva);
        }

        body {
            background-color: #f4f7f6;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: 'Segoe UI', sans-serif;
        }

        .card-login {
            border: none;
            border-top: 6px solid var(--verde-oscuro);
            width: 100%;
            max-width: 380px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
        }

        .btn-ingresar {
            background-color: var(--verde-oscuro);
            color: white;
            font-weight: bold;
        }

        .btn-ingresar:hover {
            background-color: var(--verde-oliva);
            color: white;
        }

        .logo-derecha {
            position: absolute;
            top: 20px;
            right: 20px;
            max-width: 150px;
            z-index: 1050;
        }

        .error-box {
            font-size: 0.85rem;
            text-align: center;
        }
    </style>
</head>

<body>

    <img src="<?= htmlspecialchars(smartcsetLogoUrl()) ?>" alt="Logo" class="logo-derecha" id="login-logo-preview">

    <div class="card card-login shadow-lg">
        <div class="card-body p-4">
            <h4 class="text-center fw-bold mb-4" style="color: var(--verde-oscuro);">Control de Acceso</h4>

            <?php renderPageFlash($w_error ?: null, 'danger', 'Acceso denegado'); ?>

            <form method="POST" autocomplete="off" id="loginForm">
                <div class="mb-3">
                    <label class="form-label small fw-bold">Identificación</label>
                    <input type="text" name="txt_usuario" class="form-control" required placeholder="ID de usuario">
                </div>
                <div class="mb-4">
                    <label class="form-label small fw-bold">Contraseña</label>
                    <input type="password" name="txt_clave" class="form-control" required placeholder="••••••••••••"
                        minlength="12">
                </div>
                <button type="submit" class="btn btn-ingresar w-100 py-2">
                    INGRESAR AL SISTEMA
                </button>
            </form>

            <div class="text-center mt-3">
                <a href="src/auth/recuperar.php" class="text-decoration-none small text-muted">¿Olvidó su contraseña?</a>
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
    <script src="js/login.js"></script>
    <?php $ui_assets_prefix = ''; include 'src/layout/ui_kit.php'; ?>
</body>

</html>