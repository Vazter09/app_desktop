<?php
require_once __DIR__ . '/../lib/init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . $smartcset_asset_href . 'index.php');
    exit();
}

$tipos_doc   = [];
$salidas_hoy = [];
$ultimo_id   = (int) ($_SESSION['ultimo_salida_id'] ?? 0);

if (!empty($_SESSION['flash_msg'])) {
    $w_mensaje     = $_SESSION['flash_msg'];
    $w_tipo_alerta = $_SESSION['flash_tipo'] ?? 'success';
    unset($_SESSION['flash_msg'], $_SESSION['flash_tipo']);
} else {
    $w_mensaje     = '';
    $w_tipo_alerta = 'success';
}

try {
    $stmt_list_tipos_doc->execute();
    $tipos_doc = $stmt_list_tipos_doc->fetchAll();

    $stmt_list_salidas_hoy->execute();
    $salidas_hoy = $stmt_list_salidas_hoy->fetchAll();
} catch (PDOException $e) {
    $w_mensaje     = ErrorHandler::userMessageFromException($e);
    $w_tipo_alerta = 'danger';
}

$page_title     = 'Registro de salida';
$active_menu_id = '0103';
$wnom_usuario   = $_SESSION['nom_usuario'];
$hora_servidor  = date('H:i');
$total_hoy      = count($salidas_hoy);
$_root          = modulosProjectRoot();
$_css_v         = @filemtime($_root . '/css/modulos_salidas.css') ?: time();
$_css_pt        = @filemtime($_root . '/css/porteria_modos.css') ?: time();
$h              = htmlspecialchars($smartcset_asset_href);
$extra_stylesheets = '<link rel="stylesheet" href="' . $h . 'css/modulos_salidas.css?v=' . (int) $_css_v . '">'
    . '<link rel="stylesheet" href="' . $h . 'css/porteria_modos.css?v=' . (int) $_css_pt . '">';
$pt_reset_escaner = ($w_tipo_alerta === 'success' && $w_mensaje !== '');

include modulosLayout('layout/head.php');
include modulosLayout('layout/sidebar.php');
include modulosLayout('layout/topbar.php');

