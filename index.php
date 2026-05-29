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

require_once __DIR__ . '/src/core/prepare_login.php';
require_once __DIR__ . '/src/core/ErrorHandler.php';
require_once __DIR__ . '/src/core/helpers.php';

$w_error = '';
$w_user_value = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $w_user = trim($_POST['txt_usuario'] ?? '');
    $w_pass = $_POST['txt_clave'] ?? '';
    $w_user_value = $w_user;

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

                    $stmt_fun_ingreso_sesion->execute([$w_reg['id_usuario']]);
                    $stmt_fun_ingreso_sesion->fetchColumn();

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
    } catch (PDOException $e) {
        $w_error = ErrorHandler::userMessageFromException($e);
    } catch (Exception $e) {
        $w_error = ErrorHandler::userMessageFromException($e);
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
        body.login-page {
            background: #f1f5fa;
            background-image:
                linear-gradient(rgba(28,45,64,0.08) 1px, transparent 1px),
                linear-gradient(90deg, rgba(28,45,64,0.08) 1px, transparent 1px);
            background-size: 50px 50px;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: 'Rajdhani', 'Segoe UI', sans-serif;
            padding: 1.5rem;
        }

        .login-shell {
            display: flex;
            flex-direction: column;
            align-items: center;
            width: 100%;
            max-width: 380px;
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

        .btn-ingresar:hover:not(:disabled) {
            background: linear-gradient(90deg, #4ba9ff, #8097ff);
            color: white;
        }

        .btn-ingresar:disabled {
            opacity: 0.72;
            cursor: wait;
        }

        .login-logo {
            display: block;
            width: auto;
            max-width: 160px;
            max-height: 120px;
            margin: 0 auto 1.25rem;
            object-fit: contain;
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

        .login-alert {
            display: flex;
            gap: 0.75rem;
            align-items: flex-start;
            padding: 0.85rem 1rem;
            margin-bottom: 1rem;
            border-radius: 10px;
            border: 1px solid rgba(192, 57, 43, 0.35);
            border-left: 4px solid #c0392b;
            background: #fff5f5;
            color: #4a3030;
        }

        .login-alert__icon {
            flex-shrink: 0;
            font-size: 1.25rem;
            line-height: 1.3;
            color: #c0392b;
        }

        .login-alert__title {
            font-size: 0.95rem;
            font-weight: 700;
            color: #8b1e1e;
            margin-bottom: 0.25rem;
        }

        .login-alert__message {
            font-size: 0.9rem;
            line-height: 1.5;
            margin: 0;
            font-weight: 500;
        }

        .login-inline-error {
            display: none;
            margin-bottom: 1rem;
            padding: 0.75rem 1rem;
            border-radius: 8px;
            background: #fff8e6;
            border: 1px solid rgba(184, 134, 11, 0.35);
            color: #5c4a12;
            font-size: 0.875rem;
            font-weight: 600;
        }

        .login-inline-error.is-visible {
            display: block;
        }
    </style>
</head>

<body class="login-page">

    <div class="login-shell">
    <img src="<?= htmlspecialchars(smartcsetLogoUrl()) ?>" alt="Logo SENA" class="login-logo" id="login-logo-preview">

    <div class="card card-login shadow-lg">
        <div class="card-body p-4">
            <h4 class="text-center fw-bold mb-4" style="color: #1f3348;">Control de Acceso</h4>

            <?php if ($w_error !== ''): ?>
            <div class="login-alert" role="alert" aria-live="assertive">
                <span class="login-alert__icon" aria-hidden="true">&#9888;</span>
                <div>
                    <div class="login-alert__title">Acceso denegado</div>
                    <p class="login-alert__message"><?= htmlspecialchars($w_error) ?></p>
                </div>
            </div>
            <?php endif; ?>

            <div id="loginClientError" class="login-inline-error" role="alert"></div>

            <form method="POST" autocomplete="off" id="loginForm">
                <div class="mb-3">
                    <label class="form-label small fw-bold" for="txt_usuario">Identificación</label>
                    <input type="text" id="txt_usuario" name="txt_usuario" class="form-control" required
                        placeholder="ID de usuario" value="<?= htmlspecialchars($w_user_value) ?>">
                </div>
                <div class="mb-4">
                    <label class="form-label small fw-bold" for="txt_clave">Contraseña</label>
                    <input type="password" id="txt_clave" name="txt_clave" class="form-control" required
                        placeholder="••••••••••••" minlength="12">
                </div>
                <button type="submit" class="btn btn-ingresar w-100 py-2" id="loginSubmitBtn">
                    INGRESAR AL SISTEMA
                </button>
            </form>

            <div class="text-center mt-3">
                <a href="src/auth/recuperar.php" class="text-decoration-none small" style="color:rgba(70,96,124,.78);">¿Olvidó su contraseña?</a>
            </div>
        </div>
    </div>
    </div>

    <script>
        (function () {
            const loginForm = document.getElementById('loginForm');
            const submitBtn = document.getElementById('loginSubmitBtn');
            const clientError = document.getElementById('loginClientError');
            const passInput = document.getElementById('txt_clave');

            if (!loginForm || !submitBtn) {
                return;
            }

            loginForm.addEventListener('submit', function (e) {
                const pass = passInput ? passInput.value : '';

                if (pass.length < 12) {
                    e.preventDefault();
                    if (clientError) {
                        clientError.textContent = 'La contraseña debe tener al menos 12 caracteres.';
                        clientError.classList.add('is-visible');
                    }
                    return;
                }

                if (clientError) {
                    clientError.classList.remove('is-visible');
                }

                submitBtn.disabled = true;
                submitBtn.textContent = 'Verificando…';
            });

            history.pushState(null, null, location.href);
            window.onpopstate = function () {
                history.go(1);
            };
        })();
    </script>
</body>

</html>