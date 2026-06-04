<?php
require_once __DIR__ . '/../lib/init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . $smartcset_asset_href . 'index.php');
    exit();
}

$tipos_doc       = [];
$tipos_persona   = [];
$entradas_lista  = [];
$ingresos_hoy    = [];
$puerta_pref     = (int) ($_SESSION['ingreso_puerta_pref'] ?? 0);
$ultimo_id       = (int) ($_SESSION['ultimo_ingreso_id'] ?? 0);

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

    $stmt_list_tipos_persona->execute();
    $tipos_persona = $stmt_list_tipos_persona->fetchAll();

    $stmt_list_entradas->execute();
    $entradas_lista = $stmt_list_entradas->fetchAll();

    $stmt_list_ingresos_hoy->execute();
    $ingresos_hoy = $stmt_list_ingresos_hoy->fetchAll();
} catch (PDOException $e) {
    $w_mensaje     = ErrorHandler::userMessageFromException($e);
    $w_tipo_alerta = 'danger';
}

$page_title     = 'Registro de ingreso';
$active_menu_id = '0102';
$wnom_usuario   = $_SESSION['nom_usuario'];
$hora_servidor  = date('H:i');
$total_hoy      = count($ingresos_hoy);
$_root          = modulosProjectRoot();
$_css_v         = @filemtime($_root . '/css/modulos_ingresos.css') ?: time();
$_css_pt        = @filemtime($_root . '/css/porteria_modos.css') ?: time();
$extra_stylesheets = '<link rel="stylesheet" href="' . htmlspecialchars($smartcset_asset_href)
    . 'css/modulos_ingresos.css?v=' . (int) $_css_v . '">'
    . '<link rel="stylesheet" href="' . htmlspecialchars($smartcset_asset_href)
    . 'css/porteria_modos.css?v=' . (int) $_css_pt . '">';
$pt_reset_escaner = ($w_tipo_alerta === 'success' && $w_mensaje !== '');

include modulosLayout('layout/head.php');
include modulosLayout('layout/sidebar.php');
include modulosLayout('layout/topbar.php');

