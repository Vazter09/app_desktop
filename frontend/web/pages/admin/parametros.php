<?php
require_once dirname(__DIR__, 2) . '/init.php';
require_once dirname(__DIR__, 4) . '/backend/core/PmtrosGralesDefaults.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ../../index.php');
    exit();
}

if (!usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])) {
    http_response_code(403);
    die('Acceso denegado. Solo administradores pueden modificar los parámetros generales.');
}

$w_mensaje = '';
$w_tipo_alerta = 'success';

$pmtros = [];
if ($stmt_get_pmtros instanceof PDOStatement) {
    try {
        $stmt_get_pmtros->execute();
        $pmtros = $stmt_get_pmtros->fetch(PDO::FETCH_ASSOC) ?: [];
    } catch (PDOException) {
        $pmtros = [];
    }
}

$p = $pmtros;
$hasPmtros = $pmtros !== [];
$page_title = 'Config. parámetros';
$active_menu_id = '0403';
$wnom_usuario = $_SESSION['nom_usuario'] ?? '';

include smartcsetLayoutPath('head.php');
include smartcsetLayoutPath('sidebar.php');
include smartcsetLayoutPath('topbar.php');
?>

<?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

<?php if (!$hasPmtros): ?>
<div class="alert alert-warning" role="alert">
    No hay parámetros configurados. Ejecute el seed o contacte al administrador de BD.
</div>
<?php else: ?>

