<?php
declare(strict_types=1);

require_once __DIR__ . '/../init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

if (!usuarioTieneMenu($pdo, (string) $_SESSION['id_usuario'], '21103')) {
    http_response_code(403);
    die('Acceso denegado. No tiene el módulo SIEM asignado.');
}

$sesiones      = [];
$w_mensaje     = '';
$w_tipo_alerta = 'success';

if (!empty($_SESSION['flash_msg'])) {
    $w_mensaje     = $_SESSION['flash_msg'];
    $w_tipo_alerta = $_SESSION['flash_tipo'] ?? 'success';
    unset($_SESSION['flash_msg'], $_SESSION['flash_tipo']);
}

try {
    $sesiones = $pdo->query("SELECT * FROM fun_siem_sesiones_activas()")->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $w_mensaje     = ErrorHandler::userMessageFromException($e);
    $w_tipo_alerta = 'danger';
}

$page_title     = 'SIEM — Sesiones Activas';
$active_menu_id = '21103';
$wnom_usuario   = $_SESSION['nom_usuario'];

$_root  = modulosProjectRoot();
$_css_v = @filemtime($_root . '/css/siem.css') ?: time();
$extra_stylesheets = '<link rel="stylesheet" href="'
    . htmlspecialchars($smartcset_asset_href) . 'css/siem.css?v=' . (int) $_css_v . '">';

include modulosLayout('layout/head.php');
include modulosLayout('layout/sidebar.php');
include modulosLayout('layout/topbar.php');
?>

<?php if ($w_mensaje !== ''): ?>
    <?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>
<?php endif; ?>

<div class="container-fluid py-3 px-3">
    <div class="siem-kpi-card p-3">
        <div class="siem-section-header">
            <i class="bi bi-people text-success"></i>
            <span class="siem-section-title">Sesiones activas</span>
            <span class="ms-auto badge bg-success"><?= count($sesiones) ?> activas</span>
        </div>

        <div class="table-responsive">
            <table class="table table-hover table-siem mb-0" id="tbl-sesiones">
                <thead>
                    <tr>
                        <th>Usuario</th>
                        <th>IP</th>
                        <th>Inicio sesión</th>
                        <th class="text-center">Duración</th>
                        <th class="text-center">Última actividad</th>
                        <th class="text-center">Acción</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($sesiones)): ?>
                        <tr>
                            <td colspan="6" class="text-center text-muted py-4">
                                <i class="bi bi-inbox me-1"></i>No hay sesiones activas.
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($sesiones as $s):
                            $min    = (int) $s['minutos_activo'];
                            $duracion = $min >= 60
                                ? floor($min / 60) . 'h ' . ($min % 60) . 'm'
                                : $min . ' min';
                            $propia = ($s['id_usuario'] === $_SESSION['id_usuario']);
                        ?>
                            <tr>
                                <td>
                                    <i class="bi bi-person-circle me-1 text-muted"></i>
                                    <?= htmlspecialchars($s['nom_usuario']) ?>
                                    <small class="text-muted font-monospace d-block"><?= htmlspecialchars($s['id_usuario']) ?></small>
                                </td>
                                <td class="font-monospace"><?= htmlspecialchars($s['ip_cliente'] ?? '—') ?></td>
                                <td class="font-monospace"><?= date('H:i:s', strtotime($s['fec_ingreso'])) ?></td>
                                <td class="text-center">
                                    <?php
                                    $badge = 'bg-success';
                                    if ($min > 60)  $badge = 'bg-warning text-dark';
                                    if ($min > 120) $badge = 'bg-danger';
                                    ?>
                                    <span class="badge <?= $badge ?>"><?= htmlspecialchars($duracion) ?></span>
                                </td>
                                <td class="text-center font-monospace small">
                                    <?= $s['fec_actividad'] ? date('H:i:s', strtotime($s['fec_actividad'])) : '—' ?>
                                </td>
                                <td class="text-center">
                                    <?php if ($propia): ?>
                                        <span class="badge bg-secondary">Sesión actual</span>
                                    <?php else: ?>
                                        <button type="button"
                                                class="btn btn-sm btn-outline-danger btn-forzar-cierre"
                                                data-id-sesion="<?= htmlspecialchars($s['id_sesion']) ?>"
                                                data-usuario="<?= htmlspecialchars($s['nom_usuario']) ?>"
                                                title="Forzar cierre">
                                            <i class="bi bi-x-circle me-1"></i>Forzar cierre
                                        </button>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Modal confirmación cierre forzado -->
<div class="modal fade" id="modal-forzar-cierre" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-sm">
        <div class="modal-content">
            <div class="modal-header border-secondary">
                <h6 class="modal-title">
                    <i class="bi bi-exclamation-triangle text-warning me-1"></i>
                    Forzar cierre de sesión
                </h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body small">
                ¿Cerrar sesión de <strong id="modal-nombre-usuario"></strong>?
                El usuario será desconectado inmediatamente.
            </div>
            <div class="modal-footer border-secondary">
                <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                <button type="button" class="btn btn-sm btn-danger" id="btn-confirmar-cierre">
                    <i class="bi bi-x-circle me-1"></i>Sí, cerrar
                </button>
            </div>
        </div>
    </div>
</div>

<?php
$url_forzar = smartcsetUrl('/routers/siem/v1/forzar_sesion.php');
$extra_js = <<<HTML
<script>
(function () {
    'use strict';
    var modal       = new bootstrap.Modal(document.getElementById('modal-forzar-cierre'));
    var idSesion    = '';
    var urlForzar   = '{$url_forzar}';

    document.getElementById('tbl-sesiones').addEventListener('click', function (e) {
        var btn = e.target.closest('.btn-forzar-cierre');
        if (!btn) return;
        idSesion = btn.dataset.idSesion;
        document.getElementById('modal-nombre-usuario').textContent = btn.dataset.usuario;
        modal.show();
    });

    document.getElementById('btn-confirmar-cierre').addEventListener('click', function () {
        this.disabled = true;
        SmartcsetHttp.post(urlForzar, { id_sesion: idSesion })
            .then(function (res) {
                modal.hide();
                if (res.ok) {
                    window.location.reload();
                } else {
                    SmartcsetToast.show(res.error || 'No se pudo cerrar la sesión.', 'danger');
                }
            })
            .catch(function () {
                SmartcsetToast.show('Error de red.', 'danger');
            })
            .finally(function () {
                document.getElementById('btn-confirmar-cierre').disabled = false;
            });
    });
}());
</script>
HTML;

include modulosLayout('layout/footer.php');
?>
