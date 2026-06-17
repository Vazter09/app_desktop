<?php
/**
 * LOGIN PRINCIPAL - SmartCSET V.1.0
 * Validación de ind_estado, Estética Corporativa y Seguridad
 */

require_once __DIR__ . '/src/core/prepare_login.php';
require_once __DIR__ . '/src/core/ErrorHandler.php';
require_once __DIR__ . '/src/core/helpers.php';

// Forzar HTTPS en producción
if (defined('APP_ENV') && APP_ENV === 'production' && empty($_SERVER['HTTPS'])) {
    header("Location: https://" . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'], true, 301);
    exit;
}


$w_error = '';
$w_user_value = '';

if (isset($_GET['sesion'])) {
    if ($_GET['sesion'] === 'invalida') {
        $w_error = 'Su sesión ya no está activa. Ingrese nuevamente.';
    } elseif ($_GET['sesion'] === 'ip') {
        $w_error = 'Su sesión se cerró porque la conexión no coincide con la del inicio de sesión. Ingrese nuevamente.';
    }
}

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

                    $w_ip = smartcsetClientIp();
                    $w_id_sesion = accesoIngresoSesion(
                        $stmt_fun_ingreso_sesion,
                        (string) $w_reg['id_usuario'],
                        $w_ip
                    );

                    session_regenerate_id(true);

                    $_SESSION['id_usuario']   = $w_reg['id_usuario'];
                    $_SESSION['nom_usuario'] = $w_reg['nom_usuario'];
                    $_SESSION['ind_usuario'] = !empty($w_reg['ind_usuario']);
                    $_SESSION['id_sesion']    = $w_id_sesion;

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
    <?php
    $bootstrap_vendor_mode = 'head';
    $bootstrap_asset_href = '';
    $bootstrap_vendor_icons = false;
    include __DIR__ . '/src/layout/partials/bootstrap_vendor.php';
    ?>
    <?php
    $_v_comp = @filemtime(__DIR__ . '/css/components.css') ?: time();
    $_v_login = @filemtime(__DIR__ . '/css/login.css') ?: time();
    ?>
    <?php include __DIR__ . '/src/layout/theme_vars.php'; ?>
    <link rel="stylesheet" href="css/components.css?v=<?= (int) $_v_comp ?>">
    <link rel="stylesheet" href="css/login.css?v=<?= (int) $_v_login ?>">
</head>

<body class="login-page">
    <div class="scanline" aria-hidden="true"></div>

    <div class="login-shell">
    <img src="<?= htmlspecialchars(smartcsetLogoUrl()) ?>" alt="Logo SENA" class="login-logo" id="login-logo-preview">

    <div class="card card-login shadow-lg">
        <div class="card-body p-4">
            <h4 class="text-center fw-bold mb-4 login-card__title">Control de Acceso</h4>

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
                        placeholder="••••••••••••" minlength="8">
                </div>
                <button type="submit" class="btn btn-ingresar w-100 py-2" id="loginSubmitBtn">
                    INGRESAR AL SISTEMA
                </button>
            </form>

            <div class="text-center mt-3">
                <a href="src/auth/recuperar.php" class="text-decoration-none small login-forgot-link">¿Olvidó su contraseña?</a>
            </div>
        </div>
    </div>
    </div>

    <?php $_v_login_js = @filemtime(__DIR__ . '/js/login-page.js') ?: time(); ?>
    <script src="js/login-page.js?v=<?= (int) $_v_login_js ?>"></script>
</body>

</html>