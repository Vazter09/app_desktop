<?php
declare(strict_types=1);

require_once __DIR__ . '/init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

if (!usuarioTieneMenu($pdo, (string) $_SESSION['id_usuario'], '0601')) {
    http_response_code(403);
    die('Acceso denegado. No tiene el módulo SIEM asignado.');
}

$kpis         = ['total_intentos_hoy' => 0, 'fallos_hoy' => 0, 'ips_bloqueadas' => 0, 'sesiones_activas' => 0];
$eventos_hora = [];
$top_ips      = [];
$alertas      = [];
$w_mensaje    = '';
$w_tipo_alerta = 'danger';

try {
    $row = $pdo->query("SELECT * FROM fun_siem_dashboard_kpis()")->fetch(PDO::FETCH_ASSOC);
    if ($row) {
        $kpis = $row;
    }

    $eventos_hora = $pdo->query("SELECT * FROM fun_siem_eventos_por_hora()")->fetchAll(PDO::FETCH_ASSOC);
    $top_ips      = $pdo->query("SELECT * FROM fun_siem_top_ips_fallidas()")->fetchAll(PDO::FETCH_ASSOC);
    $alertas      = $pdo->query("SELECT * FROM fun_siem_alertas_recientes()")->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $w_mensaje = ErrorHandler::userMessageFromException($e);
}

$page_title    = 'SIEM — Panel de Control';
$active_menu_id = '0601';
$wnom_usuario  = $_SESSION['nom_usuario'];

$_root   = modulosProjectRoot();
$_css_v  = @filemtime($_root . '/css/siem.css') ?: time();
$extra_stylesheets = '<link rel="stylesheet" href="'
    . htmlspecialchars($smartcset_asset_href) . 'css/siem.css?v=' . (int) $_css_v . '">';

// Preparar datos para Chart.js
$chart_labels  = [];
$chart_exitosos = [];
$chart_fallidos = [];
for ($h = 0; $h < 24; $h++) {
    $chart_labels[] = str_pad((string) $h, 2, '0', STR_PAD_LEFT) . ':00';
    $chart_exitosos[] = 0;
    $chart_fallidos[] = 0;
}
foreach ($eventos_hora as $ev) {
    $h = (int) $ev['hora'];
    $chart_exitosos[$h] = (int) $ev['exitosos'];
    $chart_fallidos[$h] = (int) $ev['fallidos'];
}

include modulosLayout('layout/head.php');
include modulosLayout('layout/sidebar.php');
include modulosLayout('layout/topbar.php');
?>

<?php if ($w_mensaje !== ''): ?>
    <?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>
<?php endif; ?>

