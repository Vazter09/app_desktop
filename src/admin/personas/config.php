<?php
require_once __DIR__ . '/../../core/prepare.php';
require_once __DIR__ . '/../../core/ErrorHandler.php';
require_once __DIR__ . '/../../core/helpers.php';
require_once __DIR__ . '/../../core/ConfigSistemaDefaults.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ../../../index.php');
    exit();
}

if (!usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])) {
    http_response_code(403);
    die('Acceso denegado. Solo administradores pueden modificar la configuración del sistema.');
}

$w_mensaje = '';
$w_tipo_alerta = 'success';
$smartcset_asset_href = smartcsetProjectAssetHref();

$config = [];
if ($stmt_get_config instanceof PDOStatement) {
    try {
        $stmt_get_config->execute();
        $config = $stmt_get_config->fetch(PDO::FETCH_ASSOC) ?: [];
    } catch (PDOException) {
        $config = [];
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['btn_guardar_registro'])) {
    if (!$stmt_get_config instanceof PDOStatement) {
        $w_mensaje = 'Ejecute database/migrations/run_config_sistema.sh antes de guardar.';
        $w_tipo_alerta = 'danger';
    } else {
        try {
            $stmt_get_config->execute();
            $row = $stmt_get_config->fetch(PDO::FETCH_ASSOC) ?: [];

            $indModulo = isset($_POST['chk_modulo_registro']);
            // El módulo de registro siempre usa su login propio (standalone).
            $row['ind_modulo_registro'] = $indModulo;
            $row['ind_login_registro_standalone'] = $indModulo;
            $row['usr_registro'] = trim((string) ($_POST['txt_usr_registro'] ?? ''));

            $passHash = null;
            $nuevaClave = trim((string) ($_POST['txt_pass_registro'] ?? ''));
            if ($nuevaClave !== '') {
                validarLongitudPassword($nuevaClave, true);
                $passHash = password_hash($nuevaClave, PASSWORD_BCRYPT);
            }

            $stmt_fun_upd_config->execute(
                ConfigSistemaDefaults::toUpdateParamsFromRow($row, (string) $_SESSION['id_usuario'], $passHash)
            );
            $res = $stmt_fun_upd_config->fetchColumn();
            if (strpos((string) $res, 'OK') !== false) {
                AppConfig::reset();
                AppConfig::boot($pdo);
                $stmt_get_config->execute();
                $config = $stmt_get_config->fetch(PDO::FETCH_ASSOC) ?: [];
                $w_mensaje = 'Configuración del módulo guardada correctamente.';
            } else {
                $w_mensaje = 'Error: ' . $res;
                $w_tipo_alerta = 'danger';
            }
        } catch (PDOException $e) {
            $w_mensaje = ErrorHandler::handleDatabaseException($e)['message'];
            $w_tipo_alerta = 'danger';
        } catch (Exception $e) {
            $w_mensaje = ErrorHandler::handleValidationException($e)['message'];
            $w_tipo_alerta = 'danger';
        }
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['btn_restaurar_registro'])) {
    if (!$stmt_get_config instanceof PDOStatement) {
        $w_mensaje = 'Ejecute database/migrations/run_config_sistema.sh antes de restaurar.';
        $w_tipo_alerta = 'danger';
    } else {
        try {
            $stmt_get_config->execute();
            $row = $stmt_get_config->fetch(PDO::FETCH_ASSOC) ?: [];
            $defaults = ConfigSistemaDefaults::values();

            $row['ind_modulo_registro'] = $defaults['ind_modulo_registro'] ?? true;
            $row['ind_login_registro_standalone'] = $defaults['ind_modulo_registro'] ?? true;
            $row['usr_registro'] = (string) ($defaults['usr_registro'] ?? 'usuariocset');

            $passHash = password_hash('usuariocset', PASSWORD_BCRYPT);
            $stmt_fun_upd_config->execute(
                ConfigSistemaDefaults::toUpdateParamsFromRow($row, (string) $_SESSION['id_usuario'], $passHash)
            );
            $res = $stmt_fun_upd_config->fetchColumn();
            if (strpos((string) $res, 'OK') !== false) {
                AppConfig::reset();
                AppConfig::boot($pdo);
                $stmt_get_config->execute();
                $config = $stmt_get_config->fetch(PDO::FETCH_ASSOC) ?: [];
                $w_mensaje = 'Se restauró la configuración del módulo de personas.';
            } else {
                $w_mensaje = 'Error: ' . $res;
                $w_tipo_alerta = 'danger';
            }
        } catch (PDOException $e) {
            $w_mensaje = ErrorHandler::handleDatabaseException($e)['message'];
            $w_tipo_alerta = 'danger';
        }
    }
}

