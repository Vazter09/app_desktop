<?php
require_once __DIR__ . '/init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . $smartcset_asset_href . 'index.php');
    exit();
}

$w_mensaje     = "";
$w_tipo_alerta = "success";
$usr_audit     = $_SESSION['id_usuario'];
$entradas_lista = [];
/** V.1.5: tab_entradas_centro requiere centro y sede (ver seed_acceso_dev.sql) */
const CSET_ID_CENTRO_DEV = 9001;
const CSET_ID_SEDE_DEV = 1;

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        if (isset($_POST['btn_guardar'])) {
            $w_id  = (int) ($_POST['txt_id_entrada'] ?? 0);
            $w_nom = strtoupper(trim($_POST['txt_nom_entrada'] ?? ''));

            if ($w_id < 1 || $w_id > 9) {
                throw new Exception('El código de entrada debe ser un número entre 1 y 9.');
            }
            if (strlen($w_nom) < 3) {
                throw new Exception('El nombre de la entrada debe tener al menos 3 caracteres.');
            }

            $stmt_check = $pdo->prepare(
                "SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = ?::NUMERIC"
            );
            $stmt_check->execute([$w_id]);

            if ($stmt_check->fetch()) {
                $stmt_upd = $pdo->prepare(
                    "UPDATE tab_entradas_centro
                     SET nom_entrada_centro = ?::VARCHAR,
                         usr_update = ?::VARCHAR,
                         fec_update = CURRENT_TIMESTAMP
                     WHERE id_entrada_centro = ?::NUMERIC"
                );
                $stmt_upd->execute([$w_nom, $usr_audit, $w_id]);
                $w_mensaje = "Entrada actualizada correctamente.";
            } else {
                $stmt_ins = $pdo->prepare(
                    "INSERT INTO tab_entradas_centro (
                         id_entrada_centro, nom_entrada_centro, id_centro, id_sede,
                         usr_insert, fec_insert
                     ) VALUES (?::NUMERIC, ?::VARCHAR, ?::NUMERIC, ?::NUMERIC, ?::VARCHAR, CURRENT_TIMESTAMP)"
                );
                $stmt_ins->execute([$w_id, $w_nom, CSET_ID_CENTRO_DEV, CSET_ID_SEDE_DEV, $usr_audit]);
                $w_mensaje = "Entrada registrada correctamente.";
            }
        }

        if (isset($_POST['btn_eliminar'])) {
            $w_id_del = (int) ($_POST['hid_id_entrada'] ?? 0);
            $stmt_del = $pdo->prepare(
                "DELETE FROM tab_entradas_centro WHERE id_entrada_centro = ?::NUMERIC"
            );
            $stmt_del->execute([$w_id_del]);
            $w_mensaje = "Entrada eliminada correctamente.";
        }
    } catch (PDOException $e) {
        if ($e->getCode() === '23503') {
            $w_mensaje = "No se puede eliminar: la entrada está en uso en registros de ingreso.";
        } else {
            $w_mensaje = ErrorHandler::handleDatabaseException($e)['message'];
        }
        $w_tipo_alerta = "danger";
    } catch (Exception $e) {
        $w_mensaje     = ErrorHandler::handleValidationException($e)['message'];
        $w_tipo_alerta = "danger";
    }
}

try {
    $stmt_list_entradas->execute();
    $entradas_lista = $stmt_list_entradas->fetchAll();
} catch (PDOException $e) {
    $w_mensaje     = "Error al cargar entradas: " . ErrorHandler::handleDatabaseException($e)['message'];
    $w_tipo_alerta = "danger";
}

$page_title     = 'Entradas al centro';
$active_menu_id = '0101';
$wnom_usuario   = $_SESSION['nom_usuario'];
$_crud_hl_v = @filemtime(dirname(__DIR__, 3) . '/css/crud-row-highlight.css') ?: time();
$extra_stylesheets = '<link rel="stylesheet" href="' . htmlspecialchars($smartcset_asset_href, ENT_QUOTES, 'UTF-8')
    . 'css/crud-row-highlight.css?v=' . (int) $_crud_hl_v . '">';

include modulosLayout('layout/head.php');
include modulosLayout('layout/sidebar.php');
include modulosLayout('layout/topbar.php');
?>

<?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

