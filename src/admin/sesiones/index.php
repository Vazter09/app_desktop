<?php
require_once __DIR__ . '/../../core/prepare.php';
require_once __DIR__ . '/../../core/ErrorHandler.php';
require_once __DIR__ . '/../../core/helpers.php';

session_start();

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ../../../index.php');
    exit();
}

if (!usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])) {
    http_response_code(403);
    die('Acceso denegado. Solo administradores pueden gestionar sesiones activas.');
}

$w_mensaje     = '';
$w_tipo_alerta = 'success';
$sesiones_lista = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['btn_cerrar_sesion'])) {
    try {
        $w_id_cerrar = trim((string) ($_POST['hid_id_usuario'] ?? ''));
        if ($w_id_cerrar === '') {
            throw new Exception('Debe indicar el usuario de la sesión a cerrar.');
        }

        $stmt_fun_salida_sesion->execute([$w_id_cerrar]);
        $stmt_fun_salida_sesion->fetchColumn();

        $w_mensaje = 'Sesión de «' . $w_id_cerrar . '» cerrada correctamente.';
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
    $sesiones_lista = $stmt_list_sesiones_activas->fetchAll();
} catch (PDOException $e) {
    $w_mensaje     = ErrorHandler::userMessageFromException($e);
    $w_tipo_alerta = 'danger';
}

$page_title           = 'Sesiones activas';
$active_menu_id       = '';
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
                    <i class="bi bi-person-badge me-2"></i>Sesiones activas
                    <span class="badge bg-light text-dark ms-1" style="font-size:0.72rem;"><?= count($sesiones_lista) ?></span>
                </strong>
            </div>
            <div class="table-responsive scroll-lista">
                <table class="table table-hover align-middle mb-0 table-sm" id="tabla-sesiones-activas">
                    <thead class="thead-oliva sticky-top">
                        <tr style="font-size:0.85rem;">
                            <th class="ps-3 py-2">ID usuario</th>
                            <th class="py-2">Nombre</th>
                            <th class="py-2">Correo</th>
                            <th class="text-center py-2">Rol</th>
                            <th class="py-2">Inicio sesión</th>
                            <th class="py-2">Última actividad</th>
                            <th class="text-center py-2" width="130">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($sesiones_lista)): ?>
                        <tr>
                            <td colspan="7" class="text-center text-muted py-4 small">
                                No hay sesiones activas en este momento.
                            </td>
                        </tr>
                        <?php else: ?>
                        <?php foreach ($sesiones_lista as $s): ?>
                        <?php
                            $fmtInicio = $s['fec_inicio']
                                ? date('d/m/Y H:i', strtotime((string) $s['fec_inicio']))
                                : '—';
                            $fmtActividad = $s['ult_actividad']
                                ? date('d/m/Y H:i', strtotime((string) $s['ult_actividad']))
                                : '—';
                            $esYo = ($s['id_usuario'] === $_SESSION['id_usuario']);
                        ?>
                        <tr class="<?= $esYo ? 'sesion-propia' : '' ?>" style="font-size:0.875rem;">
                            <td class="ps-3 fw-bold py-2 text-muted small"><?= htmlspecialchars($s['id_usuario']) ?></td>
                            <td class="py-2 fw-medium" style="color:var(--v-oscuro);">
                                <?= htmlspecialchars($s['nom_usuario']) ?>
                                <?php if ($esYo): ?>
                                <span class="badge bg-info text-dark ms-1" style="font-size:0.65rem;">Tú</span>
                                <?php endif; ?>
                            </td>
                            <td class="py-2 small text-muted"><?= htmlspecialchars($s['mail_usuario']) ?></td>
                            <td class="text-center py-2">
                                <?php if (!empty($s['ind_usuario'])): ?>
                                <span class="badge rounded-pill" style="background:rgba(107,142,35,0.2);color:var(--v-oscuro);font-size:0.7rem;">
                                    <i class="bi bi-shield-fill-check me-1"></i>Admin
                                </span>
                                <?php else: ?>
                                <span class="badge bg-light text-secondary border" style="font-size:0.7rem;">Usuario</span>
                                <?php endif; ?>
                            </td>
                            <td class="py-2 small"><?= htmlspecialchars($fmtInicio) ?></td>
                            <td class="py-2 small"><?= htmlspecialchars($fmtActividad) ?></td>
                            <td class="text-center py-2">
                                <form method="POST" class="d-inline" data-smart-confirm
                                      data-smart-confirm-title="Cerrar sesión"
                                      data-smart-confirm-message="¿Cerrar la sesión activa de «<?= htmlspecialchars($s['nom_usuario']) ?>» (<?= htmlspecialchars($s['id_usuario']) ?>)?"
                                      data-smart-confirm-ok="Cerrar sesión"
                                      data-smart-confirm-variant="danger">
                                    <input type="hidden" name="hid_id_usuario" value="<?= htmlspecialchars($s['id_usuario']) ?>">
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
