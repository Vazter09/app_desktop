<?php
require_once __DIR__ . '/../init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

$tipos_doc       = [];
$tipos_persona   = [];
$entradas_lista  = [];
$salidas_hoy     = [];
$puerta_pref     = (int) ($_SESSION['ingreso_puerta_pref'] ?? 0);
$ultimo_id       = (int) ($_SESSION['ultimo_salida_id'] ?? 0);

if (!empty($_SESSION['flash_msg'])) {
    $w_mensaje     = $_SESSION['flash_msg'];
    $w_tipo_alerta = $_SESSION['flash_tipo'] ?? 'success';
    unset($_SESSION['flash_msg'], $_SESSION['flash_tipo']);
} else {
    $w_mensaje     = '';
    $w_tipo_alerta = 'success';
}

if ($w_mensaje === '' && isset($_GET['ok']) && (int) $_GET['ok'] > 0) {
    $w_mensaje     = 'Salida del ingreso #' . (int) $_GET['ok'] . ' registrada correctamente.';
    $w_tipo_alerta = 'success';
}

try {
    $stmt_list_tipos_doc->execute();
    $tipos_doc = $stmt_list_tipos_doc->fetchAll();

    $stmt_list_tipos_persona->execute();
    $tipos_persona = $stmt_list_tipos_persona->fetchAll();

    $stmt_list_entradas->execute();
    $entradas_lista = $stmt_list_entradas->fetchAll();

    $stmt_list_salidas_hoy->execute();
    $salidas_hoy = $stmt_list_salidas_hoy->fetchAll();
} catch (PDOException $e) {
    $w_mensaje     = ErrorHandler::userMessageFromException($e);
    $w_tipo_alerta = 'danger';
}

$page_title     = 'Registro de salida';
$active_menu_id = '103';
$wnom_usuario   = $_SESSION['nom_usuario'];
$hora_servidor  = date('H:i');
$total_hoy      = count($salidas_hoy);
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
<div class="ingresos-page ingresos-page--table-first">
    <div class="ing-panel ing-panel-list ing-panel-full">
        <div class="ing-panel-head d-flex justify-content-between align-items-center flex-wrap gap-2">
            <span><i class="bi bi-clock-history me-1"></i> Salidas de hoy</span>
            <div class="ing-panel-head-actions d-flex align-items-center flex-wrap gap-2">
                <span class="meta" title="Cantidad de salidas hoy y hora del servidor">
                    <?= $total_hoy ?> <?= $total_hoy === 1 ? 'salida' : 'salidas' ?>
                    · <?= htmlspecialchars($hora_servidor) ?>
                </span>
                <button type="button" class="btn btn-sm btn-outline-light" id="btn_abrir_modal_kiosk" title="Abrir teclado numérico">
                    <i class="bi bi-grid-3x3-gap-fill me-1"></i> Teclado
                </button>
                <button type="button" class="btn btn-sm btn-light fw-semibold" id="btn_abrir_salida_modal">
                    <i class="bi bi-box-arrow-right me-1"></i> Nueva salida
                </button>
            </div>
        </div>

        <div class="ing-panel-body ing-list-scroll p-0">
            <?php if (empty($salidas_hoy)): ?>
            <div class="ing-empty">
                <i class="bi bi-inbox"></i>
                <p><strong>Sin registros hoy</strong></p>
                <p class="small text-muted mt-2">Use <em>Nueva salida</em> para registrar la primera salida del día.</p>
            </div>
            <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover table-sm mb-0 ing-table-full">
                    <thead class="thead-oliva">
                        <tr>
                            <th style="width:2.5rem">#</th>
                            <th style="width:3rem">Hora</th>
                            <th>Persona</th>
                            <th style="width:4.5rem">Tipo</th>
                            <th style="width:5rem">Ficha</th>
                            <th>Carrera</th>
                            <th style="width:4rem">Puerta</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($salidas_hoy as $row): ?>
                        <?php
                        $esReciente = $ultimo_id > 0 && (int) $row['id_ingreso'] === $ultimo_id;
                        $nomCompleto = trim($row['nom_persona'] . ' ' . $row['ape_persona']);
                        $idFicha = isset($row['id_ficha']) ? (int) $row['id_ficha'] : 0;
                        $nomPrograma = trim((string) ($row['nom_programa'] ?? ''));
                        ?>
                        <tr class="<?= $esReciente ? 'salida-reciente' : '' ?>">
                            <td class="text-muted fw-semibold"><?= (int) $row['id_ingreso'] ?></td>
                            <td class="text-nowrap"><?= htmlspecialchars(smartcsetFormatDbTimestamp($row['fec_salida'], 'H:i')) ?></td>
                            <td>
                                <span class="v-nom" title="<?= htmlspecialchars($nomCompleto) ?>"><?= htmlspecialchars($nomCompleto) ?></span>
                                <span class="v-doc"><?= htmlspecialchars($row['id_tipo_docum']) ?> <?= htmlspecialchars((string) $row['id_persona']) ?></span>
                            </td>
                            <td><span class="ing-tipo-badge"><?= htmlspecialchars($row['nom_tipo_persona']) ?></span></td>
                            <td class="text-nowrap"><?= $idFicha > 0 ? (int) $idFicha : '—' ?></td>
                            <td><span class="v-carrera" title="<?= htmlspecialchars($nomPrograma) ?>"><?= $nomPrograma !== '' ? htmlspecialchars($nomPrograma) : '—' ?></span></td>
                            <td>
                                <span class="ing-puerta-badge" title="<?= htmlspecialchars($row['nom_entrada_centro']) ?>">
                                    <?= (int) $row['id_entrada_centro'] ?>
                                </span>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
            <?php endif; ?>
        </div>

        <?php if ($total_hoy > 8): ?>
        <div class="ing-list-hint">Desplaza para ver todos los registros</div>
        <?php endif; ?>
    </div>
