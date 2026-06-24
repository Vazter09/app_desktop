<?php
require_once __DIR__ . '/init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

$w_mensaje = '';
$w_tipo_alerta = 'success';
$usr_audit      = $_SESSION['id_usuario'];
$entradas_lista  = [];
$sedes_lista     = [];
$entradas_llenas = false;

try {
    $stmt_sedes = $pdo->query(
        'SELECT s.id_centro, s.id_sede, c.nom_centro, s.nom_sede
         FROM tab_sedes s
         INNER JOIN tab_centros c ON c.id_centro = s.id_centro
         ORDER BY c.nom_centro, s.id_sede'
    );
    $sedes_lista = $stmt_sedes->fetchAll(PDO::FETCH_ASSOC);

    $stmt_list_entradas->execute();
    $entradas_lista = $stmt_list_entradas->fetchAll();
    $entradas_llenas = count($entradas_lista) >= 9;
} catch (PDOException $e) {
    $w_mensaje     = 'Error al cargar entradas: ' . ErrorHandler::handleDatabaseException($e)['message'];
    $w_tipo_alerta = 'danger';
}

$page_title     = 'Entradas al centro';
$active_menu_id = '0101';
$wnom_usuario   = $_SESSION['nom_usuario'];
$_crud_hl_v = @filemtime(dirname(__DIR__, 3) . '/public/assets/css/crud-row-highlight.css') ?: time();
$extra_stylesheets = '<link rel="stylesheet" href="' . htmlspecialchars(smartcsetAsset('css/crud-row-highlight.css')) . '?v=' . (int) $_crud_hl_v . '">';

include modulosLayout('layout/head.php');
include modulosLayout('layout/sidebar.php');
include modulosLayout('layout/topbar.php');
?>

<?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

<?php if ($sedes_lista === []): ?>
<div class="alert alert-warning small mb-3">
    No hay sedes registradas en <code>tab_sedes</code>. Cargue la cadena institucional (centro + sede) antes de crear entradas.
</div>
<?php endif; ?>

<div class="row g-3">
    <div class="col-12">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-corporativo py-2 d-flex flex-wrap justify-content-between align-items-center gap-2">
                <strong style="font-size:0.95rem;">
                    <i class="bi bi-door-open-fill me-2"></i>Entradas al centro
                    <span class="badge bg-light text-dark ms-1" style="font-size:0.72rem;"><?= count($entradas_lista) ?></span>
                </strong>
                <button type="button" id="btn_nueva_entrada" class="btn btn-sm btn-light fw-bold"
                    <?php
                    if ($sedes_lista === []) {
                        echo 'disabled title="Registre sedes primero"';
                    } elseif ($entradas_llenas) {
                        echo 'disabled title="Máximo 9 entradas (códigos 1–9)"';
                    }
                    ?>>
                    <i class="bi bi-plus-circle me-1"></i>Nueva entrada
                </button>
            </div>
            <div class="table-responsive scroll-lista">
                <table class="table table-hover align-middle mb-0 table-sm" id="tabla-entradas">
                    <thead class="thead-oliva sticky-top">
                        <tr style="font-size:0.85rem;">
                            <th class="ps-3 py-2 text-center" width="80">Código</th>
                            <th class="py-2">Nombre</th>
                            <th class="py-2">Centro / Sede</th>
                            <th class="text-center py-2" width="100">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($entradas_lista)): ?>
                        <tr>
                            <td colspan="4" class="text-center text-muted py-4 small">
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
                            <td class="py-2 small text-muted">
                                <?= htmlspecialchars($b['nom_centro']) ?>
                                <span class="text-secondary">·</span>
                                Sede <?= (int) $b['id_sede'] ?>:
                                <?= htmlspecialchars($b['nom_sede']) ?>
                            </td>
                            <td class="text-center py-2">
                                <div class="btn-group btn-group-sm">
                                    <button type="button"
                                            class="btn btn-outline-primary border-0 btn-editar-entrada"
                                            title="Editar"
                                            data-id="<?= (int) $b['id_entrada'] ?>"
                                            data-nom="<?= htmlspecialchars($b['nom_entrada']) ?>"
                                            data-centro="<?= (int) $b['id_centro'] ?>"
                                            data-sede="<?= (int) $b['id_sede'] ?>">
                                        <i class="bi bi-pencil-square"></i>
                                    </button>
                                    <form method="POST" class="d-inline form-eliminar-entrada" data-smart-confirm
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
                <input type="hidden" name="hid_id_entrada" id="hid_id_entrada" value="">
                <div class="modal-body" style="background:#f8faf8;">
                    <div class="form-section mb-0">
                        <div class="form-section-title">Datos de la entrada</div>
                        <div id="f_codigo_badge" class="alert alert-light border small py-2 mb-3 d-none" role="status">
                            Código asignado: <strong id="f_codigo_text"></strong>
                        </div>
                        <div class="row g-3">
                            <div class="col-12">
                                <label class="form-label" for="f_sede">Centro y sede <span class="text-danger">*</span></label>
                                <select name="sel_sede" id="f_sede" class="form-select form-select-sm" required>
                                    <option value="">— Seleccione sede —</option>
                                    <?php foreach ($sedes_lista as $s): ?>
                                    <?php
                                        $optVal = (int) $s['id_centro'] . ':' . (int) $s['id_sede'];
                                        $optLbl = sprintf(
                                            '%s — %s (centro %s, sede %s)',
                                            $s['nom_centro'],
                                            $s['nom_sede'],
                                            $s['id_centro'],
                                            $s['id_sede']
                                        );
                                    ?>
                                    <option value="<?= htmlspecialchars($optVal) ?>">
                                        <?= htmlspecialchars($optLbl) ?>
                                    </option>
                                    <?php endforeach; ?>
                                </select>
                                <div class="form-text">La entrada queda asociada a esa sede.</div>
                            </div>
                            <div class="col-12">
                                <label class="form-label" for="f_nom">Nombre de la entrada <span class="text-danger">*</span></label>
                                <input type="text" name="txt_nom_entrada" id="f_nom" class="form-control form-control-sm"
                                       required minlength="5" placeholder="Ej. Entrada principal">
                                <div class="form-text" id="f_nom_hint">
                                    Al crear, el sistema asigna automáticamente el siguiente código libre (1–9).
                                </div>
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
$_asset_root = dirname(__DIR__, 3) . '/public/assets';
$_v_entradas_js = @filemtime($_asset_root . '/js/core/entradas.js') ?: time();
$_v_http = @filemtime($_asset_root . '/js/services/http-client.js') ?: time();
$_v_er = @filemtime($_asset_root . '/js/services/entradas-router.js') ?: time();
$extra_js = '<script src="' . htmlspecialchars(smartcsetAsset('js/services/http-client.js')) . '?v=' . (int) $_v_http . '"></script>'
    . '<script src="' . htmlspecialchars(smartcsetAsset('js/services/entradas-router.js')) . '?v=' . (int) $_v_er . '"></script>'
    . '<script src="' . htmlspecialchars(smartcsetAsset('js/core/entradas.js')) . '?v=' . (int) $_v_entradas_js . '"></script>';
include modulosLayout('layout/footer.php');
?>
