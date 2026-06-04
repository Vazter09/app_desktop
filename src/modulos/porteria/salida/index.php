<?php
require_once __DIR__ . '/../lib/init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . $smartcset_asset_href . 'index.php');
    exit();
}

$tipos_doc      = [];
$salidas_hoy    = [];
$ultimo_id      = (int) ($_SESSION['ultimo_salida_id'] ?? 0);

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
$extra_stylesheets = '<link rel="stylesheet" href="' . htmlspecialchars($smartcset_asset_href)
    . 'css/modulos_salidas.css?v=' . (int) $_css_v . '">'
    . '<link rel="stylesheet" href="' . htmlspecialchars($smartcset_asset_href)
    . 'css/porteria_modos.css?v=' . (int) $_css_pt . '">';
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
                                <td class="text-nowrap"><?= htmlspecialchars(date('H:i', strtotime($row['fec_salida']))) ?></td>
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
<?php unset($_SESSION['ultimo_salida_id']); ?>

<style>
/* ========================================================
   SMARTCSET — MODAL REGISTRO SALIDA (carrusel 2 pasos)
   Idéntico a ingreso, solo 2 pasos y sin selección de puerta
   ======================================================== */

/* ---- Tokens por tema ---- */
:root {
    --dm-bg:         rgba(8, 20, 16, 0.82);
    --dm-border:     rgba(0,229,176, 0.18);
    --dm-shine:      rgba(255,255,255,0.06);
    --dm-key-bg:     rgba(0,50,40, 0.55);
    --dm-key-brd:    rgba(0,229,176, 0.16);
    --dm-key-col:    #c8ece0;
    --dm-disp-bg:    rgba(0,30,24, 0.70);
    --dm-lbl:        rgba(0,229,176, 0.65);
    --dm-muted:      rgba(200,236,224, 0.45);
    --dm-shadow:     0 40px 80px rgba(0,0,0,0.70), 0 0 0 1px rgba(0,229,176,0.08), inset 0 1px 0 rgba(255,255,255,0.04);
    --dm-num-col:    var(--cyan, #00e5b0);
    --dm-accent:     var(--cyan, #00e5b0);
    --dm-gap:        8px;
    --dm-pad:        16px;
    --dm-radius:     24px;
    --dm-key-fs:     1.15rem;
    --dm-num-fs:     1.8rem;
}
.light-theme {
    --dm-bg:         rgba(248,252,250, 0.92);
    --dm-border:     rgba(0,77,64, 0.15);
    --dm-shine:      rgba(255,255,255,0.95);
    --dm-key-bg:     rgba(0,77,64, 0.06);
    --dm-key-brd:    rgba(0,77,64, 0.14);
    --dm-key-col:    #0a1e16;
    --dm-disp-bg:    rgba(0,77,64, 0.04);
    --dm-lbl:        #004d40;
    --dm-muted:      rgba(10,30,22, 0.45);
    --dm-shadow:     0 20px 56px rgba(0,77,64,0.14), 0 0 0 1px rgba(0,77,64,0.09);
    --dm-num-col:    var(--v-oscuro, #004d40);
    --dm-accent:     var(--v-oscuro, #004d40);
}

/* ---- Backdrop ---- */
.modal-backdrop {
    backdrop-filter: blur(10px) !important;
    -webkit-backdrop-filter: blur(10px) !important;
    background: rgba(0,0,0,0.45) !important;
}

/* ---- Dialog ---- */
#documentModal .modal-dialog {
    width: min(380px, calc(100vw - 24px));
    margin: auto;
    transition: transform .30s cubic-bezier(.34,1.4,.64,1), opacity .24s ease;
}
#documentModal.fade:not(.show) .modal-dialog {
    transform: translateY(20px) scale(0.95); opacity: 0;
}

/* ---- Glass container ---- */
#documentModal .modal-content {
    background: var(--dm-bg) !important;
    backdrop-filter: blur(36px) saturate(200%) !important;
    -webkit-backdrop-filter: blur(36px) saturate(200%) !important;
    border: 1px solid var(--dm-border) !important;
    border-radius: var(--dm-radius) !important;
    box-shadow: var(--dm-shadow) !important;
    overflow: hidden;
    position: relative;
}
/* Brillo diagonal superior */
#documentModal .modal-content::before {
    content: '';
    position: absolute; top: 0; left: 0; right: 0; height: 40%;
    background: linear-gradient(160deg, var(--dm-shine) 0%, transparent 100%);
    pointer-events: none; z-index: 0; border-radius: var(--dm-radius);
}
#documentModal .modal-content > * { position: relative; z-index: 1; }