renderPageFlash($w_mensaje, $w_tipo_alerta);
?>
<div class="ingresos-page">
    <div class="ingresos-layout">
        <div class="ing-col-form">
            <div class="ing-panel ing-panel-form">
                <div class="ing-panel-head">
                    <i class="bi bi-person-plus-fill me-1"></i> Nuevo ingreso
                </div>

                <form method="POST" id="form_ingreso" action="procesar.php" autocomplete="off"
                      data-pt-reset="<?= $pt_reset_escaner ? '1' : '0' ?>">
                    <input type="hidden" name="hid_captura_raw" id="hid_captura_raw" value="">
                    <input type="hidden" name="hid_metodo_aut" id="hid_metodo_aut" value="1">
                    <div class="ing-panel-body">
                        <?php $pt_contexto = 'ingreso'; include __DIR__ . '/../lib/porteria_modos_ui.php'; ?>
                        <div class="ing-field">
                            <label for="txt_documento">Documento de identidad</label>
                            <div class="ing-doc-row">
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
                            <span id="badge_persona" class="badge rounded-pill d-none" role="status"></span>
                            <div id="ingreso_bloqueado_msg" class="ing-bloqueo-msg d-none" role="alert"></div>
                        </div>

                        <div class="ing-field">
                            <label for="sel_tipo_persona">Tipo de persona</label>
                            <select name="sel_tipo_persona" id="sel_tipo_persona"
                                    class="form-select form-select-sm" required>
                                <option value="">Seleccione…</option>
                                <?php foreach ($tipos_persona as $tp): ?>
                                <option value="<?= (int) $tp['id_tipo_persona'] ?>">
                                    <?= htmlspecialchars($tp['nom_tipo_persona']) ?>
                                </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="ing-field">
                            <label>Datos de la persona</label>
                            <div class="ing-nombres-row">
                                <div>
                                    <label class="small text-muted mb-1" for="txt_nombres">Nombres</label>
                                    <input type="text" name="txt_nombres" id="txt_nombres"
                                           class="form-control form-control-sm" required minlength="2"
                                           placeholder="Nombres" autocomplete="off">
                                </div>
                                <div>
                                    <label class="small text-muted mb-1" for="txt_apellidos">Apellidos</label>
                                    <input type="text" name="txt_apellidos" id="txt_apellidos"
                                           class="form-control form-control-sm" required minlength="2"
                                           placeholder="Apellidos" autocomplete="off">
                                </div>
                            </div>
                        </div>

                        <div class="ing-field">
                            <label>Puerta de ingreso</label>
                            <input type="hidden" name="sel_entrada" id="sel_entrada"
                                   value="<?= $puerta_pref > 0 ? $puerta_pref : '' ?>">
                            <div class="ing-puertas" id="puertas_grid" role="group">
                                <?php if (empty($entradas_lista)): ?>
                                <p class="small text-danger mb-0">Sin puertas configuradas.</p>
                                <?php else: ?>
                                <?php foreach ($entradas_lista as $e): ?>
                                <?php
                                $idPuerta = (int) $e['id_entrada'];
                                $sel = ($puerta_pref === $idPuerta) ? ' is-selected' : '';
                                ?>
                                <button type="button" class="ing-puerta<?= $sel ?>"
                                        data-puerta="<?= $idPuerta ?>"
                                        title="<?= htmlspecialchars($e['nom_entrada']) ?>">
                                    <span class="p-num"><?= $idPuerta ?></span>
                                    <span class="p-nom"><?= htmlspecialchars($e['nom_entrada']) ?></span>
                                </button>
                                <?php endforeach; ?>
                                <?php endif; ?>
                            </div>
                            <div class="ing-puerta-error" id="puerta_error">Seleccione una puerta para continuar.</div>
                        </div>

                        <div class="ing-field">
                            <label for="txt_observaciones">Observaciones <span class="text-muted fw-normal">(opcional)</span></label>
                            <textarea name="txt_observaciones" id="txt_observaciones" rows="2"
                                      class="form-control form-control-sm" placeholder="Ej. visita a coordinación"></textarea>
                        </div>
                    </div>

                    <div class="ing-panel-foot">
                        <button type="submit" id="btn_registrar_ingreso" class="btn btn-corporativo btn-ingreso-submit"
                                <?= empty($entradas_lista) ? 'disabled' : '' ?>>
                            <i class="bi bi-check2-circle me-1"></i>Registrar ingreso
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <div class="ing-col-list">
            <div class="ing-panel ing-panel-list">
                <div class="ing-panel-head d-flex justify-content-between align-items-center flex-wrap gap-1">
                    <span><i class="bi bi-clock-history me-1"></i> Ingresos de hoy</span>
                    <span class="meta" title="Cantidad de ingresos hoy y hora del servidor">
                        <?= $total_hoy ?> <?= $total_hoy === 1 ? 'ingreso' : 'ingresos' ?>
                        · <?= htmlspecialchars($hora_servidor) ?>
                    </span>
                </div>

                <div class="ing-panel-body ing-list-scroll p-0">
                    <?php if (empty($ingresos_hoy)): ?>
                    <div class="ing-empty">
                        <i class="bi bi-inbox"></i>
                        <p><strong>Sin registros hoy</strong></p>
                        <p class="small text-muted mt-2">Al guardar un ingreso aparecerá en esta lista.</p>
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
                            <?php foreach ($ingresos_hoy as $row): ?>
                            <?php
                            $esReciente = $ultimo_id > 0 && (int) $row['id_ingreso'] === $ultimo_id;
                            $nomCompleto = trim($row['nom_persona'] . ' ' . $row['ape_persona']);
                            ?>
                            <tr class="<?= $esReciente ? 'ingreso-reciente' : '' ?>">
                                <td class="text-muted fw-semibold"><?= (int) $row['id_ingreso'] ?></td>
                                <td class="text-nowrap"><?= htmlspecialchars(smartcsetFormatDbTimestamp($row['fec_ingreso'], 'H:i')) ?></td>
                                <td>
                                    <span class="v-nom" title="<?= htmlspecialchars($nomCompleto) ?>"><?= htmlspecialchars($nomCompleto) ?></span>
                                    <span class="v-doc"><?= htmlspecialchars($row['id_tipo_docum']) ?> <?= htmlspecialchars((string) $row['id_persona']) ?></span>
                                </td>
                                <td><span class="ing-tipo-badge"><?= htmlspecialchars($row['nom_tipo_persona']) ?></span></td>
                                <td>
                                    <span class="ing-puerta-badge" title="<?= htmlspecialchars($row['nom_entrada_centro']) ?>">
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
                <div class="ing-list-hint">Desplaza para ver todos los registros</div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>
<?php
unset($_SESSION['ultimo_ingreso_id']);
$_js_root = modulosProjectRoot() . '/js';
$_v_cap = @filemtime($_js_root . '/porteria-captura.js') ?: time();
$_v_med = @filemtime($_js_root . '/porteria-medios.js') ?: time();
$_v_ing = @filemtime($_js_root . '/ingresos.js') ?: time();
$h = htmlspecialchars($smartcset_asset_href);
$extra_js = '<script src="' . $h . 'js/porteria-captura.js?v=' . (int) $_v_cap . '"></script>'
    . '<script src="' . $h . 'js/porteria-medios.js?v=' . (int) $_v_med . '"></script>'
    . '<script src="' . $h . 'js/ingresos.js?v=' . (int) $_v_ing . '"></script>';
include modulosLayout('layout/footer.php');
