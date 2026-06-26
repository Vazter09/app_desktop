<?php
declare(strict_types=1);

require_once dirname(__DIR__, 4) . '/init.php';
require_once dirname(__DIR__, 6) . '/backend/services/instructor/asistencia_service.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

$idInstructor = instructorResolverIdDesdeSesion($pdo, (string) $_SESSION['id_usuario']);
if ($idInstructor === null) {
    http_response_code(403);
    exit('Acceso restringido a instructores registrados.');
}

$w_mensaje = '';
$w_tipo_alerta = 'success';
$fichas = [];
$asistencia = [
    'desde' => date('Y-m-d'),
    'hasta' => date('Y-m-d'),
    'rows' => [],
    'por_fecha' => [],
];
$idFichaSel = null;
$fichaSel = null;

try {
    $fichas = instructorListarFichas($stmt_fun_listar_fichas_instructor, $idInstructor);
    $rango = instructorNormalizarRangoFechas($_GET);
    $idFichaSel = instructorResolverFichaSeleccionada($fichas, $_GET);

    if ($idFichaSel !== null) {
        foreach ($fichas as $f) {
            if ((int) ($f['id_ficha'] ?? 0) === $idFichaSel) {
                $fichaSel = $f;
                break;
            }
        }
        $asistencia = instructorListarAsistenciaFicha(
            $stmt_fun_listar_asistencia_ficha,
            $idInstructor,
            $idFichaSel,
            $rango['desde'],
            $rango['hasta']
        );
    }
} catch (InvalidArgumentException $e) {
    $w_mensaje = $e->getMessage();
    $w_tipo_alerta = 'warning';
} catch (PDOException $e) {
    $w_mensaje = ErrorHandler::userMessageFromException($e);
    $w_tipo_alerta = 'danger';
}

$basePath = parse_url((string) ($_SERVER['REQUEST_URI'] ?? ''), PHP_URL_PATH) ?: '';
$modoRango = isset($_GET['desde'], $_GET['hasta'])
    && trim((string) $_GET['desde']) !== ''
    && trim((string) $_GET['hasta']) !== ''
    && trim((string) ($_GET['desde'] ?? '')) !== trim((string) ($_GET['hasta'] ?? ''));

if (isset($_GET['partial']) && $_GET['partial'] === '1') {
    include __DIR__ . '/fragment_detalle.php';
    exit();
}

$page_title = 'Mis fichas';
$active_menu_id = '0601';
$wnom_usuario = (string) ($_SESSION['nom_usuario'] ?? '');
$_root = smartcsetProjectRoot();
$_css_v = @filemtime($_root . '/frontend/web/public/assets/css/modulo_instructor_fichas.css') ?: time();
$_js_v = @filemtime($_root . '/frontend/web/public/assets/js/instructor-fichas.js') ?: time();
$extra_stylesheets = '<link rel="stylesheet" href="' . htmlspecialchars(smartcsetAsset('css/modulo_instructor_fichas.css'))
    . '?v=' . (int) $_css_v . '">';
$extra_js = '<script src="' . htmlspecialchars(smartcsetAsset('js/instructor-fichas.js'))
    . '?v=' . (int) $_js_v . '"></script>';

include smartcsetLayoutPath('head.php');
include smartcsetLayoutPath('sidebar.php');
include smartcsetLayoutPath('topbar.php');

renderPageFlash($w_mensaje, $w_tipo_alerta);
?>
<div class="inst-fichas-page" id="inst-fichas-page" data-base-path="<?= htmlspecialchars($basePath) ?>">
    <div class="inst-fichas-header mb-4">
        <h2 class="inst-fichas-title h4 mb-1"><i class="bi bi-journal-bookmark-fill me-2"></i>Mis fichas</h2>
        <p class="text-muted mb-0">Seleccione una ficha para consultar la asistencia de sus aprendices.</p>
    </div>

    <?php if ($fichas === []): ?>
        <div class="alert alert-info">No tiene fichas en ejecución asignadas como líder o instructor transversal.</div>
    <?php else: ?>
        <div class="row g-4">
            <div class="col-lg-4">
                <div class="inst-fichas-panel card shadow-sm">
                    <div class="card-header fw-semibold">Fichas a cargo</div>
                    <div class="list-group list-group-flush inst-fichas-list" role="listbox">
                        <?php foreach ($fichas as $ficha): ?>
                            <?php
                            $fid = (int) ($ficha['id_ficha'] ?? 0);
                            $activa = $idFichaSel === $fid;
                            $href = $basePath . '?id_ficha=' . $fid
                                . '&fecha=' . urlencode($asistencia['desde']);
                            ?>
                            <a href="<?= htmlspecialchars($href) ?>"
                               class="list-group-item list-group-item-action inst-ficha-item<?= $activa ? ' active' : '' ?>"
                               data-id-ficha="<?= $fid ?>">
                                <div class="d-flex justify-content-between align-items-start gap-2">
                                    <div>
                                        <div class="fw-semibold">Ficha <?= htmlspecialchars((string) $fid) ?></div>
                                        <div class="small <?= $activa ? 'text-white-50' : 'text-muted' ?>">
                                            <?= htmlspecialchars((string) ($ficha['nom_programa'] ?? '')) ?>
                                        </div>
                                    </div>
                                    <span class="badge <?= $activa ? 'bg-light text-dark' : 'bg-secondary' ?>">
                                        <?= (int) ($ficha['num_aprendices'] ?? 0) ?>
                                    </span>
                                </div>
                                <div class="small mt-2 <?= $activa ? 'text-white-50' : 'text-muted' ?>">
                                    <i class="bi bi-clock me-1"></i><?= htmlspecialchars((string) ($ficha['nom_jornada'] ?? '')) ?>
                                    <span class="ms-2 badge rounded-pill <?= $activa ? 'bg-dark' : 'bg-outline-secondary border' ?>">
                                        <?= htmlspecialchars(instructorEtiquetaOrigen((string) ($ficha['origen_vinculo'] ?? ''))) ?>
                                    </span>
                                </div>
                            </a>
                        <?php endforeach; ?>
                    </div>
                </div>
            </div>

            <div class="col-lg-8">
                <div id="inst-fichas-detalle">
                    <?php include __DIR__ . '/fragment_detalle.php'; ?>
                </div>
            </div>
        </div>
    <?php endif; ?>
</div>
<?php
include smartcsetLayoutPath('footer.php');