/* ---- Cabecera: logo marca + paso + cerrar ---- */
#dm-header {
    display: flex; align-items: center; justify-content: space-between;
    padding: 16px var(--dm-pad) 0;
    gap: 10px;
}
#dm-brand {
    display: flex; align-items: center; gap: 8px;
}
#dm-brand-icon {
    width: 32px; height: 32px; border-radius: 9px;
    background: linear-gradient(135deg, var(--dm-accent), rgba(0,229,176,.3));
    display: flex; align-items: center; justify-content: center;
    box-shadow: 0 4px 12px rgba(0,229,176,.25);
    flex-shrink: 0;
}
#dm-brand-icon svg { width: 16px; height: 16px; color: #041210; }
#dm-brand-text { display: flex; flex-direction: column; }
#dm-brand-name {
    font-size: 0.78rem; font-weight: 800; letter-spacing: 0.06em;
    text-transform: uppercase; color: var(--dm-key-col); line-height: 1;
}
#dm-brand-sub {
    font-size: 0.65rem; color: var(--dm-muted); margin-top: 1px;
}
#dm-x {
    width: 28px; height: 28px; border-radius: 8px; flex-shrink: 0;
    background: var(--dm-key-bg); border: 1px solid var(--dm-key-brd);
    color: var(--dm-muted); cursor: pointer;
    display: flex; align-items: center; justify-content: center;
    transition: all .15s ease;
}
#dm-x:hover { background: rgba(255,60,80,.18); border-color: rgba(255,60,80,.4); color: #ff5566; }

/* ---- Indicador de pasos ---- */
#dm-steps {
    display: flex; align-items: center; justify-content: center;
    gap: 6px; padding: 14px var(--dm-pad) 0;
}
.dm-step-dot {
    height: 3px; border-radius: 2px;
    background: var(--dm-key-brd);
    transition: all .3s ease;
}
.dm-step-dot.active   { background: var(--dm-accent); width: 22px; }
.dm-step-dot.done     { background: rgba(0,229,176,.40); width: 10px; }
.dm-step-dot.pending  { width: 10px; }

/* ---- Separador fino ---- */
.dm-sep {
    height: 1px; margin: 12px var(--dm-pad) 0;
    background: linear-gradient(90deg, transparent, var(--dm-border) 30%, var(--dm-border) 70%, transparent);
}

/* ---- Etiqueta de sección ---- */
.dm-section-label {
    font-size: 0.68rem; font-weight: 700; letter-spacing: 0.09em; text-transform: uppercase;
    color: var(--dm-lbl); padding: 10px var(--dm-pad) 4px;
}

/* ---- PASO 1: Display documento ---- */
#dm-display {
    background: var(--dm-disp-bg);
    border: 1px solid var(--dm-border);
    border-radius: 14px;
    margin: 8px var(--dm-pad) 0;
    padding: 12px 18px;
    min-height: 52px;
    display: flex; align-items: center; justify-content: space-between;
    gap: 10px;
}
#dm-disp-label {
    font-size: 0.65rem; font-weight: 700; letter-spacing: 0.08em;
    text-transform: uppercase; color: var(--dm-muted); white-space: nowrap;
}
#dm-num {
    font-size: var(--dm-num-fs); font-weight: 700;
    letter-spacing: 0.12em; line-height: 1;
    font-family: 'SF Mono','Fira Code','Courier New',monospace;
    color: var(--dm-num-col);
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    flex: 1; text-align: right;
}
#dm-num.placeholder { opacity: 0.25; letter-spacing: 0.06em; }