</div>

<div class="modal fade" id="salidaFormModal" tabindex="-1" aria-labelledby="salidaFormModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-scrollable modal-dialog-centered">
        <div class="modal-content ing-modal-form">
            <div class="modal-header">
                <h5 class="modal-title" id="salidaFormModalLabel">
                    <i class="bi bi-box-arrow-right me-1"></i> Nueva salida
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
            </div>
            <div class="modal-body p-0">
                <?php include __DIR__ . '/../lib/formulario_salida.php'; ?>
            </div>
        </div>
    </div>
</div>
<?php unset($_SESSION['ultimo_salida_id']); ?>

<style>
/* ========================================================
   SMARTCSET — MODAL REGISTRO SALIDA (carrusel 3 pasos)
   ======================================================== */

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

/* ---- Backdrop (sin elevar z-index: bloqueaba el modal de formulario) ---- */
.modal-backdrop {
    backdrop-filter: blur(10px) !important;
    -webkit-backdrop-filter: blur(10px) !important;
    background: rgba(0,0,0,0.45) !important;
}

#documentModal {
    z-index: 1060 !important;
}

#documentModal .modal-dialog {
    width: min(380px, calc(100vw - 24px));
    margin: auto;
    transition: transform .30s cubic-bezier(.34,1.4,.64,1), opacity .24s ease;
}
#documentModal.fade:not(.show) .modal-dialog {
    transform: translateY(20px) scale(0.95); opacity: 0;
}

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
#documentModal .modal-content::before {
    content: '';
    position: absolute; top: 0; left: 0; right: 0; height: 40%;
    background: linear-gradient(160deg, var(--dm-shine) 0%, transparent 100%);
    pointer-events: none; z-index: 0; border-radius: var(--dm-radius);
}
#documentModal .modal-content > * { position: relative; z-index: 1; }

#dm-header {
    display: flex; align-items: center; justify-content: space-between;
    padding: 16px var(--dm-pad) 0;
    gap: 10px;
}
#dm-brand { display: flex; align-items: center; gap: 8px; }
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
#dm-brand-sub { font-size: 0.65rem; color: var(--dm-muted); margin-top: 1px; }
#dm-x {
    width: 28px; height: 28px; border-radius: 8px; flex-shrink: 0;
    background: var(--dm-key-bg); border: 1px solid var(--dm-key-brd);
    color: var(--dm-muted); cursor: pointer;
    display: flex; align-items: center; justify-content: center;
    transition: all .15s ease;
}
#dm-x:hover { background: rgba(255,60,80,.18); border-color: rgba(255,60,80,.4); color: #ff5566; }

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

.dm-sep {
    height: 1px; margin: 12px var(--dm-pad) 0;
    background: linear-gradient(90deg, transparent, var(--dm-border) 30%, var(--dm-border) 70%, transparent);
}