<div class="container-fluid py-3 px-3">

    <!-- KPIs -->
    <div class="row g-3 mb-3">

        <div class="col-6 col-md-3">
            <div class="siem-kpi-card p-3">
                <div class="d-flex align-items-center gap-2 mb-1">
                    <span class="siem-kpi-icon text-info"><i class="bi bi-shield-check"></i></span>
                    <span class="siem-kpi-label">Intentos hoy</span>
                </div>
                <div class="siem-kpi-value"><?= (int) $kpis['total_intentos_hoy'] ?></div>
            </div>
        </div>

        <div class="col-6 col-md-3">
            <div class="siem-kpi-card p-3">
                <div class="d-flex align-items-center gap-2 mb-1">
                    <span class="siem-kpi-icon text-danger"><i class="bi bi-x-circle"></i></span>
                    <span class="siem-kpi-label">Fallos hoy</span>
                </div>
                <div class="siem-kpi-value text-danger"><?= (int) $kpis['fallos_hoy'] ?></div>
            </div>
        </div>

        <div class="col-6 col-md-3">
            <div class="siem-kpi-card p-3">
                <div class="d-flex align-items-center gap-2 mb-1">
                    <span class="siem-kpi-icon text-warning"><i class="bi bi-shield-exclamation"></i></span>
                    <span class="siem-kpi-label">IPs bloqueadas</span>
                </div>
                <div class="siem-kpi-value text-warning"><?= (int) $kpis['ips_bloqueadas'] ?></div>
            </div>
        </div>

        <div class="col-6 col-md-3">
            <div class="siem-kpi-card p-3">
                <div class="d-flex align-items-center gap-2 mb-1">
                    <span class="siem-kpi-icon text-success"><i class="bi bi-people"></i></span>
                    <span class="siem-kpi-label">Sesiones activas</span>
                </div>
                <div class="siem-kpi-value text-success"><?= (int) $kpis['sesiones_activas'] ?></div>
            </div>
        </div>

    </div><!-- /KPIs -->

    <!-- Gráfica + Alertas -->
    <div class="row g-3 mb-3">

        <div class="col-12 col-lg-7">
            <div class="siem-kpi-card p-3 h-100">
                <div class="siem-section-header">
                    <i class="bi bi-graph-up-arrow text-info"></i>
                    <span class="siem-section-title">Eventos de autenticación — últimas 24 h</span>
                </div>
                <div class="siem-chart-wrap">
                    <canvas id="siem-chart-eventos"></canvas>
                </div>
            </div>
        </div>

        <div class="col-12 col-lg-5">
            <div class="siem-kpi-card p-3 h-100">
                <div class="siem-section-header">
                    <i class="bi bi-exclamation-triangle text-warning"></i>
                    <span class="siem-section-title">Alertas recientes</span>
                </div>
                <?php if (empty($alertas)): ?>
                    <p class="text-muted small mb-0"><i class="bi bi-check-circle me-1 text-success"></i>Sin alertas activas.</p>
                <?php else: ?>
                    <?php foreach ($alertas as $al): ?>
                        <div class="siem-alert-item <?= htmlspecialchars($al['severidad']) ?>">
                            <div class="siem-alert-desc">
                                <?php if ($al['severidad'] === 'danger'): ?>
                                    <i class="bi bi-shield-x text-danger me-1"></i>
                                <?php else: ?>
                                    <i class="bi bi-exclamation-circle text-warning me-1"></i>
                                <?php endif; ?>
                                <?= htmlspecialchars($al['descripcion']) ?>
                            </div>
                            <div class="siem-alert-meta mt-1">
                                <?= htmlspecialchars($al['ip_cliente']) ?>
                                &nbsp;·&nbsp;
                                <?= date('H:i:s', strtotime($al['fec_evento'])) ?>
                            </div>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>

    </div><!-- /Gráfica + Alertas -->

    <!-- Top IPs -->
    <div class="row g-3">
        <div class="col-12">
            <div class="siem-kpi-card p-3">
                <div class="siem-section-header">
                    <i class="bi bi-diagram-3 text-danger"></i>
                    <span class="siem-section-title">Top IPs con más fallos hoy</span>
                </div>
                <?php if (empty($top_ips)): ?>
                    <p class="text-muted small mb-0"><i class="bi bi-check-circle me-1 text-success"></i>Sin actividad sospechosa registrada hoy.</p>
                <?php else: ?>
                    <div class="table-responsive">
                        <table class="table table-hover table-siem mb-0">
                            <thead>
                                <tr>
                                    <th>IP</th>
                                    <th class="text-center">Fallos</th>
                                    <th>Último intento</th>
                                    <th class="text-center">Estado</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($top_ips as $ip): ?>
                                    <tr>
                                        <td class="font-monospace"><?= htmlspecialchars($ip['ip_cliente']) ?></td>
                                        <td class="text-center fw-bold text-danger"><?= (int) $ip['total_fallos'] ?></td>
                                        <td class="font-monospace"><?= date('H:i:s', strtotime($ip['ultimo_fallo'])) ?></td>
                                        <td class="text-center">
                                            <?php if ($ip['bloqueada']): ?>
                                                <span class="badge badge-bloqueada"><i class="bi bi-shield-x me-1"></i>Bloqueada</span>
                                            <?php else: ?>
                                                <span class="badge badge-activa-ip"><i class="bi bi-exclamation me-1"></i>Activa</span>
                                            <?php endif; ?>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>

</div><!-- /container -->

<?php
$chart_labels_json   = json_encode($chart_labels,   JSON_UNESCAPED_UNICODE);
$chart_exitosos_json = json_encode($chart_exitosos, JSON_UNESCAPED_UNICODE);
$chart_fallidos_json = json_encode($chart_fallidos, JSON_UNESCAPED_UNICODE);

$extra_js = <<<HTML
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
(function () {
    'use strict';
    var labels    = {$chart_labels_json};
    var exitosos  = {$chart_exitosos_json};
    var fallidos  = {$chart_fallidos_json};

    var ctx = document.getElementById('siem-chart-eventos').getContext('2d');
    new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [
                {
                    label: 'Exitosos',
                    data: exitosos,
                    borderColor: '#198754',
                    backgroundColor: 'rgba(25,135,84,0.12)',
                    borderWidth: 2,
                    pointRadius: 3,
                    fill: true,
                    tension: 0.3
                },
                {
                    label: 'Fallidos',
                    data: fallidos,
                    borderColor: '#dc3545',
                    backgroundColor: 'rgba(220,53,69,0.12)',
                    borderWidth: 2,
                    pointRadius: 3,
                    fill: true,
                    tension: 0.3
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    labels: { color: '#adb5bd', font: { size: 11 } }
                }
            },
            scales: {
                x: {
                    ticks: { color: '#6c757d', font: { size: 10 }, maxTicksLimit: 12 },
                    grid: { color: 'rgba(255,255,255,0.05)' }
                },
                y: {
                    beginAtZero: true,
                    ticks: { color: '#6c757d', font: { size: 10 }, precision: 0 },
                    grid: { color: 'rgba(255,255,255,0.05)' }
                }
            }
        }
    });
}());
</script>
HTML;

include modulosLayout('layout/footer.php');
?>