/* ---- Teclado numérico ---- */
#dm-keypad {
    display: grid; grid-template-columns: repeat(3,1fr);
    gap: var(--dm-gap); margin: 8px var(--dm-pad) var(--dm-pad);
}
.dm-k {
    aspect-ratio: 1.1; min-height: 46px;
    background: var(--dm-key-bg); border: 1px solid var(--dm-key-brd);
    border-radius: 13px; color: var(--dm-key-col);
    font-size: var(--dm-key-fs); font-weight: 600;
    cursor: pointer; user-select: none;
    display: flex; align-items: center; justify-content: center;
    box-shadow: 0 1px 0 rgba(255,255,255,0.04), inset 0 -1px 0 rgba(0,0,0,0.15);
    transition: background .12s, border-color .12s, transform .09s, box-shadow .12s;
    -webkit-tap-highlight-color: transparent;
}
.dm-k:hover  {
    background: rgba(0,229,176,.12); border-color: var(--dm-accent);
    box-shadow: 0 4px 14px rgba(0,229,176,.15), inset 0 -1px 0 rgba(0,0,0,0.10);
}
.dm-k:active { transform: scale(0.90); box-shadow: none; }
.dm-k.k-zero { grid-column: span 2; aspect-ratio: auto; padding: 13px 0; }
.dm-k.k-del  {
    color: #ff7080; border-color: rgba(255,60,80,.20);
    background: rgba(255,60,80,.08);
    box-shadow: inset 0 -1px 0 rgba(0,0,0,0.12);
}
.dm-k.k-del:hover { background: rgba(255,60,80,.18); border-color: rgba(255,60,80,.5); }
.dm-k.k-del svg   { width: 18px; height: 18px; pointer-events: none; }

/* ---- PASO 2: Tarjeta persona (reutilizar nombre pero para ingreso) ---- */
#dm-persona-card {
    margin: 8px var(--dm-pad) 0;
    background: var(--dm-disp-bg);
    border: 1px solid var(--dm-border);
    border-radius: 16px; padding: 16px;
    display: flex; flex-direction: column; gap: 10px;
}
#dm-persona-avatar {
    width: 46px; height: 46px; border-radius: 14px; flex-shrink: 0;
    background: linear-gradient(135deg, rgba(0,229,176,.25), rgba(0,229,176,.08));
    border: 1px solid var(--dm-border);
    display: flex; align-items: center; justify-content: center;
}
#dm-persona-avatar svg { width: 22px; height: 22px; color: var(--dm-accent); }
#dm-persona-top { display: flex; align-items: center; gap: 12px; }
#dm-persona-info { flex: 1; min-width: 0; }
#dm-persona-nombre {
    font-size: 1.0rem; font-weight: 800; line-height: 1.2;
    color: var(--dm-key-col);
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
#dm-persona-tipo {
    font-size: 0.72rem; font-weight: 600; color: var(--dm-lbl);
    margin-top: 3px; display: flex; align-items: center; gap: 5px;
}
.dm-tipo-dot {
    width: 6px; height: 6px; border-radius: 50%;
    background: var(--dm-accent); display: inline-block; flex-shrink: 0;
}
#dm-persona-doc-row {
    display: flex; align-items: center; gap: 8px;
    padding: 8px 12px; border-radius: 10px;
    background: rgba(0,229,176,.05); border: 1px solid rgba(0,229,176,.10);
}
#dm-persona-doc-row svg { width: 13px; height: 13px; color: var(--dm-lbl); flex-shrink: 0; }
#dm-persona-doc-text {
    font-size: 0.78rem; font-weight: 700; color: var(--dm-muted);
    font-family: 'SF Mono','Courier New',monospace; letter-spacing: 0.06em;
}
#dm-persona-nueva {
    display: none; text-align: center; padding: 10px;
}
#dm-persona-nueva .dm-nueva-ico {
    width: 40px; height: 40px; border-radius: 12px; margin: 0 auto 8px;
    background: rgba(255,180,0,.10); border: 1px solid rgba(255,180,0,.20);
    display: flex; align-items: center; justify-content: center;
}
#dm-persona-nueva .dm-nueva-ico svg { width: 20px; height: 20px; color: #ffb400; }
#dm-persona-nueva p { font-size: 0.78rem; color: var(--dm-muted); margin: 0; }
#dm-persona-nueva strong { color: var(--dm-key-col); }

/* Pregunta confirmación */
#dm-confirm-question {
    margin: 10px var(--dm-pad) 0;
    font-size: 0.80rem; color: var(--dm-muted); text-align: center; line-height: 1.5;
}
#dm-confirm-question strong { color: var(--dm-key-col); }

