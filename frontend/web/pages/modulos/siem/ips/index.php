<?php
declare(strict_types=1);

require_once __DIR__ . '/../init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

if (!usuarioTieneMenu($pdo, (string) $_SESSION['id_usuario'], '0604')) {
    http_response_code(403);
    die('Acceso denegado. No tiene el módulo SIEM asignado.');
}

$max_intentos = defined('LOGIN_MAX_INTENTOS')   ? (int) LOGIN_MAX_INTENTOS   : 5;
$ventana_min  = defined('LOGIN_VENTANA_MINUTOS') ? (int) LOGIN_VENTANA_MINUTOS : 15;

$ips           = [];
$w_mensaje     = '';
$w_tipo_alerta = 'success';

if (!empty($_SESSION['flash_msg'])) {
    $w_mensaje     = $_SESSION['flash_msg'];
    $w_tipo_alerta = $_SESSION['flash_tipo'] ?? 'success';
    unset($_SESSION['flash_msg'], $_SESSION['flash_tipo']);
}

try {
    $stmt = $pdo->prepare("SELECT * FROM fun_siem_ips_bloqueadas(?::INT, ?::INT)");
    $stmt->execute([$max_intentos, $ventana_min]);
    $ips = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $w_mensaje     = ErrorHandler::userMessageFromException($e);
    $w_tipo_alerta = 'danger';
}

$bloqueadas_activas = count(array_filter($ips, fn($r) => !$r['expirada']));

$page_title     = 'SIEM — IPs Bloqueadas';
$active_menu_id = '0604';
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

    <?php if ($bloqueadas_activas > 0): ?>
        <div class="alert alert-warning alert-sm d-flex align-items-center gap-2 mb-3 py-2">
            <i class="bi bi-exclamation-triangle-fill"></i>
            <span>
                Las IPs se desbloquean automáticamente al vencer la ventana de <?= $ventana_min ?> minutos.
                El desbloqueo manual elimina los intentos fallidos recientes de esa IP.
            </span>
        </div>
    <?php endif; ?>

    <div class="siem-kpi-card p-3">
        <div class="siem-section-header">
            <i class="bi bi-shield-x text-danger"></i>
            <span class="siem-section-title">IPs en cuarentena por rate limiting</span>
            <?php if ($bloqueadas_activas > 0): ?>
                <span class="ms-auto badge bg-danger"><?= $bloqueadas_activas ?> bloqueada<?= $bloqueadas_activas > 1 ? 's' : '' ?></span>
            <?php else: ?>
                <span class="ms-auto badge bg-success">Sin bloqueos activos</span>
            <?php endif; ?>
        </div>

        <p class="small text-muted mb-2">
            Umbral: <strong><?= $max_intentos ?> fallos</strong> en <strong><?= $ventana_min ?> minutos</strong>
            (configurado en <code>.env</code>).
        </p>

        <div class="table-responsive">
            <table class="table table-hover table-siem mb-0" id="tbl-ips">
                <thead>
                    <tr>
                        <th>IP Cliente</th>
                        <th class="text-center">Intentos fallidos</th>
                        <th>Último intento</th>
                        <th class="text-center">Expira en</th>
                        <th class="text-center">Estado</th>
                        <th class="text-center">Acción</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($ips)): ?>
                        <tr>
                            <td colspan="6" class="text-center text-muted py-4">
                                <i class="bi bi-check-circle me-1 text-success"></i>
                                Sin IPs bloqueadas actualmente.
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($ips as $ip): ?>
                            <tr>
                                <td class="font-monospace fw-bold"><?= htmlspecialchars($ip['ip_cliente']) ?></td>
                                <td class="text-center fw-bold text-danger"><?= (int) $ip['total_intentos'] ?></td>
                                <td class="font-monospace"><?= date('H:i:s', strtotime($ip['ultimo_intento'])) ?></td>
                                <td class="text-center font-monospace">
                                    <?php if ($ip['expirada']): ?>
                                        <span class="text-muted">Expirada</span>
                                    <?php else: ?>
                                        <span class="text-warning"><?= (int) $ip['minutos_expira'] ?> min</span>
                                    <?php endif; ?>
                                </td>
                                <td class="text-center">
                                    <?php if ($ip['expirada']): ?>
                                        <span class="badge badge-expirada">Expirada</span>
                                    <?php else: ?>
                                        <span class="badge badge-bloqueada"><i class="bi bi-shield-x me-1"></i>Bloqueada</span>
                                    <?php endif; ?>
                                </td>
                                <td class="text-center">
                                    <button type="button"
                                            class="btn btn-sm btn-outline-warning btn-desbloquear"
                                            data-ip="<?= htmlspecialchars($ip['ip_cliente']) ?>"
                                            title="Desbloquear IP">
                                        <i class="bi bi-arrow-counterclockwise me-1"></i>Desbloquear
                                    </button>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Modal confirmación desbloqueo -->
<div class="modal fade" id="modal-desbloquear" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-sm">
        <div class="modal-content">
            <div class="modal-header border-secondary">
                <h6 class="modal-title">
                    <i class="bi bi-arrow-counterclockwise text-warning me-1"></i>
                    Desbloquear IP
                </h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body small">
                ¿Desbloquear <strong id="modal-ip-texto" class="font-monospace"></strong>?
                Se eliminarán sus intentos fallidos recientes y podrá volver a intentar el login.
            </div>
            <div class="modal-footer border-secondary">
                <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                <button type="button" class="btn btn-sm btn-warning text-dark" id="btn-confirmar-desbloqueo">
                    <i class="bi bi-arrow-counterclockwise me-1"></i>Sí, desbloquear
                </button>
            </div>
        </div>
    </div>
</div>

<?php
$url_desbloquear = smartcsetUrl('/routers/siem/v1/desbloquear_ip.php');
$extra_js = <<<HTML
<script>
(function () {
    'use strict';
    var modal  = new bootstrap.Modal(document.getElementById('modal-desbloquear'));
    var ipSel  = '';
    var urlDes = '{$url_desbloquear}';

    document.getElementById('tbl-ips').addEventListener('click', function (e) {
        var btn = e.target.closest('.btn-desbloquear');
        if (!btn) return;
        ipSel = btn.dataset.ip;
        document.getElementById('modal-ip-texto').textContent = ipSel;
        modal.show();
    });

    document.getElementById('btn-confirmar-desbloqueo').addEventListener('click', function () {
        this.disabled = true;
        SmartcsetHttp.post(urlDes, { ip_cliente: ipSel })
            .then(function (res) {
                modal.hide();
                if (res.ok) {
                    window.location.reload();
                } else {
                    SmartcsetToast.show(res.error || 'No se pudo desbloquear la IP.', 'danger');
                }
            })
            .catch(function () {
                SmartcsetToast.show('Error de red.', 'danger');
            })
            .finally(function () {
                document.getElementById('btn-confirmar-desbloqueo').disabled = false;
            });
    });
}());
</script>
HTML;

include modulosLayout('layout/footer.php');
?>
