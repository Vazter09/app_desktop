<?php
require_once dirname(__DIR__, 3) . '/init.php';
require_once dirname(__DIR__, 5) . '/backend/core/ConfigSistemaDefaults.php';

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

$c = $config;
$page_title = 'Config. módulo personas';
$active_menu_id = '0402';
$wnom_usuario = $_SESSION['nom_usuario'] ?? '';

include smartcsetLayoutPath('head.php');
include smartcsetLayoutPath('sidebar.php');
include smartcsetLayoutPath('topbar.php');
?>

<?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

<form method="POST" id="form-config-personas" class="row g-3" action="#">
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
                    (<code>/pages/modulos/registro/login.php</code>). El administrador solo configura este acceso desde aquí.
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

<?php
$_ar = dirname(__DIR__, 4) . '/public/assets';
include smartcsetLayoutPath('footer.php');
?>
<script src="<?= htmlspecialchars(smartcsetAsset('js/services/http-client.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/services/http-client.js') ?: time()) ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/services/admin-router.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/services/admin-router.js') ?: time()) ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/core/admin-personas-config.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/core/admin-personas-config.js') ?: time()) ?>"></script>