$c = $config;
$page_title = 'Config. módulo personas';
$active_menu_id = '0402';
$wnom_usuario = $_SESSION['nom_usuario'] ?? '';

include __DIR__ . '/../../layout/head.php';
include __DIR__ . '/../../layout/sidebar.php';
include __DIR__ . '/../../layout/topbar.php';
?>

<?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

<form method="POST" class="row g-3">
    <div class="col-12">
        <div class="card shadow-sm border-0 registro-config-card">
            <div class="card-header bg-corporativo py-2 d-flex flex-wrap justify-content-between align-items-center gap-2">
                <strong style="font-size:0.95rem;">
                    <i class="bi bi-person-vcard-fill me-2"></i>Configuración — Módulo de personas
                </strong>
                <button type="submit" name="btn_restaurar_registro" value="1"
                        class="btn btn-sm btn-light fw-bold"
                        data-smart-confirm
                        data-smart-confirm-title="Restaurar módulo personas"
                        data-smart-confirm-message="¿Restaurar la configuración del módulo de personas a los valores por defecto?"
                        data-smart-confirm-ok="Restaurar"
                        data-smart-confirm-variant="warning">
                    <i class="bi bi-arrow-counterclockwise me-1"></i>Restaurar
                </button>
            </div>

            <div class="card-body registro-config-body">
                <div class="config-toggle-list">
                    <div class="config-toggle-item">
                        <input class="form-check-input" type="checkbox" name="chk_modulo_registro"
                               id="chk_modulo" value="1"
                            <?= !empty($c['ind_modulo_registro']) ? 'checked' : '' ?>>
                        <div class="config-toggle-item__body">
                            <label class="config-toggle-item__title mb-0" for="chk_modulo">
                                Habilitar módulo de personas (standalone)
                            </label>
                            <span class="config-toggle-item__desc">
                                Si está desactivado, el menú «Personas» (panel y formularios)
                                (aprendiz, instructor, etc.) no estarán disponibles.
                            </span>
                        </div>
                    </div>
                </div>

                <div class="row g-2 mt-2" id="registro-credenciales-wrap"
                     <?= empty($c['ind_modulo_registro']) ? 'hidden' : '' ?>>
                    <div class="col-md-6">
                        <label class="form-label small fw-bold" for="txt_usr_registro">Usuario del login de registro</label>
                        <input type="text" name="txt_usr_registro" id="txt_usr_registro"
                               class="form-control form-control-sm"
                               value="<?= htmlspecialchars($c['usr_registro'] ?? '') ?>"
                               placeholder="usuariocset" autocomplete="off">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label small fw-bold" for="txt_pass_registro">Clave del login de registro (opcional)</label>
                        <input type="password" name="txt_pass_registro" id="txt_pass_registro"
                               class="form-control form-control-sm"
                               placeholder="Dejar vacío para no cambiar" minlength="12" autocomplete="new-password">
                    </div>
                </div>

                <p class="small text-muted mb-0 mt-2 registro-config-help">
                    El acceso al módulo de registro se realiza desde su propio login
                    (<code>src/modulos/registro/login.php</code>). El administrador solo configura este acceso desde aquí.
                </p>
            </div>

            <div class="card-footer registro-config-footer border-0 d-flex flex-wrap align-items-center gap-2 justify-content-end">
                <button type="submit" name="btn_guardar_registro" value="1" class="btn btn-sm fw-bold text-white"
                        style="background:var(--v-oscuro);">
                    <i class="bi bi-save-fill me-1"></i>Guardar configuración
                </button>
            </div>
        </div>
    </div>
</form>

<?php include __DIR__ . '/../../layout/footer.php'; ?>
<?php
$vAdminPersonas = @filemtime(dirname(__DIR__, 3) . '/js/admin-personas-config.js') ?: time();
?>
<script src="<?= htmlspecialchars($smartcset_asset_href) ?>js/admin-personas-config.js?v=<?= (int) $vAdminPersonas ?>"></script>

