<?php
require_once(__DIR__ . '/../core/prepare.php');
require_once(__DIR__ . '/../core/ErrorHandler.php');
require_once(__DIR__ . '/../core/helpers.php');
session_start();

if (!isset($_SESSION['id_usuario'])) {
    header("Location: ../../index.php");
    exit();
}

$w_mensaje = "";
$w_tipo_alerta = "success";

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        if (isset($_POST['btn_guardar'])) {
            $w_id       = trim($_POST['txt_id_menu']);
            $w_nom      = trim($_POST['txt_nom_menu']);
            $w_padre    = trim($_POST['txt_id_padre'] ?? '0');
            $w_programa = trim($_POST['txt_nom_programa'] ?? '') ?: 'no_aplica';

            if ($w_id === '' || $w_nom === '') {
                throw new Exception('ID y descripción del menú son obligatorios.');
            }
            if ($w_padre === '') {
                $w_padre = '0';
            }

            $stmt_check = $pdo->prepare("SELECT 1 FROM tab_menus WHERE id_menu = ?::TEXT");
            $stmt_check->execute([$w_id]);

            if ($stmt_check->fetch()) {
                $stmt_upd_menu->execute([$w_id, $w_nom, $w_padre, $w_programa]);
                $w_res = $stmt_upd_menu->fetchColumn();
            } else {
                $stmt_ins_menu->execute([$w_id, $w_nom, $w_padre, $w_programa]);
                $w_res = $stmt_ins_menu->fetchColumn();
            }

            if (strpos($w_res, 'OK') !== false) {
                $w_mensaje = "Menú guardado correctamente.";
            } else {
                $w_mensaje = "Error: " . $w_res;
                $w_tipo_alerta = "danger";
            }
        }

        if (isset($_POST['btn_eliminar'])) {
            $stmt_del_menu->execute([$_POST['hid_id_menu']]);
            $w_res = $stmt_del_menu->fetchColumn();

            if (strpos($w_res, 'OK') !== false) {
                $w_mensaje = "Menú eliminado correctamente.";
            } else {
                if (stripos($w_res, 'tab_menu_usuarios') !== false) {
                    $w_mensaje = "No se puede eliminar: el menú está asignado a usuarios. Primero desasígnelo en Accesos.";
                } else {
                    $w_mensaje = "Error: " . $w_res;
                }
                $w_tipo_alerta = "danger";
            }
        }
    } catch (PDOException $e) {
        $w_mensaje = ErrorHandler::handleDatabaseException($e)['message'];
        $w_tipo_alerta = "danger";
    } catch (Exception $e) {
        $w_mensaje = ErrorHandler::handleValidationException($e)['message'];
        $w_tipo_alerta = "danger";
    }
}

$stmt_list_todos_menus->execute();
$menus_lista = $stmt_list_todos_menus->fetchAll();

$page_title     = 'Menús';
$active_menu_id = '0202';
$wnom_usuario   = $_SESSION['nom_usuario'];
$extra_css      = '.menu-editando { background: rgba(107, 142, 35, 0.12) !important; }';

include __DIR__ . '/../layout/head.php';
include __DIR__ . '/../layout/sidebar.php';
include __DIR__ . '/../layout/topbar.php';
?>

<?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

<div class="card guide-card border-0 shadow-sm mb-3">
    <div class="guide-card-header py-2">
        <div class="guide-card-icon" style="width:2rem;height:2rem;font-size:0.95rem;">
            <i class="bi bi-journal-text"></i>
        </div>
        <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 w-100">
            <div>
                <p class="guide-card-title mb-0" style="font-size:0.9rem;">Catálogo de menús</p>
                <p class="guide-card-subtitle mb-0" style="font-size:0.8rem;">
                    Cree opciones aquí; asigne accesos en <a href="menu_usuarios.php">Accesos</a>.
                </p>
            </div>
            <div class="guide-actions mb-0">
                <a href="menu_usuarios.php" class="btn btn-sm btn-corporativo">
                    <i class="bi bi-person-check me-1"></i>Accesos
                </a>
                <a href="copiar_menu_usuarios.php" class="btn btn-sm btn-outline-corporativo">
                    <i class="bi bi-files me-1"></i>Copiar perfil
                </a>
            </div>
        </div>
    </div>
</div>