<form method="POST" id="form-config-pmtros" class="row g-3" action="#">
    <input type="hidden" name="txt_id_centro" value="<?= htmlspecialchars((string) ($p['id_centro'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">

    <div class="col-12">
        <div class="card shadow-sm border-0 registro-config-card">
            <div class="card-header bg-corporativo py-2">
                <strong style="font-size:0.95rem;">
                    <i class="bi bi-building me-2"></i>Centro de formación
                </strong>
            </div>
            <div class="card-body registro-config-body">
                <div class="row g-2">
                    <div class="col-md-4">
                        <label class="form-label small fw-bold" for="txt_id_centro_display">Código centro</label>
                        <input type="text" id="txt_id_centro_display" class="form-control form-control-sm"
                               value="<?= htmlspecialchars((string) ($p['id_centro'] ?? ''), ENT_QUOTES, 'UTF-8') ?>"
                               readonly disabled>
                    </div>
                    <div class="col-md-8">
                        <label class="form-label small fw-bold" for="txt_nom_centro_display">Nombre del centro</label>
                        <input type="text" id="txt_nom_centro_display" class="form-control form-control-sm"
                               value="<?= htmlspecialchars((string) ($p['nom_centro'] ?? ''), ENT_QUOTES, 'UTF-8') ?>"
                               readonly disabled>
                    </div>
                    <div class="col-md-8">
                        <label class="form-label small fw-bold" for="txt_dir_centro">Dirección del centro</label>
                        <input type="text" name="txt_dir_centro" id="txt_dir_centro"
                               class="form-control form-control-sm" required minlength="10" maxlength="90"
                               value="<?= htmlspecialchars((string) ($p['dir_centro'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-bold" for="txt_tel_centro">Teléfono del centro</label>
                        <input type="number" name="txt_tel_centro" id="txt_tel_centro"
                               class="form-control form-control-sm" required min="1" max="9999999999"
                               value="<?= htmlspecialchars((string) ($p['tel_centro'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-12">
        <div class="card shadow-sm border-0 registro-config-card">
            <div class="card-header bg-corporativo py-2">
                <strong style="font-size:0.95rem;">
                    <i class="bi bi-calendar3 me-2"></i>Período académico
                </strong>
            </div>
            <div class="card-body registro-config-body">
                <div class="row g-2">
                    <div class="col-md-6">
                        <label class="form-label small fw-bold" for="num_ano_academico">Año académico</label>
                        <input type="number" name="num_ano_academico" id="num_ano_academico"
                               class="form-control form-control-sm" required min="2000" max="2100"
                               value="<?= htmlspecialchars((string) ($p['ano_academico'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label small fw-bold" for="num_mes_academico">Mes académico</label>
                        <input type="number" name="num_mes_academico" id="num_mes_academico"
                               class="form-control form-control-sm" required min="1" max="12"
                               value="<?= htmlspecialchars((string) ($p['mes_academico'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-12">
        <div class="card shadow-sm border-0 registro-config-card">
            <div class="card-header bg-corporativo py-2">
                <strong style="font-size:0.95rem;">
                    <i class="bi bi-sliders me-2"></i>Reglas operativas
                </strong>
            </div>
            <div class="card-body registro-config-body">
                <div class="row g-2">
                    <div class="col-md-4">
                        <label class="form-label small fw-bold" for="num_nota_minima_rap">Nota mínima RAP</label>
                        <input type="number" name="num_nota_minima_rap" id="num_nota_minima_rap"
                               class="form-control form-control-sm" required min="0" max="100"
                               value="<?= htmlspecialchars((string) ($p['val_nota_minima_rap'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-bold" for="num_horas_instructor">Horas mes instructor</label>
                        <input type="number" name="num_horas_instructor" id="num_horas_instructor"
                               class="form-control form-control-sm" required min="0" max="200"
                               value="<?= htmlspecialchars((string) ($p['num_horas_instructor'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-bold" for="num_porcent_icfes_raps">% mín. RAPs ICFES</label>
                        <input type="number" name="num_porcent_icfes_raps" id="num_porcent_icfes_raps"
                               class="form-control form-control-sm" required min="0" max="100"
                               value="<?= htmlspecialchars((string) ($p['val_porcent_icfes_raps'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-bold" for="num_tiempo_gracia_aprendiz">Gracia aprendiz (min)</label>
                        <input type="number" name="num_tiempo_gracia_aprendiz" id="num_tiempo_gracia_aprendiz"
                               class="form-control form-control-sm" required min="0" max="99"
                               value="<?= htmlspecialchars((string) ($p['val_tiempo_gracia_aprendiz'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-bold" for="num_tiempo_gracia_instru">Gracia instructor (min)</label>
                        <input type="number" name="num_tiempo_gracia_instru" id="num_tiempo_gracia_instru"
                               class="form-control form-control-sm" required min="0" max="99"
                               value="<?= htmlspecialchars((string) ($p['val_tiempo_gracia_instru'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-bold" for="num_max_llamados_aprendiz">Máx. llamados atención</label>
                        <input type="number" name="num_max_llamados_aprendiz" id="num_max_llamados_aprendiz"
                               class="form-control form-control-sm" required min="1" max="9"
                               value="<?= htmlspecialchars((string) ($p['val_max_llamados_aprendiz'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-12">
        <div class="card shadow-sm border-0 registro-config-card">
            <div class="card-header bg-corporativo py-2 d-flex flex-wrap justify-content-between align-items-center gap-2">
                <strong style="font-size:0.95rem;">
                    <i class="bi bi-person-badge me-2"></i>Administrador del centro
                </strong>
                <button type="submit" name="btn_restaurar_pmtros" value="1"
                        class="btn btn-sm btn-light fw-bold"
                        data-smart-confirm
                        data-smart-confirm-title="Restaurar parámetros"
                        data-smart-confirm-message="¿Restaurar los parámetros generales a los valores por defecto?"
                        data-smart-confirm-ok="Restaurar"
                        data-smart-confirm-variant="warning">
                    <i class="bi bi-arrow-counterclockwise me-1"></i>Restaurar
                </button>
            </div>
            <div class="card-body registro-config-body">
                <div class="row g-2">
                    <div class="col-md-8">
                        <label class="form-label small fw-bold" for="txt_nom_administrador">Nombre del administrador</label>
                        <input type="text" name="txt_nom_administrador" id="txt_nom_administrador"
                               class="form-control form-control-sm" required minlength="3" maxlength="80"
                               value="<?= htmlspecialchars((string) ($p['nom_administrador'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-bold" for="txt_tel_administrador">Teléfono del administrador</label>
                        <input type="number" name="txt_tel_administrador" id="txt_tel_administrador"
                               class="form-control form-control-sm" required min="1" max="9999999999"
                               value="<?= htmlspecialchars((string) ($p['tel_administrador'] ?? ''), ENT_QUOTES, 'UTF-8') ?>">
                    </div>
                </div>
            </div>
            <div class="card-footer registro-config-footer border-0 d-flex flex-wrap align-items-center gap-2 justify-content-end">
                <button type="submit" name="btn_guardar_pmtros" value="1" class="btn btn-sm fw-bold text-white"
                        style="background:var(--v-oscuro);">
                    <i class="bi bi-save-fill me-1"></i>Guardar parámetros
                </button>
            </div>
        </div>
    </div>
</form>

<?php endif; ?>

<?php
$_ar = dirname(__DIR__, 3) . '/public/assets';
include smartcsetLayoutPath('footer.php');
?>
<?php if ($hasPmtros): ?>
<script src="<?= htmlspecialchars(smartcsetAsset('js/services/http-client.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/services/http-client.js') ?: time()) ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/services/admin-router.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/services/admin-router.js') ?: time()) ?>"></script>
<script src="<?= htmlspecialchars(smartcsetAsset('js/core/admin-parametros-config.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/core/admin-parametros-config.js') ?: time()) ?>"></script>
<?php endif; ?>
