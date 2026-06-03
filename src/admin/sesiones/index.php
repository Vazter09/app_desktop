<?php
require_once __DIR__ . '/../../core/prepare.php';
require_once __DIR__ . '/../../core/ErrorHandler.php';
require_once __DIR__ . '/../../core/helpers.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ../../../index.php');
    exit();
}

if (!usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])) {
    http_response_code(403);
    die('Acceso denegado. Solo administradores pueden gestionar sesiones.');
}

$w_mensaje     = '';
$w_tipo_alerta = 'success';
$sesiones_activas = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['btn_cerrar_sesion'])) {
    try {
        $w_id_sesion = (int) ($_POST['hid_id_sesion'] ?? 0);
        if ($w_id_sesion < 1) {
            throw new Exception('Debe indicar la sesión a cerrar.');
        }

        accesoSalidaSesion(
            $stmt_fun_salida_sesion,
            $w_id_sesion,
            ACCESO_SESION_CIERRE_ADMIN,
            (string) $_SESSION['id_usuario']
        );

        $w_mensaje = 'Sesión #' . $w_id_sesion . ' cerrada correctamente.';
    } catch (PDOException $e) {
        $w_mensaje     = ErrorHandler::userMessageFromException($e);
        $w_tipo_alerta = 'danger';
    } catch (Exception $e) {
        $w_mensaje     = ErrorHandler::userMessageFromException($e);
        $w_tipo_alerta = 'danger';
    }
}

try {
    $stmt_list_sesiones_activas->execute();
    $sesiones_activas = $stmt_list_sesiones_activas->fetchAll();
} catch (PDOException $e) {
    $w_mensaje     = ErrorHandler::userMessageFromException($e);
    $w_tipo_alerta = 'danger';
}

$page_title           = 'Sesiones activas';
$active_menu_id       = '0206';
$wnom_usuario         = $_SESSION['nom_usuario'];
$smartcset_asset_href = smartcsetProjectAssetHref();

$extra_stylesheets = '<link rel="stylesheet" href="' . htmlspecialchars($smartcset_asset_href)
    . 'css/admin_sesiones.css?v=' . (int) (@filemtime(dirname(__DIR__, 3) . '/css/admin_sesiones.css') ?: time()) . '">';

include __DIR__ . '/../../layout/head.php';
include __DIR__ . '/../../layout/sidebar.php';
include __DIR__ . '/../../layout/topbar.php';
?>

<?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

<div class="row g-3">
    <div class="col-12">
        <div class="card shadow-sm border-0 admin-sesiones-card">
            <div class="card-header bg-corporativo py-2 d-flex flex-wrap justify-content-between align-items-center gap-2">
                <strong style="font-size:0.95rem;">
                    <i class="bi bi-person-badge me-2"></i>Conectados ahora
                    <span class="badge bg-light text-dark ms-1" style="font-size:0.72rem;"><?= count($sesiones_activas) ?></span>
                </strong>
            </div>
            <div class="table-responsive scroll-lista">
                <table class="table table-hover align-middle mb-0 table-sm" id="tabla-sesiones-activas">
                    <thead class="thead-oliva sticky-top">
                        <tr style="font-size:0.85rem;">
                            <th class="ps-3 py-2">Sesión</th>
                            <th class="py-2">Usuario</th>
                            <th class="py-2">Nombre</th>
                            <th class="py-2">Última ubicación</th>
                            <th class="py-2">IP</th>
                            <th class="py-2">Inicio</th>
                            <th class="py-2">Actividad</th>
                            <th class="py-2">Estado</th>
                            <th class="text-center py-2" width="120">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($sesiones_activas)): ?>
                        <tr>
                            <td colspan="9" class="text-center text-muted py-4 small">
                                No hay sesiones activas en este momento.
                            </td>
                        </tr>
                        <?php else: ?>
                        <?php foreach ($sesiones_activas as $s): ?>
                        <?php
                            $fmtInicio = smartcsetFormatDbTimestamp($s['fec_inicio'] ?? null);
                            $fmtActividad = smartcsetFormatDbTimestamp($s['ult_actividad'] ?? null);
                            $ubicacion = trim((string) ($s['ult_ruta'] ?? ''));
                            if (!empty($s['ult_menu_id'])) {
                                $ubicacion .= ($ubicacion !== '' ? ' · ' : '') . 'menú ' . $s['ult_menu_id'];
                            }
                            $esYo = ($s['id_usuario'] === $_SESSION['id_usuario']);
                            $estadoPresencia = accesoEstadoPresencia(true, $s['ult_actividad'] ?? null);
                            $etiquetaPresencia = accesoPresenciaEtiqueta($estadoPresencia);
                            $clasePresencia = accesoPresenciaClaseCss($estadoPresencia);
                        ?>
                        <tr class="<?= $esYo ? 'sesion-propia' : '' ?>" style="font-size:0.875rem;">
                            <td class="ps-3 py-2 text-muted small">#<?= (int) $s['id_sesion'] ?></td>
                            <td class="py-2 fw-bold text-muted small"><?= htmlspecialchars($s['id_usuario']) ?></td>
                            <td class="py-2 fw-medium" style="color:var(--v-oscuro);">
                                <?= htmlspecialchars($s['nom_usuario']) ?>
                                <?php if ($esYo): ?>
                                <span class="badge badge-corporativo-soft ms-1" style="font-size:0.65rem;">Tú</span>
                                <?php endif; ?>
                            </td>
                            <td class="py-2 small text-muted"><?= htmlspecialchars($ubicacion !== '' ? $ubicacion : '—') ?></td>
                            <td class="py-2 small"><?= htmlspecialchars((string) ($s['ip_cliente'] ?? '—')) ?></td>
                            <td class="py-2 small"><?= htmlspecialchars($fmtInicio) ?></td>
                            <td class="py-2 small"><?= htmlspecialchars($fmtActividad) ?></td>
                            <td class="py-2">
                                <span class="badge presencia-badge <?= htmlspecialchars($clasePresencia) ?>"
                                      title="Última actividad: <?= htmlspecialchars($fmtActividad) ?>">
                                    <?= htmlspecialchars($etiquetaPresencia) ?>
                                </span>
                            </td>
                            <td class="text-center py-2">
                                <form method="POST" class="d-inline" data-smart-confirm
                                      data-smart-confirm-title="Cerrar sesión"
                                      data-smart-confirm-message="¿Cerrar la sesión #<?= (int) $s['id_sesion'] ?> de «<?= htmlspecialchars($s['nom_usuario']) ?>»?"
                                      data-smart-confirm-ok="Cerrar sesión"
                                      data-smart-confirm-variant="danger">
                                    <input type="hidden" name="hid_id_sesion" value="<?= (int) $s['id_sesion'] ?>">
                                    <button type="submit" name="btn_cerrar_sesion"
                                            class="btn btn-sm btn-outline-danger border-0"
                                            title="Cerrar sesión">
                                        <i class="bi bi-box-arrow-right me-1"></i>Cerrar
                                    </button>
                                </form>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<?php
$extra_js = '<script src="' . htmlspecialchars($smartcset_asset_href)
    . 'js/admin_sesiones.js?v=' . (int) (@filemtime(dirname(__DIR__, 3) . '/js/admin_sesiones.js') ?: time()) . '"></script>';
include __DIR__ . '/../../layout/footer.php';
?>