<div class="row g-3">
    <div class="col-12">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-corporativo py-2 d-flex flex-wrap justify-content-between align-items-center gap-2">
                <strong style="font-size:0.95rem;">
                    <i class="bi bi-layout-sidebar me-2"></i>Menús del sistema
                    <span class="badge bg-light text-dark ms-1" style="font-size:0.72rem;"><?= count($menus_lista) ?></span>
                </strong>
                <button type="button" id="btn_nuevo_menu" class="btn btn-sm btn-light fw-bold">
                    <i class="bi bi-plus-circle me-1"></i>Nuevo menú
                </button>
            </div>
            <div class="scroll-lista">
                <table class="table table-hover align-middle mb-0 table-sm" id="tabla-menus">
                    <thead class="thead-oliva sticky-top">
                        <tr style="font-size:0.85rem;">
                            <th class="py-2 px-3" width="72">ID</th>
                            <th class="py-2">Descripción</th>
                            <th class="py-2 text-center" width="64">Padre</th>
                            <th class="py-2">Programa</th>
                            <th class="py-2 text-center" width="96">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($menus_lista)): ?>
                        <tr>
                            <td colspan="5" class="text-center text-muted py-4 small">No hay menús. Pulse <strong>Nuevo menú</strong>.</td>
                        </tr>
                        <?php else: ?>
                        <?php foreach ($menus_lista as $m): ?>
                        <?php
                        $prog = $m['nom_programa'] ?? 'no_aplica';
                        $indent = max(0, strlen($m['id_menu']) - 2);
                        ?>
                        <tr class="menu-row" data-id="<?= htmlspecialchars($m['id_menu']) ?>" style="font-size:0.875rem;">
                            <td class="fw-bold text-muted small px-3 py-2"><?= htmlspecialchars($m['id_menu']) ?></td>
                            <td class="py-2" style="color:var(--v-oscuro);font-weight:500;">
                                <?= str_repeat('<span style="display:inline-block;width:12px;"></span>', $indent) ?>
                                <?php if ($indent > 0): ?><span class="text-muted me-1">›</span><?php endif; ?>
                                <?= htmlspecialchars($m['nom_menu']) ?>
                            </td>
                            <td class="text-center py-2">
                                <span class="badge bg-light text-dark border" style="font-size:0.72rem;">
                                    <?= htmlspecialchars($m['ind_id_padre']) ?>
                                </span>
                            </td>
                            <td class="py-2 small text-muted"><?= htmlspecialchars($prog) ?></td>
                            <td class="text-center py-2">
                                <div class="btn-group btn-group-sm">
                                    <button type="button"
                                            class="btn btn-outline-primary border-0 btn-editar-menu"
                                            title="Editar"
                                            data-id="<?= htmlspecialchars($m['id_menu']) ?>"
                                            data-nom="<?= htmlspecialchars($m['nom_menu']) ?>"
                                            data-padre="<?= htmlspecialchars($m['ind_id_padre']) ?>"
                                            data-programa="<?= htmlspecialchars($prog) ?>">
                                        <i class="bi bi-pencil-square"></i>
                                    </button>
                                    <form method="POST" class="d-inline" data-smart-confirm
                                          data-smart-confirm-title="Eliminar menú"
                                          data-smart-confirm-message="¿Eliminar el menú «<?= htmlspecialchars($m['nom_menu']) ?>»?"
                                          data-smart-confirm-ok="Eliminar"
                                          data-smart-confirm-variant="danger">
                                        <input type="hidden" name="hid_id_menu" value="<?= htmlspecialchars($m['id_menu']) ?>">
                                        <button type="submit" name="btn_eliminar" class="btn btn-outline-danger border-0" title="Eliminar">
                                            <i class="bi bi-trash3"></i>
                                        </button>
                                    </form>
                                </div>
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

<div class="modal fade modal-form-usuario" id="modalMenu" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content border-0 shadow">
            <div class="modal-header bg-corporativo text-white py-3">
                <div>
                    <h5 class="modal-title fs-6 fw-bold mb-0" id="menu-editor-titulo">Nuevo menú</h5>
                    <p class="small mb-0 opacity-75" id="menu-editor-subtitulo">Opción de navegación del sistema</p>
                </div>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Cerrar"></button>
            </div>
            <form method="POST" id="form_menu" data-watch-unsaved>
                <div class="modal-body" style="background:#f8faf8;">
                    <section class="form-section">
                        <div class="form-section-title">Identificación</div>
                        <div class="row g-3">
                            <div class="col-sm-4">
                                <label class="form-label" for="f_id">ID menú</label>
                                <input type="text" name="txt_id_menu" id="f_id" class="form-control form-control-sm"
                                       required autocomplete="off" placeholder="ej. 0205">
                            </div>
                            <div class="col-sm-8">
                                <label class="form-label" for="f_nom">Descripción</label>
                                <input type="text" name="txt_nom_menu" id="f_nom" class="form-control form-control-sm"
                                       required autocomplete="off" placeholder="Nombre visible">
                            </div>
                        </div>
                    </section>
                    <section class="form-section">
                        <div class="form-section-title">Jerarquía y ruta</div>
                        <div class="row g-3">
                            <div class="col-sm-4">
                                <label class="form-label" for="f_padre">ID padre</label>
                                <input type="text" name="txt_id_padre" id="f_padre" class="form-control form-control-sm"
                                       value="0" autocomplete="off" placeholder="0 = raíz">
                                <div class="form-text">Use <strong>0</strong> si es menú principal.</div>
                            </div>
                            <div class="col-sm-8">
                                <label class="form-label" for="f_programa">Ruta del programa</label>
                                <input type="text" name="txt_nom_programa" id="f_programa" class="form-control form-control-sm"
                                       autocomplete="off" placeholder="src/menu/ejemplo.php">
                                <div class="form-text">Vacío o <strong>no_aplica</strong> si solo agrupa submenús.</div>
                            </div>
                        </div>
                    </section>
                </div>
                <div class="modal-footer border-top">
                    <button type="button" class="btn btn-light btn-sm" data-bs-dismiss="modal">Cancelar</button>
                    <button type="submit" name="btn_guardar" class="btn btn-corporativo btn-sm px-4">
                        <i class="bi bi-save me-1"></i>Guardar
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php
$extra_js = '<script src="../../js/menus.js"></script>';
include __DIR__ . '/../layout/footer.php';
?>
