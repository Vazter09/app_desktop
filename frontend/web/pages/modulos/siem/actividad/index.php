<?php
declare(strict_types=1);

require_once __DIR__ . '/../init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

if (!usuarioTieneMenu($pdo, (string) $_SESSION['id_usuario'], '0605')) {
    http_response_code(403);
    die('Acceso denegado. No tiene el módulo SIEM asignado.');
}

$por_pagina  = 50;
$pagina      = max(1, (int) ($_GET['p'] ?? 1));
$offset      = ($pagina - 1) * $por_pagina;

$f_desde     = trim($_GET['desde'] ?? date('Y-m-d'));
$f_hasta     = trim($_GET['hasta'] ?? date('Y-m-d'));
$f_tipo      = trim($_GET['tipo']  ?? '');

$registros   = [];
$total_filas = 0;
$kpi_ingresos = 0;
$kpi_en_centro = 0;
$kpi_salidas  = 0;
$w_mensaje    = '';
$w_tipo_alerta = 'danger';

try {
    $stmt = $pdo->prepare(
        "SELECT * FROM fun_siem_actividad_fisica(?::DATE, ?::DATE, ?::TEXT, ?::INT, ?::INT)"
    );
    $stmt->execute([
        $f_desde !== '' ? $f_desde : null,
        $f_hasta !== '' ? $f_hasta : null,
        $f_tipo  !== '' ? $f_tipo  : null,
        $por_pagina,
        $offset,
    ]);
    $registros   = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $total_filas = !empty($registros) ? (int) $registros[0]['total_filas'] : 0;

    // KPIs de hoy
    $kpi_row = $pdo->query(
        "SELECT
            COUNT(*)                                     AS ingresos,
            COUNT(*) FILTER (WHERE fec_salida=fec_ingreso) AS en_centro,
            COUNT(*) FILTER (WHERE fec_salida<>fec_ingreso) AS salidas
         FROM tab_log_ingresos
         WHERE DATE(fec_ingreso) = CURRENT_DATE"
    )->fetch(PDO::FETCH_ASSOC);
    if ($kpi_row) {
        $kpi_ingresos  = (int) $kpi_row['ingresos'];
        $kpi_en_centro = (int) $kpi_row['en_centro'];
        $kpi_salidas   = (int) $kpi_row['salidas'];
    }
} catch (PDOException $e) {
    $w_mensaje = ErrorHandler::userMessageFromException($e);
}

$total_paginas = $total_filas > 0 ? (int) ceil($total_filas / $por_pagina) : 1;