renderPageFlash($w_mensaje, $w_tipo_alerta);
?>
<div class="salidas-page">
    <div class="salidas-layout">
        <div class="sal-col-form">
            <div class="sal-panel sal-panel-form">
                <div class="sal-panel-head">
                    <i class="bi bi-box-arrow-right me-1"></i> Registrar salida
                </div>

                <form method="POST" id="form_salida" action="procesar.php" autocomplete="off"
                      data-pt-reset="<?= $pt_reset_escaner ? '1' : '0' ?>">
                    <input type="hidden" name="hid_id_ingreso" id="hid_id_ingreso" value="">
                    <input type="hidden" name="hid_captura_raw" id="hid_captura_raw" value="">
                    <input type="hidden" name="hid_metodo_aut" id="hid_metodo_aut" value="1">
                    <div class="sal-panel-body">
                        <?php $pt_contexto = 'salida'; include __DIR__ . '/../lib/porteria_modos_ui.php'; ?>
                        <div class="sal-field">
                            <label for="txt_documento">Documento de identidad</label>
                            <div class="sal-doc-row">
                                <select name="sel_tipo_doc" id="sel_tipo_doc" class="form-select form-select-sm tipo-doc" required>
                                    <?php foreach ($tipos_doc as $t): ?>
                                    <option value="<?= htmlspecialchars($t['id_tipo_docum']) ?>">
                                        <?= htmlspecialchars($t['id_tipo_docum']) ?>
                                    </option>
                                    <?php endforeach; ?>
                                </select>
                                <input type="text" name="txt_documento" id="txt_documento"
                                       class="form-control form-control-sm num-doc"
                                       data-documento-captura="1" required
                                       placeholder="Número de documento"
                                       autocomplete="off">
                            </div>
                            <span id="badge_salida" class="badge rounded-pill d-none" role="status"></span>
                            <div id="salida_aviso_msg" class="sal-aviso-msg d-none" role="alert"></div>
                        </div>

                        <div id="bloque_ingreso" class="sal-resumen d-none" aria-live="polite">
                            <div class="sal-resumen-title">Ingreso activo</div>
                            <p class="sal-resumen-nom mb-1" id="resumen_nombre"></p>
                            <ul class="sal-resumen-list mb-0">
                                <li><span class="text-muted">Ingreso #</span> <strong id="resumen_id_ingreso"></strong></li>
                                <li><span class="text-muted">Hora ingreso</span> <strong id="resumen_hora_ingreso"></strong></li>
                                <li><span class="text-muted">Tipo</span> <strong id="resumen_tipo"></strong></li>
                                <li><span class="text-muted">Puerta</span> <strong id="resumen_puerta"></strong></li>
                            </ul>
                        </div>

                        <div class="sal-field">
                            <label for="txt_observaciones">Observaciones <span class="text-muted fw-normal">(opcional)</span></label>
                            <textarea name="txt_observaciones" id="txt_observaciones" rows="2"
                                      class="form-control form-control-sm"
                                      placeholder="Ej. salida por puerta principal"></textarea>
                        </div>
                    </div>

                    <div class="sal-panel-foot">
                        <button type="submit" class="btn btn-corporativo btn-salida-submit" id="btn_registrar_salida" disabled>
                            <i class="bi bi-box-arrow-right me-1"></i>Registrar salida
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <div class="sal-col-list">
            <div class="sal-panel sal-panel-list">
                <div class="sal-panel-head d-flex justify-content-between align-items-center flex-wrap gap-1">
                    <span><i class="bi bi-clock-history me-1"></i> Salidas de hoy</span>
                    <span class="meta" title="Salidas registradas hoy y hora del servidor">
                        <?= $total_hoy ?> <?= $total_hoy === 1 ? 'salida' : 'salidas' ?>
                        · <?= htmlspecialchars($hora_servidor) ?>
                    </span>
                </div>

                <div class="sal-panel-body sal-list-scroll p-0">
                    <?php if (empty($salidas_hoy)): ?>
                    <div class="sal-empty">
                        <i class="bi bi-inbox"></i>
                        <p><strong>Sin salidas hoy</strong></p>
                        <p class="small text-muted mt-2">Al registrar una salida aparecerá en esta lista.</p>
                    </div>
                    <?php else: ?>
                    <table class="table table-hover table-sm mb-0">
                        <thead class="thead-oliva">
                            <tr>
                                <th style="width:2.5rem">#</th>
                                <th style="width:3rem">Hora</th>
                                <th>Persona</th>
                                <th style="width:4.5rem">Tipo</th>
                                <th style="width:4rem">Puerta</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($salidas_hoy as $row): ?>
                            <?php
                            $esReciente = $ultimo_id > 0 && (int) $row['id_ingreso'] === $ultimo_id;
                            $nomCompleto = trim($row['nom_persona'] . ' ' . $row['ape_persona']);
                            ?>
                            <tr class="<?= $esReciente ? 'salida-reciente' : '' ?>">
                                <td class="text-muted fw-semibold"><?= (int) $row['id_ingreso'] ?></td>
                                <td class="text-nowrap"><?= htmlspecialchars(smartcsetFormatDbTimestamp($row['fec_salida'], 'H:i')) ?></td>
                                <td>
                                    <span class="v-nom" title="<?= htmlspecialchars($nomCompleto) ?>"><?= htmlspecialchars($nomCompleto) ?></span>
                                    <span class="v-doc"><?= htmlspecialchars($row['id_tipo_docum']) ?> <?= htmlspecialchars((string) $row['id_persona']) ?></span>
                                </td>
                                <td><span class="sal-tipo-badge"><?= htmlspecialchars($row['nom_tipo_persona']) ?></span></td>
                                <td>
                                    <span class="sal-puerta-badge" title="<?= htmlspecialchars($row['nom_entrada_centro']) ?>">
                                        <?= (int) $row['id_entrada_centro'] ?>
                                    </span>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                    <?php endif; ?>
                </div>

                <?php if ($total_hoy > 8): ?>
                <div class="sal-list-hint">Desplaza para ver todas las salidas</div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>
<?php
unset($_SESSION['ultimo_salida_id']);
$_js_root = modulosProjectRoot() . '/js';
$_v_cap = @filemtime($_js_root . '/porteria-captura.js') ?: time();
$_v_med = @filemtime($_js_root . '/porteria-medios.js') ?: time();
$_v_sal = @filemtime($_js_root . '/salidas.js') ?: time();
$extra_js = '<script src="' . $h . 'js/porteria-captura.js?v=' . (int) $_v_cap . '"></script>'
    . '<script src="' . $h . 'js/porteria-medios.js?v=' . (int) $_v_med . '"></script>'
    . '<script src="' . $h . 'js/salidas.js?v=' . (int) $_v_sal . '"></script>';
include modulosLayout('layout/footer.php');
