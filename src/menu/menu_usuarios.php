<?php
require_once(__DIR__ . '/../core/prepare.php');
require_once(__DIR__ . '/../core/helpers.php');
session_start();

if (!isset($_SESSION['id_usuario'])) {
    header("Location: ../../index.php");
    exit();
}

$lista_usuarios = [];
$lista_menus    = [];
$error_carga    = null;

try {
    $stmt_list_usuarios->execute();
    $lista_usuarios = $stmt_list_usuarios->fetchAll(PDO::FETCH_ASSOC);

    $stmt_list_todos_menus->execute();
    $lista_menus = $stmt_list_todos_menus->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    $error_carga = $e->getMessage();
}

$page_title     = 'Accesos';
$active_menu_id = '0203';
$wnom_usuario   = $_SESSION['nom_usuario'];

include __DIR__ . '/../layout/head.php';
include __DIR__ . '/../layout/sidebar.php';
include __DIR__ . '/../layout/topbar.php';

renderPageFlash($error_carga ?? null, 'danger', 'Error al cargar');
?>

<div class="row g-3">
    <!-- Selector de usuario -->
    <div class="col-lg-4">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-corporativo py-2">
                <strong style="font-size:0.95rem;"><i class="bi bi-people-fill me-2"></i>Seleccionar Usuario</strong>
            </div>
            <div class="card-body p-3">
                <label class="form-label small fw-bold text-muted mb-1" style="font-size:0.75rem;">USUARIO</label>
                <select id="sel_usuario" class="form-select form-select-sm mb-3">
                    <option value="">Seleccione un usuario...</option>
                    <?php foreach ($lista_usuarios as $u):
                        $esAdmin = !empty($u['ind_usuario']);
                    ?>
                    <option value="<?= htmlspecialchars($u['id_usuario']) ?>"
                            data-admin="<?= $esAdmin ? '1' : '0' ?>">
                        <?= htmlspecialchars($u['nom_usuario']) ?><?= $esAdmin ? ' (Administrador)' : '' ?>
                    </option>
                    <?php endforeach; ?>
                </select>
                <p class="text-muted small mb-2" style="font-size:0.78rem;">
                    Al seleccionar un usuario se cargan sus menús asignados. Marque o desmarque según corresponda y guarde.
                </p>
                <p class="text-muted small mb-0" style="font-size:0.78rem;">
                    Los usuarios marcados como <strong>Administrador</strong> en Usuarios tienen acceso fijo a todo el catálogo.
                </p>
            </div>
        </div>
    </div>

    <!-- Panel de permisos -->
    <div class="col-lg-8">
        <div id="alert_admin_fijo" class="card guide-card guide-card--warning guide-card--compact border-0 shadow-sm mb-3 d-none" role="status">
            <div class="guide-card-header py-2">
                <div class="guide-card-icon" style="width:2rem;height:2rem;font-size:0.95rem;">
                    <i class="bi bi-shield-fill-check"></i>
                </div>
                <div>
                    <p class="guide-card-title mb-0" style="font-size:0.88rem;">Acceso de administrador</p>
                    <p class="guide-card-subtitle mb-0" style="font-size:0.8rem;">
                        Este usuario ve todo el catálogo automáticamente. No requiere asignación manual.
                    </p>
                </div>
            </div>
        </div>
        <div id="panel_permisos" class="ventana-bloqueada">
            <form id="form_perfiles" class="card shadow-sm border-0">
                <div class="card-header bg-corporativo py-2 d-flex justify-content-between align-items-center">
                    <strong style="font-size:0.95rem;"><i class="bi bi-layout-sidebar me-2"></i>Menús Disponibles</strong>
                    <button type="button" id="btn_limpiar" class="btn btn-sm btn-light" title="Desmarcar todos los menús">
                        <i class="bi bi-arrow-counterclockwise me-1" aria-hidden="true"></i>Limpiar
                    </button>
                </div>
                <div class="card-body p-0">
                    <input type="hidden" name="hid_usuario" id="hid_usuario">
                    <div class="table-responsive scroll-lista">
                        <table class="table table-hover align-middle mb-0 table-sm">
                            <thead class="thead-oliva sticky-top">
                                <tr style="font-size:0.85rem;">
                                    <th class="py-2 px-3" width="50">Activo</th>
                                    <th class="py-2">Menú</th>
                                    <th class="py-2">Programa</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($lista_menus as $m): ?>
                                <tr data-id-menu="<?= $m['id_menu'] ?>" data-padre="<?= $m['ind_id_padre'] ?>"
                                    style="font-size:0.875rem;">
                                    <td class="px-3 py-2 text-center">
                                        <input type="checkbox" name="chk_menu[]" value="<?= $m['id_menu'] ?>"
                                               id="chk_<?= $m['id_menu'] ?>" class="form-check-input check-logica">
                                    </td>
                                    <td class="py-2">
                                        <?= str_repeat('<span style="display:inline-block;width:16px;"></span>', max(0, strlen($m['id_menu']) - 2)) ?>
                                        <?php if (strlen($m['id_menu']) > 2): ?><span class="text-muted me-1">–</span><?php endif; ?>
                                        <strong><?= htmlspecialchars($m['nom_menu']) ?></strong>
                                    </td>
                                    <td class="py-2 small text-muted">
                                        <em><?= htmlspecialchars($m['nom_programa'] ?? 'no_aplica') ?></em>
                                    </td>
                                </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="card-footer text-center py-3">
                    <button type="submit" id="btn_guardar_permisos" class="btn btn-corporativo w-100 fw-bold py-2">
                        <i class="bi bi-floppy-fill me-2" aria-hidden="true"></i>EJECUTAR PROCESO
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php
$_v_menu_u = @filemtime(dirname(__DIR__, 2) . '/js/menu_usuarios.js') ?: time();
?>
<script src="../../js/menu_usuarios.js?v=<?= (int) $_v_menu_u ?>"></script>

<?php include __DIR__ . '/../layout/footer.php'; ?>