.dm-section-label {
    font-size: 0.68rem; font-weight: 700; letter-spacing: 0.09em; text-transform: uppercase;
    color: var(--dm-lbl); padding: 10px var(--dm-pad) 4px;
}

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
}
.dm-k.k-del:hover { background: rgba(255,60,80,.18); border-color: rgba(255,60,80,.5); }
.dm-k.k-del svg   { width: 18px; height: 18px; pointer-events: none; }

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
#dm-persona-sin-ingreso {
    display: none; text-align: center; padding: 10px;
}
#dm-persona-sin-ingreso .dm-nueva-ico {
    width: 40px; height: 40px; border-radius: 12px; margin: 0 auto 8px;
    background: rgba(255,60,80,.10); border: 1px solid rgba(255,60,80,.20);
    display: flex; align-items: center; justify-content: center;
}
#dm-persona-sin-ingreso .dm-nueva-ico svg { width: 20px; height: 20px; color: #ff6070; }
#dm-persona-sin-ingreso p { font-size: 0.78rem; color: var(--dm-muted); margin: 0; }
#dm-persona-sin-ingreso strong { color: var(--dm-key-col); }

#dm-confirm-question {
    margin: 10px var(--dm-pad) 0;
    font-size: 0.80rem; color: var(--dm-muted); text-align: center; line-height: 1.5;
}
#dm-confirm-question strong { color: var(--dm-key-col); }

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

#dm-puertas-grid {
    display: grid; grid-template-columns: repeat(auto-fit, minmax(90px,1fr));
    gap: var(--dm-gap); margin: 8px var(--dm-pad) var(--dm-pad);
}
.dm-puerta {
    min-height: 70px; padding: 10px 6px;
    background: var(--dm-key-bg); border: 1.5px solid var(--dm-key-brd);
    border-radius: 15px; color: var(--dm-key-col);
    cursor: pointer; user-select: none;
    display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px;
    transition: background .13s, border-color .13s, transform .10s, box-shadow .13s;
}
.dm-puerta .p-num { font-size: 1.6rem; font-weight: 800; line-height: 1; color: var(--dm-key-col); }
.dm-puerta .p-nom { font-size: 0.65rem; font-weight: 600; opacity: .55; text-align: center; line-height: 1.3; }
.dm-puerta:hover  { background: rgba(0,229,176,.10); border-color: var(--dm-accent); transform: translateY(-2px); }
.dm-puerta.selected { background: rgba(0,229,176,.18); border-color: var(--dm-accent); }
.dm-puerta.selected .p-num { color: var(--dm-accent); }

#dm-btn-final {
    margin: 0 var(--dm-pad) 16px; padding: 13px; min-height: 48px;
    display: flex; align-items: center; justify-content: center; gap: 8px;
    border-radius: 14px; border: 1.5px solid var(--dm-accent);
    background: linear-gradient(135deg, rgba(0,229,176,.20), rgba(0,229,176,.08));
    color: var(--dm-accent); font-size: 0.90rem; font-weight: 800;
    letter-spacing: 0.04em; cursor: pointer; transition: all .20s ease;
}
#dm-btn-final:hover:not(:disabled) { background: var(--dm-accent); color: #041210; }
#dm-btn-final:disabled { opacity: 0.28; cursor: not-allowed; }
#dm-btn-final svg { width: 17px; height: 17px; }

.dm-slide { display: none; }
.dm-slide.active { display: block; animation: dmSlideIn .26s cubic-bezier(.4,0,.2,1) both; }
@keyframes dmSlideIn { from { opacity:0; transform:translateX(18px); } to { opacity:1; transform:translateX(0); } }

@media (max-width: 400px) {
    :root { --dm-gap:6px; --dm-pad:12px; --dm-radius:18px; --dm-key-fs:1.02rem; --dm-num-fs:1.5rem; }
}
</style>