/* Botones Sí / No */
#dm-confirm-btns {
    display: grid; grid-template-columns: 1fr 1fr;
    gap: 8px; margin: 8px var(--dm-pad) var(--dm-pad);
}
.dm-btn-si, .dm-btn-no {
    padding: 12px; border-radius: 13px; min-height: 46px;
    font-size: 0.88rem; font-weight: 700; letter-spacing: 0.03em;
    cursor: pointer; transition: all .18s ease; border: 1.5px solid;
    display: flex; align-items: center; justify-content: center; gap: 7px;
}
.dm-btn-si {
    background: linear-gradient(135deg, rgba(0,229,176,.22), rgba(0,229,176,.10));
    border-color: var(--dm-accent); color: var(--dm-accent);
}
.dm-btn-si svg { width: 16px; height: 16px; }
.dm-btn-si:hover { background: var(--dm-accent); color: #041210; box-shadow: 0 6px 20px rgba(0,229,176,.28); transform: translateY(-1px); }
.dm-btn-no {
    background: var(--dm-key-bg); border-color: var(--dm-key-brd); color: var(--dm-muted);
}
.dm-btn-no svg { width: 16px; height: 16px; }
.dm-btn-no:hover { background: rgba(255,60,80,.12); border-color: rgba(255,60,80,.40); color: #ff6070; }

/* loading paso 2 */
#dm-loading {
    display: flex; flex-direction: column; align-items: center;
    gap: 10px; padding: 24px var(--dm-pad);
}
.dm-spinner {
    width: 32px; height: 32px; border-radius: 50%;
    border: 2.5px solid var(--dm-key-brd);
    border-top-color: var(--dm-accent);
    animation: dmSpin .7s linear infinite;
}
@keyframes dmSpin { to { transform: rotate(360deg); } }
#dm-loading p { font-size: 0.78rem; color: var(--dm-muted); margin: 0; }

/* ---- CARRUSEL: transición entre pasos ---- */
.dm-slide { display: none; }
.dm-slide.active {
    display: block;
    animation: dmSlideIn .26s cubic-bezier(.4,0,.2,1) both;
}
.dm-slide.out {
    animation: dmSlideOut .20s cubic-bezier(.4,0,.2,1) both;
}
@keyframes dmSlideIn  { from { opacity:0; transform:translateX(18px); } to { opacity:1; transform:translateX(0); } }
@keyframes dmSlideOut { from { opacity:1; transform:translateX(0); } to { opacity:0; transform:translateX(-18px); } }

/* ---- RESPONSIVE ---- */
@media (max-width: 400px) {
    :root { --dm-gap:6px; --dm-pad:12px; --dm-radius:18px; --dm-key-fs:1.02rem; --dm-num-fs:1.5rem; }
    #dm-persona-nombre { font-size: 0.92rem; }
}
@media (min-width: 576px) and (max-width: 767px) {
    #documentModal .modal-dialog { width: min(400px, calc(100vw - 32px)); }
    :root { --dm-key-fs:1.2rem; --dm-num-fs:1.9rem; }
}
@media (min-width: 768px) {
    #documentModal .modal-dialog { width: 380px; }
}
@media (hover: none) {
    .dm-k:hover { transform: none; box-shadow: none; background: var(--dm-key-bg); border-color: var(--dm-key-brd); }
    .dm-btn-si:hover { transform: none; background: linear-gradient(135deg,rgba(0,229,176,.22),rgba(0,229,176,.10)); color: var(--dm-accent); box-shadow: none; }
    .dm-btn-no:hover { background: var(--dm-key-bg); border-color: var(--dm-key-brd); color: var(--dm-muted); }
}
@media (prefers-reduced-motion: reduce) {
    #documentModal .modal-dialog, .dm-k, .dm-btn-si, .dm-btn-no, #dm-btn-final, .dm-slide.active, .dm-spinner { transition: none !important; animation: none !important; }
}
</style>

<div class="modal fade" id="documentModal" tabindex="-1" aria-hidden="true"
     data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">

            <!-- ===== CABECERA FIJA ===== -->
            <div id="dm-header">
                <div id="dm-brand">
                    <div id="dm-brand-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                    </div>
                    <div id="dm-brand-text">
                        <span id="dm-brand-name">Registro Salida</span>
                        <span id="dm-brand-sub" id="dm-step-sub">Paso 1 de 2</span>
                    </div>
                </div>
                <button id="dm-x" type="button" data-bs-dismiss="modal" aria-label="Cerrar">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" width="11" height="11"><path d="M18 6 6 18M6 6l12 12"/></svg>
                </button>
            </div>

            <!-- Indicador de pasos -->
            <div id="dm-steps">
                <div class="dm-step-dot active" data-s="1"></div>
                <div class="dm-step-dot pending" data-s="2"></div>
            </div>

            <div class="dm-sep"></div>

            <!-- ===== PASO 1: DOCUMENTO ===== -->
            <div class="dm-slide active" id="dm-slide-1">
                <div class="dm-section-label">Número de documento</div>

                <div id="dm-display">
                    <span id="dm-disp-label">DOC</span>
                    <span id="dm-num" class="placeholder">— — —</span>
                </div>

                <div id="dm-keypad">
                    <button type="button" class="dm-k" data-d="1">1</button>
                    <button type="button" class="dm-k" data-d="2">2</button>
                    <button type="button" class="dm-k" data-d="3">3</button>
                    <button type="button" class="dm-k" data-d="4">4</button>
                    <button type="button" class="dm-k" data-d="5">5</button>
                    <button type="button" class="dm-k" data-d="6">6</button>
                    <button type="button" class="dm-k" data-d="7">7</button>
                    <button type="button" class="dm-k" data-d="8">8</button>
                    <button type="button" class="dm-k" data-d="9">9</button>
                    <button type="button" class="dm-k k-zero" data-d="0">0</button>
                    <button type="button" class="dm-k k-del" id="dm-del" aria-label="Borrar">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 4H8l-7 8 7 8h13a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2z"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
                    </button>
                </div>

                <button type="button" id="dm-btn-siguiente" disabled
                    style="margin:0 var(--dm-pad) 16px;padding:13px;min-height:48px;width:calc(100% - calc(var(--dm-pad)*2));display:flex;align-items:center;justify-content:center;gap:8px;border-radius:14px;border:1.5px solid var(--dm-accent);background:linear-gradient(135deg,rgba(0,229,176,.20),rgba(0,229,176,.08));color:var(--dm-accent);font-size:0.90rem;font-weight:800;letter-spacing:0.04em;cursor:pointer;transition:all .20s ease;box-shadow:0 4px 16px rgba(0,229,176,.10);">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="width:16px;height:16px"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                    Continuar
                </button>
            </div>

            <!-- ===== PASO 2: CONFIRMACIÓN INGRESO ACTIVO ===== -->
            <div class="dm-slide" id="dm-slide-2">

                <!-- Estado: cargando -->
                <div id="dm-loading">
                    <div class="dm-spinner"></div>
                    <p>Buscando ingreso activo…</p>
                </div>

                <!-- Estado: ingreso activo encontrado -->
                <div id="dm-persona-found" style="display:none">
                    <div id="dm-persona-card">
                        <div id="dm-persona-top">
                            <div id="dm-persona-avatar">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                            </div>
                            <div id="dm-persona-info">
                                <div id="dm-persona-nombre">—</div>
                                <div id="dm-persona-tipo">
                                    <span class="dm-tipo-dot"></span>
                                    <span id="dm-persona-tipo-text">—</span>
                                </div>
                            </div>
                        </div>
                        <div id="dm-persona-doc-row">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                            <span id="dm-persona-doc-text">—</span>
                        </div>
                    </div>
                    <p id="dm-confirm-question">¿Confirma la salida de <strong id="dm-confirm-name">—</strong>?</p>
                    <div id="dm-confirm-btns">
                        <button type="button" class="dm-btn-si" id="dm-btn-final">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                            Sí, registrar salida
                        </button>
                        <button type="button" class="dm-btn-no" id="dm-btn-no">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
                            Corregir
                        </button>
                    </div>
                </div>

                <!-- Estado: sin ingreso activo -->
                <div id="dm-persona-nueva" style="display:none">
                    <div class="dm-nueva-ico">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                    </div>
                    <p style="margin-bottom:14px"><strong>Sin ingreso activo</strong><br>Esta persona no tiene un ingreso abierto hoy.</p>
                    <div id="dm-confirm-btns-nueva" style="display:grid;grid-template-columns:1fr;gap:8px;margin:0 var(--dm-pad) 16px">
                        <button type="button" class="dm-btn-no" id="dm-btn-no-nueva">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
                            Corregir documento
                        </button>
                    </div>
                </div>

            </div>

        </div>
    </div>
</div>

<?php
$_js_root = modulosProjectRoot() . '/js';
$_v_cap = @filemtime($_js_root . '/porteria-captura.js') ?: time();
$_v_med = @filemtime($_js_root . '/porteria-medios.js') ?: time();
$_v_sal = @filemtime($_js_root . '/salidas.js') ?: time();
$h = htmlspecialchars($smartcset_asset_href);
$extra_js = '<script src="' . $h . 'js/porteria-captura.js?v=' . (int) $_v_cap . '"></script>'
    . '<script src="' . $h . 'js/porteria-medios.js?v=' . (int) $_v_med . '"></script>'
    . '<script src="' . $h . 'js/salidas.js?v=' . (int) $_v_sal . '"></script>'
    . '<script>
(function () {
    /* ---- Estado ---- */
    var num              = "";
    var step             = 1;
    var fetchResult      = null;
    var fetchPromise     = null;
    var prefetchTimer    = null;

    /* ---- Refs ---- */
    var modalEl  = document.getElementById("documentModal");
    var modal    = new bootstrap.Modal(modalEl, {backdrop:"static", keyboard:false});
    var numEl    = document.getElementById("dm-num");
    var btnSig   = document.getElementById("dm-btn-siguiente");
    var btnFinal = document.getElementById("dm-btn-final");
    var stepSub  = document.getElementById("dm-brand-sub");

    /* ---- Pre-fetch directo a consultar.php ---- */
    function prefetch() {
        if (num.length < 5) { fetchResult = null; fetchPromise = null; return; }
        fetchPromise = fetch(
            "consultar.php?" + new URLSearchParams({documento: num, tipo_doc: "CC"}),
            {headers: {Accept: "application/json"}}
        )
        .then(function(r) { return r.json(); })
        .then(function(data) {
            fetchResult = data.ok ? data : null;
            return fetchResult;
        })
        .catch(function() { fetchResult = null; return null; });
    }

    /* ---- Navegar entre pasos ---- */
    function goStep(n) {
        var curr = document.getElementById("dm-slide-" + step);
        var next = document.getElementById("dm-slide-" + n);
        if (!next) return;
        curr.classList.remove("active");
        step = n;
        next.classList.add("active");
        document.querySelectorAll(".dm-step-dot").forEach(function(d) {
            var s = parseInt(d.dataset.s);
            d.className = "dm-step-dot " + (s < n ? "done" : s === n ? "active" : "pending");
        });
        if (stepSub) stepSub.textContent = "Paso " + n + " de 2";
    }

    /* ---- Render paso 1 ---- */
    function renderNum() {
        if (num === "") { numEl.textContent = "— — —"; numEl.classList.add("placeholder"); }
        else            { numEl.textContent = num;     numEl.classList.remove("placeholder"); }
        btnSig.disabled = num.length < 5;
        btnSig.style.opacity = num.length < 5 ? "0.28" : "1";
        btnSig.style.cursor  = num.length < 5 ? "not-allowed" : "pointer";
        clearTimeout(prefetchTimer);
        if (num.length >= 5) {
            prefetchTimer = setTimeout(prefetch, 120);
        } else {
            fetchResult = null; fetchPromise = null;
        }
    }

    function showLoading(show) {
        var l = document.getElementById("dm-loading");
        var f = document.getElementById("dm-persona-found");
        var n = document.getElementById("dm-persona-nueva");
        if (l) l.style.display = show ? "flex" : "none";
        if (f) f.style.display = "none";
        if (n) n.style.display = "none";
    }

    function renderStep2(data) {
        var ingreso = data && data.ingreso_abierto;
        if (data && data.puede_salir && ingreso) {
            var nombre = (ingreso.nom_persona + " " + (ingreso.ape_persona || "")).trim();
            var f = document.getElementById("dm-persona-found");
            f.style.display = "block";
            document.getElementById("dm-persona-nombre").textContent    = nombre;
            document.getElementById("dm-persona-tipo-text").textContent = ingreso.nom_tipo_persona || "Registrado";
            document.getElementById("dm-persona-doc-text").textContent  = "Ingreso #" + ingreso.id_ingreso;
            document.getElementById("dm-confirm-name").textContent      = ingreso.nom_persona.split(" ")[0];
        } else {
            var nv = document.getElementById("dm-persona-nueva");
            nv.style.cssText = "display:flex;flex-direction:column;align-items:center;padding:16px var(--dm-pad)";
        }
    }

    /* ---- Paso 1: teclado pantalla ---- */
    document.querySelectorAll(".dm-k[data-d]").forEach(function(b) {
        b.addEventListener("click", function() {
            if (num.length < 10) { num += this.dataset.d; renderNum(); }
        });
    });
    document.getElementById("dm-del").addEventListener("click", function() {
        num = num.slice(0, -1); renderNum();
    });

    /* ---- Paso 1: teclado físico ---- */
    document.addEventListener("keydown", function(e) {
        if (!modalEl.classList.contains("show")) return;
        if (step === 1) {
            if (e.key >= "0" && e.key <= "9") {
                if (num.length < 10) { num += e.key; renderNum(); }
            } else if (e.key === "Backspace") {
                num = num.slice(0, -1); renderNum();
            } else if (e.key === "Enter" && !btnSig.disabled) {
                btnSig.click();
            }
        } else if (step === 2 && e.key === "Enter" && btnFinal && !btnFinal.disabled) {
            btnFinal.click();
        }
    });

    /* ---- Paso 1 → 2: usar resultado pre-cargado o esperar fetch en vuelo ---- */
    btnSig.addEventListener("click", function() {
        if (fetchResult !== null) {
            goStep(2);
            showLoading(false);
            renderStep2(fetchResult);
        } else if (fetchPromise !== null) {
            showLoading(true);
            goStep(2);
            fetchPromise.then(function(data) {
                showLoading(false);
                renderStep2(data);
            });
        } else {
            showLoading(true);
            goStep(2);
            prefetch();
            fetchPromise.then(function(data) {
                showLoading(false);
                renderStep2(data);
            });
        }
    });

    /* ---- Paso 2: volver al paso 1 ---- */
    function irPaso1Reset() {
        num = ""; fetchResult = null; fetchPromise = null;
        renderNum();
        goStep(1);
        showLoading(false);
        document.getElementById("txt_documento").value = "";
    }

    document.getElementById("dm-btn-no").addEventListener("click", irPaso1Reset);
    document.getElementById("dm-btn-no-nueva").addEventListener("click", irPaso1Reset);

    /* ---- Paso 2: confirmar → auto-submit ---- */
    btnFinal.addEventListener("click", function() {
        var fDoc = document.getElementById("txt_documento");
        var fTip = document.getElementById("sel_tipo_doc");
        var fCap = document.getElementById("hid_captura_raw");
        var fMet = document.getElementById("hid_metodo_aut");

        if (fDoc) fDoc.value = num;
        if (fTip) {
            var ccOpt = Array.from(fTip.options).find(function(o) { return o.value === "CC"; });
            if (ccOpt) fTip.value = "CC";
        }
        if (fCap) fCap.value = "";
        if (fMet) fMet.value = "1";

        document.getElementById("form_salida").submit();
    });

    /* ---- Reset al abrir ---- */
    modalEl.addEventListener("show.bs.modal", function() {
        num = ""; step = 1;
        fetchResult = null; fetchPromise = null;
        clearTimeout(prefetchTimer);
        renderNum();
        showLoading(false);
        document.querySelectorAll(".dm-slide").forEach(function(s) { s.classList.remove("active"); });
        document.getElementById("dm-slide-1").classList.add("active");
        document.querySelectorAll(".dm-step-dot").forEach(function(d, i) {
            d.className = "dm-step-dot " + (i === 0 ? "active" : "pending");
        });
        if (stepSub) stepSub.textContent = "Paso 1 de 2";
    });

    /* ---- Abrir al cargar ---- */
    modal.show();
})();
</script>';
include modulosLayout('layout/footer.php');
