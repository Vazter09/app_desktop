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
        body {
            background: #f1f5fa;
            background-image:
                linear-gradient(rgba(28,45,64,0.08) 1px, transparent 1px),
                linear-gradient(90deg, rgba(28,45,64,0.08) 1px, transparent 1px);
            background-size: 50px 50px;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: 'Rajdhani', 'Segoe UI', sans-serif;
        }

        .card-login {
            border: 1px solid rgba(108, 152, 205, 0.22);
            border-top: 2px solid #49a3ff;
            background: rgba(255,255,255,0.97);
            width: 100%;
            max-width: 380px;
            box-shadow: 0 16px 36px rgba(13, 33, 56, 0.14);
            color: #1f3348;
            border-radius: 14px;
        }

        .btn-ingresar {
            background: linear-gradient(90deg, #2d8ff0, #5a75ff);
            color: white;
            font-weight: bold;
            border: 1px solid rgba(125, 177, 255, 0.35);
        }

        .btn-ingresar:hover {
            background: linear-gradient(90deg, #4ba9ff, #8097ff);
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

        .form-label {
            color: rgba(33, 63, 95, 0.78);
            letter-spacing: 0.04em;
        }

        .form-control {
            background: #edf1f7;
            border: 1px solid #d4ddeb;
            color: #1f3348;
        }

        .form-control:focus {
            background: #f4f8ff;
            border-color: #78adf0;
            color: #1f3348;
            box-shadow: 0 0 0 0.16rem rgba(73, 163, 255, 0.24);
        }

        .form-control::placeholder {
            color: rgba(70, 96, 124, 0.45);
        }
    </style>
</head>

<body>

    <img src="<?= htmlspecialchars(smartcsetLogoUrl()) ?>" alt="Logo" class="logo-derecha" id="login-logo-preview">

    <div class="card card-login shadow-lg">
        <div class="card-body p-4">
            <h4 class="text-center fw-bold mb-4" style="color: #1f3348;">Control de Acceso</h4>

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
                <a href="src/auth/recuperar.php" class="text-decoration-none small" style="color:rgba(70,96,124,.78);">¿Olvidó su contraseña?</a>
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