<div class="modal fade" id="documentModal" tabindex="-1" aria-hidden="true"
     data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">

            <div id="dm-header">
                <div id="dm-brand">
                    <div id="dm-brand-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                    </div>
                    <div id="dm-brand-text">
                        <span id="dm-brand-name">Registro Salida</span>
                        <span id="dm-brand-sub">Paso 1 de 3</span>
                    </div>
                </div>
                <button id="dm-x" type="button" data-bs-dismiss="modal" aria-label="Cerrar">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" width="11" height="11"><path d="M18 6 6 18M6 6l12 12"/></svg>
                </button>
            </div>

            <div id="dm-steps">
                <div class="dm-step-dot active" data-s="1"></div>
                <div class="dm-step-dot pending" data-s="2"></div>
                <div class="dm-step-dot pending" data-s="3"></div>
            </div>

            <div class="dm-sep"></div>

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
                    style="margin:0 var(--dm-pad) 16px;padding:13px;min-height:48px;width:calc(100% - calc(var(--dm-pad)*2));display:flex;align-items:center;justify-content:center;gap:8px;border-radius:14px;border:1.5px solid var(--dm-accent);background:linear-gradient(135deg,rgba(0,229,176,.20),rgba(0,229,176,.08));color:var(--dm-accent);font-size:0.90rem;font-weight:800;letter-spacing:0.04em;cursor:pointer;transition:all .20s ease;">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="width:16px;height:16px"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                    Continuar
                </button>
            </div>

            <div class="dm-slide" id="dm-slide-2">
                <div id="dm-loading">
                    <div class="dm-spinner"></div>
                    <p>Buscando persona…</p>
                </div>

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
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20"/></svg>
                            <span id="dm-persona-doc-text">—</span>
                        </div>
                    </div>
                    <p id="dm-confirm-question">¿Confirma que usted es <strong id="dm-confirm-name">—</strong>?</p>
                    <div id="dm-confirm-btns">
                        <button type="button" class="dm-btn-si" id="dm-btn-si">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                            Sí, soy yo
                        </button>
                        <button type="button" class="dm-btn-no" id="dm-btn-no">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
                            Corregir
                        </button>
                    </div>
                </div>

                <div id="dm-persona-sin-ingreso" style="display:none">
                    <div class="dm-nueva-ico">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                    </div>
                    <p style="margin-bottom:14px"><strong>Sin ingreso activo</strong><br>No hay ingreso abierto para este documento.</p>
                    <div style="display:grid;grid-template-columns:1fr;gap:8px;margin:0 var(--dm-pad) 16px">
                        <button type="button" class="dm-btn-no" id="dm-btn-no-sin-ingreso" style="width:100%">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18M6 6l12 12"/></svg>
                            Corregir documento
                        </button>
                    </div>
                </div>
            </div>

            <div class="dm-slide" id="dm-slide-3">
                <div class="dm-section-label">Selecciona la puerta de salida</div>
                <div id="dm-puertas-grid">
                    <?php foreach ($entradas_lista as $e): ?>
                    <button type="button" class="dm-puerta" data-puerta="<?= (int)$e['id_entrada'] ?>">
                        <span class="p-num"><?= (int)$e['id_entrada'] ?></span>
                        <span class="p-nom"><?= htmlspecialchars($e['nom_entrada']) ?></span>
                    </button>
                    <?php endforeach; ?>
                </div>
                <button type="button" id="dm-btn-final" disabled>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                    Confirmar salida
                </button>
            </div>

        </div>
    </div>
</div>

<?php
$_asset_js = smartcsetUrl('/assets/js');
$_v_cap = @filemtime(__DIR__ . '/../../../../public/assets/js/modules/porteria/porteria-captura.js') ?: time();
$_v_med = @filemtime(__DIR__ . '/../../../../public/assets/js/modules/porteria/porteria-medios.js') ?: time();
$_v_sal = @filemtime(__DIR__ . '/../../../../public/assets/js/modules/porteria/salidas.js') ?: time();
$_v_modal = @filemtime(__DIR__ . '/../../../../public/assets/js/modules/porteria/porteria-salida-modal.js') ?: time();
$_v_mhost = @filemtime(__DIR__ . '/../../../../public/assets/js/modules/porteria/porteria-modal-host.js') ?: time();
$_v_http = @filemtime(__DIR__ . '/../../../../public/assets/js/services/http-client.js') ?: time();
$_v_sr = @filemtime(__DIR__ . '/../../../../public/assets/js/services/porteria/salida-router.js') ?: time();
$extra_js = '<script src="' . $_asset_js . '/services/http-client.js?v=' . (int) $_v_http . '"></script>'
    . '<script src="' . $_asset_js . '/services/porteria/salida-router.js?v=' . (int) $_v_sr . '"></script>'
    . '<script src="' . $_asset_js . '/modules/porteria/porteria-modal-host.js?v=' . (int) $_v_mhost . '"></script>'
    . '<script src="' . $_asset_js . '/modules/porteria/porteria-captura.js?v=' . (int) $_v_cap . '"></script>'
    . '<script src="' . $_asset_js . '/modules/porteria/porteria-medios.js?v=' . (int) $_v_med . '"></script>'
    . '<script src="' . $_asset_js . '/modules/porteria/salidas.js?v=' . (int) $_v_sal . '"></script>'
    . '<script src="' . $_asset_js . '/modules/porteria/porteria-salida-modal.js?v=' . (int) $_v_modal . '"></script>';
include modulosLayout('layout/footer.php');