<div class="row g-3">
    <div class="col-12">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-corporativo py-2 d-flex flex-wrap justify-content-between align-items-center gap-2">
                <strong style="font-size:0.95rem;">
                    <i class="bi bi-door-open-fill me-2"></i>Entradas al centro
                    <span class="badge bg-light text-dark ms-1" style="font-size:0.72rem;"><?= count($entradas_lista) ?></span>
                </strong>
                <button type="button" id="btn_nueva_entrada" class="btn btn-sm btn-light fw-bold">
                    <i class="bi bi-plus-circle me-1"></i>Nueva entrada
                </button>
            </div>
            <div class="table-responsive scroll-lista">
                <table class="table table-hover align-middle mb-0 table-sm" id="tabla-entradas">
                    <thead class="thead-oliva sticky-top">
                        <tr style="font-size:0.85rem;">
                            <th class="ps-3 py-2 text-center" width="80">Código</th>
                            <th class="py-2">Nombre</th>
                            <th class="text-center py-2" width="100">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($entradas_lista)): ?>
                        <tr>
                            <td colspan="3" class="text-center text-muted py-4 small">
                                No hay entradas registradas. Pulse <strong>Nueva entrada</strong>.
                            </td>
                        </tr>
                        <?php else: ?>
                        <?php foreach ($entradas_lista as $b): ?>
                        <tr data-id="<?= (int) $b['id_entrada'] ?>" style="font-size:0.875rem;">
                            <td class="ps-3 fw-bold py-2 text-center"><?= (int) $b['id_entrada'] ?></td>
                            <td class="py-2" style="color:var(--v-oscuro);font-weight:500;">
                                <?= htmlspecialchars($b['nom_entrada']) ?>
                            </td>
                            <td class="text-center py-2">
                                <div class="btn-group btn-group-sm">
                                    <button type="button"
                                            class="btn btn-outline-primary border-0 btn-editar-entrada"
                                            title="Editar"
                                            data-id="<?= (int) $b['id_entrada'] ?>"
                                            data-nom="<?= htmlspecialchars($b['nom_entrada']) ?>">
                                        <i class="bi bi-pencil-square"></i>
                                    </button>
                                    <form method="POST" class="d-inline" data-smart-confirm
                                          data-smart-confirm-title="Eliminar entrada"
                                          data-smart-confirm-message="¿Eliminar la entrada «<?= htmlspecialchars($b['nom_entrada']) ?>»?"
                                          data-smart-confirm-ok="Eliminar"
                                          data-smart-confirm-variant="danger">
                                        <input type="hidden" name="hid_id_entrada" value="<?= (int) $b['id_entrada'] ?>">
                                        <button type="submit" name="btn_eliminar" class="btn btn-outline-danger border-0" title="Eliminar">
                                            <i class="bi bi-trash-fill"></i>
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

<div class="modal fade modal-form-usuario" id="modalEntrada" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow">
            <div class="modal-header bg-corporativo text-white py-3">
                <div>
                    <h5 class="modal-title fs-6 fw-bold mb-0" id="entrada-editor-titulo">Nueva entrada</h5>
                    <p class="small mb-0 opacity-75" id="entrada-editor-subtitulo">Puerta o acceso del centro formativo</p>
                </div>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Cerrar"></button>
            </div>
            <form method="POST" id="form_entrada" data-watch-unsaved>
                <div class="modal-body" style="background:#f8faf8;">
                    <div class="form-section mb-0">
                        <div class="form-section-title">Datos de la entrada</div>
                        <div class="row g-3">
                            <div class="col-sm-4">
                                <label class="form-label" for="f_id">Código</label>
                                <input type="text" name="txt_id_entrada" id="f_id"
                                       class="form-control form-control-sm input-numeric"
                                       required inputmode="numeric" pattern="[1-9]" maxlength="1"
                                       data-numeric-only="1-9" autocomplete="off" placeholder="1–9">
                                <div class="form-text">Un solo dígito por centro.</div>
                            </div>
                            <div class="col-sm-8">
                                <label class="form-label" for="f_nom">Nombre</label>
                                <input type="text" name="txt_nom_entrada" id="f_nom" class="form-control form-control-sm"
                                       required minlength="3" placeholder="Ej. Entrada principal">
                            </div>
                        </div>
                    </div>
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
$extra_js = '<script src="' . htmlspecialchars($smartcset_asset_href) . 'js/entradas.js"></script>';
include modulosLayout('layout/footer.php');
?>
