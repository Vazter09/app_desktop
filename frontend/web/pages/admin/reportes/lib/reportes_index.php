<?php
declare(strict_types=1);

/**
 * Pantalla de CARGUE de un reporte SENA. Cada página define $reporteKey.
 * Reemplaza el listado anterior: ahora se sube el archivo (.xlsx/.csv) del reporte.
 * El procesamiento a tab_temp_* se habilitará por separado (requiere validar el
 * layout real del archivo antes de hacer TRUNCATE + carga).
 */

require_once dirname(__DIR__, 4) . '/init.php';
require_once dirname(__DIR__, 6) . '/backend/services/reportes/reportes_catalogo.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

if (!usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])) {
    http_response_code(403);
    die('Acceso denegado. Solo administradores pueden cargar reportes.');
}

$reporteKey = isset($reporteKey) ? (string) $reporteKey : '';
$rep = reportesGet($reporteKey);
if ($rep === null) {
    http_response_code(404);
    die('Reporte no encontrado.');
}

$page_title = 'Cargue — ' . (string) $rep['titulo'];
$active_menu_id = isset($reporteMenuId) ? (string) $reporteMenuId : '';
$wnom_usuario = $_SESSION['nom_usuario'] ?? '';
$_asset_root = dirname(__DIR__, 4) . '/public/assets';

include smartcsetLayoutPath('head.php');
include smartcsetLayoutPath('sidebar.php');
include smartcsetLayoutPath('topbar.php');
?>

<div class="cargue-shell" data-spa="1" style="max-width:760px;margin:0 auto;">

    <header style="background:linear-gradient(135deg, color-mix(in srgb, var(--v-oscuro) 92%, #000), var(--v-oscuro)); border-radius:16px; padding:1.3rem 1.5rem; margin-bottom:1.1rem;">
        <span style="display:inline-flex;align-items:center;gap:7px;font-size:.7rem;text-transform:uppercase;letter-spacing:.1em;font-weight:600;color:rgba(255,255,255,.82);background:rgba(255,255,255,.1);padding:4px 11px;border-radius:999px;">
            <i class="bi bi-cloud-arrow-up"></i> Cargue de reportes
        </span>
        <h2 style="color:#fff;font-size:1.45rem;font-weight:700;margin:.55rem 0 .2rem;letter-spacing:.01em;">
            <?= htmlspecialchars((string) $rep['titulo']) ?>
        </h2>
        <p style="color:rgba(255,255,255,.72);margin:0;font-size:.85rem;">
            Sube el archivo del reporte para cargarlo al sistema.
        </p>
    </header>

    <div class="card border-0 shadow-sm" style="border-radius:14px;">
        <div class="card-body p-4">

            <div class="d-flex align-items-start gap-2 mb-3" style="color:var(--text-muted);font-size:.85rem;">
                <i class="bi bi-info-circle mt-1"></i>
                <span>Formatos aceptados: <strong>.xlsx</strong> o <strong>.csv</strong>.</span>
            </div>

            <form data-cargue-form
                  data-reporte="<?= htmlspecialchars($reporteKey, ENT_QUOTES, 'UTF-8') ?>"
                  action="<?= htmlspecialchars(smartcsetUrl('/routers/admin/v1/reportes/cargar.php')) ?>"
                  method="post"
                  enctype="multipart/form-data">
                <div class="mb-3">
                    <input type="file" name="archivo" accept=".xlsx,.csv" required
                           class="form-control form-control-lg">
                </div>
                <button type="submit" class="btn fw-bold text-white px-4" style="background:var(--v-oscuro);">
                    <i class="bi bi-upload me-1"></i> Cargar archivo
                </button>
            </form>

            <div class="cargue-result mt-3" role="status" aria-live="polite"></div>

        </div>
    </div>

</div>

<?php
$vCargueJs = @filemtime($_asset_root . '/js/core/smartcset-cargue.js') ?: time();
$extra_js = '<script src="' . htmlspecialchars(smartcsetAsset('js/core/smartcset-cargue.js')) . '?v=' . (int) $vCargueJs . '"></script>';
include smartcsetLayoutPath('footer.php');
