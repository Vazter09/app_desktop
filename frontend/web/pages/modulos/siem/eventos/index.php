<?php
declare(strict_types=1);

require_once __DIR__ . '/../init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

if (!usuarioTieneMenu($pdo, (string) $_SESSION['id_usuario'], '0602')) {
    http_response_code(403);
    die('Acceso denegado. No tiene el módulo SIEM asignado.');
}

$por_pagina  = 50;
$pagina      = max(1, (int) ($_GET['p'] ?? 1));
$offset      = ($pagina - 1) * $por_pagina;

$f_ip        = trim($_GET['ip']     ?? '');
$f_usuario   = trim($_GET['usr']    ?? '');
$f_desde     = trim($_GET['desde']  ?? '');
$f_hasta     = trim($_GET['hasta']  ?? '');
$f_resultado = trim($_GET['res']    ?? '');

$eventos     = [];
$total_filas = 0;
$w_mensaje   = '';
$w_tipo_alerta = 'danger';

try {
    $stmt = $pdo->prepare(
        "SELECT * FROM fun_siem_list_eventos(
            ?::TEXT, ?::TEXT, ?::DATE, ?::DATE, ?::TEXT, ?::INT, ?::INT
        )"
    );
    $stmt->execute([
        $f_ip       !== '' ? $f_ip       : null,
        $f_usuario  !== '' ? $f_usuario  : null,
        $f_desde    !== '' ? $f_desde    : null,
        $f_hasta    !== '' ? $f_hasta    : null,
        $f_resultado !== '' ? $f_resultado : null,
        $por_pagina,
        $offset,
    ]);
    $eventos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $total_filas = !empty($eventos) ? (int) $eventos[0]['total_filas'] : 0;
} catch (PDOException $e) {
    $w_mensaje = ErrorHandler::userMessageFromException($e);
}

$total_paginas = $total_filas > 0 ? (int) ceil($total_filas / $por_pagina) : 1;

$page_title     = 'SIEM — Eventos de Autenticación';
$active_menu_id = '0602';
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

    <!-- Filtros -->
    <div class="siem-kpi-card p-3 mb-3">
        <div class="siem-section-header mb-2">
            <i class="bi bi-funnel text-info"></i>
            <span class="siem-section-title">Filtros</span>
        </div>
        <form method="GET" class="siem-filtros" autocomplete="off">
            <div class="row g-2 align-items-end">
                <div class="col-6 col-md-2">
                    <label class="form-label small mb-1">IP cliente</label>
                    <input type="text" name="ip" value="<?= htmlspecialchars($f_ip) ?>"
                           class="form-control form-control-sm" placeholder="192.168.x.x">
                </div>
                <div class="col-6 col-md-2">
                    <label class="form-label small mb-1">Usuario</label>
                    <input type="text" name="usr" value="<?= htmlspecialchars($f_usuario) ?>"
                           class="form-control form-control-sm" placeholder="admin.smart">
                </div>
                <div class="col-6 col-md-2">
                    <label class="form-label small mb-1">Desde</label>
                    <input type="date" name="desde" value="<?= htmlspecialchars($f_desde) ?>"
                           class="form-control form-control-sm">
                </div>
                <div class="col-6 col-md-2">
                    <label class="form-label small mb-1">Hasta</label>
                    <input type="date" name="hasta" value="<?= htmlspecialchars($f_hasta) ?>"
                           class="form-control form-control-sm">
                </div>
                <div class="col-6 col-md-2">
                    <label class="form-label small mb-1">Resultado</label>
                    <select name="res" class="form-select form-select-sm">
                        <option value="">Todos</option>
                        <option value="true"  <?= $f_resultado === 'true'  ? 'selected' : '' ?>>Exitoso</option>
                        <option value="false" <?= $f_resultado === 'false' ? 'selected' : '' ?>>Fallido</option>
                    </select>
                </div>
                <div class="col-6 col-md-2 d-flex gap-2">
                    <button type="submit" class="btn btn-sm btn-outline-success w-100">
                        <i class="bi bi-search me-1"></i>Filtrar
                    </button>
                    <a href="<?= htmlspecialchars(smartcsetUrl('/pages/modulos/siem/eventos/index.php')) ?>"
                       class="btn btn-sm btn-outline-secondary w-100">
                        <i class="bi bi-x"></i>
                    </a>
                </div>
            </div>
        </form>
    </div>

    <!-- Tabla -->
    <div class="siem-kpi-card p-3">
        <div class="siem-section-header">
            <i class="bi bi-key text-warning"></i>
            <span class="siem-section-title">Eventos de autenticación</span>
            <span class="ms-auto badge bg-secondary"><?= number_format($total_filas) ?> registros</span>
        </div>

        <div class="table-responsive">
            <table class="table table-hover table-siem mb-0">
                <thead>
                    <tr>
                        <th>Fecha / Hora</th>
                        <th>IP Cliente</th>
                        <th>Usuario</th>
                        <th class="text-center">Resultado</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($eventos)): ?>
                        <tr>
                            <td colspan="4" class="text-center text-muted py-4">
                                <i class="bi bi-inbox me-1"></i>Sin eventos para los filtros aplicados.
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($eventos as $ev): ?>
                            <tr>
                                <td class="font-monospace">
                                    <?= date('Y-m-d H:i:s', strtotime($ev['fec_intento'])) ?>
                                </td>
                                <td class="font-monospace"><?= htmlspecialchars($ev['ip_cliente']) ?></td>
                                <td><?= htmlspecialchars($ev['id_usuario'] ?? '—') ?></td>
                                <td class="text-center">
                                    <?php if ($ev['ind_exitoso']): ?>
                                        <span class="badge bg-success"><i class="bi bi-check-lg me-1"></i>Exitoso</span>
                                    <?php else: ?>
                                        <span class="badge bg-danger"><i class="bi bi-x-lg me-1"></i>Fallido</span>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>

        <!-- Paginación -->
        <?php if ($total_paginas > 1): ?>
            <nav class="mt-3">
                <ul class="pagination pagination-sm mb-0 justify-content-center">
                    <?php
                    $base_url = smartcsetUrl('/pages/modulos/siem/eventos/index.php');
                    $params = array_filter([
                        'ip' => $f_ip, 'usr' => $f_usuario,
                        'desde' => $f_desde, 'hasta' => $f_hasta, 'res' => $f_resultado
                    ]);
                    function siemPageUrl(string $base, array $params, int $p): string
                    {
                        return $base . '?' . http_build_query(array_merge($params, ['p' => $p]));
                    }
                    ?>
                    <li class="page-item <?= $pagina <= 1 ? 'disabled' : '' ?>">
                        <a class="page-link" href="<?= siemPageUrl($base_url, $params, $pagina - 1) ?>">
                            <i class="bi bi-chevron-left"></i>
                        </a>
                    </li>
                    <li class="page-item disabled">
                        <span class="page-link">
                            Página <?= $pagina ?> de <?= $total_paginas ?>
                        </span>
                    </li>
                    <li class="page-item <?= $pagina >= $total_paginas ? 'disabled' : '' ?>">
                        <a class="page-link" href="<?= siemPageUrl($base_url, $params, $pagina + 1) ?>">
                            <i class="bi bi-chevron-right"></i>
                        </a>
                    </li>
                </ul>
            </nav>
        <?php endif; ?>

    </div>
</div>

<?php include modulosLayout('layout/footer.php'); ?>