$page_title     = 'SIEM — Actividad Física';
$active_menu_id = '0605';
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

    <!-- KPIs rápidos (hoy) -->
    <div class="row g-3 mb-3">
        <div class="col-4">
            <div class="siem-kpi-card p-3 text-center">
                <div class="siem-kpi-label mb-1">Ingresos hoy</div>
                <div class="siem-kpi-value"><?= $kpi_ingresos ?></div>
            </div>
        </div>
        <div class="col-4">
            <div class="siem-kpi-card p-3 text-center">
                <div class="siem-kpi-label mb-1">En el centro</div>
                <div class="siem-kpi-value text-success"><?= $kpi_en_centro ?></div>
            </div>
        </div>
        <div class="col-4">
            <div class="siem-kpi-card p-3 text-center">
                <div class="siem-kpi-label mb-1">Salidas hoy</div>
                <div class="siem-kpi-value text-muted"><?= $kpi_salidas ?></div>
            </div>
        </div>
    </div>

    <!-- Filtros -->
    <div class="siem-kpi-card p-3 mb-3">
        <form method="GET" class="siem-filtros" autocomplete="off">
            <div class="row g-2 align-items-end">
                <div class="col-6 col-md-3">
                    <label class="form-label small mb-1">Desde</label>
                    <input type="date" name="desde" value="<?= htmlspecialchars($f_desde) ?>"
                           class="form-control form-control-sm">
                </div>
                <div class="col-6 col-md-3">
                    <label class="form-label small mb-1">Hasta</label>
                    <input type="date" name="hasta" value="<?= htmlspecialchars($f_hasta) ?>"
                           class="form-control form-control-sm">
                </div>
                <div class="col-6 col-md-3">
                    <label class="form-label small mb-1">Tipo persona</label>
                    <input type="text" name="tipo" value="<?= htmlspecialchars($f_tipo) ?>"
                           class="form-control form-control-sm" placeholder="Aprendiz, Visitante...">
                </div>
                <div class="col-6 col-md-3 d-flex gap-2">
                    <button type="submit" class="btn btn-sm btn-outline-success w-100">
                        <i class="bi bi-search me-1"></i>Filtrar
                    </button>
                    <a href="<?= htmlspecialchars(smartcsetUrl('/pages/modulos/siem/actividad/index.php')) ?>"
                       class="btn btn-sm btn-outline-secondary w-100">
                        <i class="bi bi-x"></i>
                    </a>
                </div>
            </div>
        </form>
    </div>

    <!-- Línea de tiempo -->
    <div class="siem-kpi-card p-3">
        <div class="siem-section-header">
            <i class="bi bi-door-open text-info"></i>
            <span class="siem-section-title">Registro de actividad física</span>
            <span class="ms-auto badge bg-secondary"><?= number_format($total_filas) ?> registros</span>
        </div>

        <?php if (empty($registros)): ?>
            <p class="text-muted small mb-0 text-center py-3">
                <i class="bi bi-inbox me-1"></i>Sin registros para los filtros aplicados.
            </p>
        <?php else: ?>
            <div class="mt-2">
                <?php foreach ($registros as $r):
                    $es_abierto = (bool) $r['abierto'];
                    $tipo_cls   = $es_abierto ? 'ingreso' : 'salida';
                    $hora       = date('H:i:s', strtotime($r['fec_ingreso']));
                    $fecha      = date('d/m/Y', strtotime($r['fec_ingreso']));
                ?>
                    <div class="siem-timeline-item <?= $tipo_cls ?>">
                        <div class="d-flex justify-content-between align-items-start">
                            <div>
                                <span class="siem-timeline-hora"><?= $fecha ?> <?= $hora ?></span>
                                <?php if ($es_abierto): ?>
                                    <span class="badge bg-success ms-2 small">
                                        <i class="bi bi-box-arrow-in-right me-1"></i>INGRESO
                                    </span>
                                <?php else: ?>
                                    <span class="badge bg-secondary ms-2 small">
                                        <i class="bi bi-box-arrow-right me-1"></i>SALIDA
                                        <span class="ms-1"><?= date('H:i', strtotime($r['fec_salida'])) ?></span>
                                    </span>
                                <?php endif; ?>
                            </div>
                            <span class="badge bg-dark border border-secondary small">
                                <?= htmlspecialchars($r['nom_entrada'] ?? '—') ?>
                            </span>
                        </div>
                        <div class="siem-timeline-nombre mt-1">
                            <?= htmlspecialchars($r['nom_persona']) ?>
                        </div>
                        <div class="siem-timeline-detalle">
                            <?= htmlspecialchars($r['id_persona']) ?>
                            &nbsp;·&nbsp;
                            <?= htmlspecialchars($r['nom_tipo_persona']) ?>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>

            <!-- Paginación -->
            <?php if ($total_paginas > 1): ?>
                <nav class="mt-3">
                    <ul class="pagination pagination-sm mb-0 justify-content-center">
                        <?php
                        $base_url = smartcsetUrl('/pages/modulos/siem/actividad/index.php');
                        $params   = array_filter(['desde' => $f_desde, 'hasta' => $f_hasta, 'tipo' => $f_tipo]);
                        ?>
                        <li class="page-item <?= $pagina <= 1 ? 'disabled' : '' ?>">
                            <a class="page-link"
                               href="<?= $base_url . '?' . http_build_query(array_merge($params, ['p' => $pagina - 1])) ?>">
                                <i class="bi bi-chevron-left"></i>
                            </a>
                        </li>
                        <li class="page-item disabled">
                            <span class="page-link">Página <?= $pagina ?> de <?= $total_paginas ?></span>
                        </li>
                        <li class="page-item <?= $pagina >= $total_paginas ? 'disabled' : '' ?>">
                            <a class="page-link"
                               href="<?= $base_url . '?' . http_build_query(array_merge($params, ['p' => $pagina + 1])) ?>">
                                <i class="bi bi-chevron-right"></i>
                            </a>
                        </li>
                    </ul>
                </nav>
            <?php endif; ?>

        <?php endif; ?>
    </div>
</div>

<?php include modulosLayout('layout/footer.php'); ?>
