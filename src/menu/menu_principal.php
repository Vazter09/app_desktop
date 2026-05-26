<?php
session_start();
require_once(__DIR__ . '/../core/prepare.php');
require_once(__DIR__ . '/../core/helpers.php');

if (!isset($_SESSION['id_usuario'])) {
    header("Location: ../../index.php");
    exit();
}

$wid_usuario  = $_SESSION['id_usuario'];
$wnom_usuario = $_SESSION['nom_usuario'];

// Construir menú del usuario para el dashboard (admin: catálogo completo)
try {
    $menu_raw = obtenerMenusUsuario($pdo, $wid_usuario);

    $menu_final = [];
    foreach ($menu_raw as $item) {
        if ($item['ind_id_padre'] == '0') {
            $menu_final[$item['id_menu']] = $item;
            $menu_final[$item['id_menu']]['submenus'] = [];
        } else {
            $padre_id = $item['ind_id_padre'];
            if (isset($menu_final[$padre_id])) {
                $menu_final[$padre_id]['submenus'][$item['id_menu']] = $item;
            } else {
                foreach ($menu_final as $abuelo_id => &$abuelo) {
                    if (isset($abuelo['submenus'][$padre_id])) {
                        $abuelo['submenus'][$padre_id]['items'][] = $item;
                    }
                }
                unset($abuelo);
            }
        }
    }
} catch (Exception $e) {
    $menu_final = [];
}

$page_title        = 'Inicio';
$active_menu_id    = '0';
$include_calculator = true;

include __DIR__ . '/../layout/head.php';
include __DIR__ . '/../layout/sidebar.php';
include __DIR__ . '/../layout/topbar.php';
?>

<div class="dashboard-welcome">
    <h2>Bienvenido, <?= htmlspecialchars($wnom_usuario) ?></h2>
    <p>Seleccione un módulo para comenzar. Su acceso ha sido configurado según su perfil.</p>
</div>

<?php if (!empty($menu_final)): ?>
<div class="dashboard-grid">
    <?php foreach ($menu_final as $padre):
        $prog_p  = trim($padre['nom_programa'] ?? '');
        $es_exit = (strcasecmp($prog_p, 'Exit') === 0 || strcasecmp($prog_p, 'exit.php') === 0);
        if ($es_exit) continue;
        $icono   = getIcon($padre['nom_menu']);
        $submenus = array_filter($padre['submenus'] ?? [], function($s) {
            $p = trim($s['nom_programa'] ?? '');
            return !(strcasecmp($p, 'Exit') === 0 || strcasecmp($p, 'exit.php') === 0 || $p === 'no_aplica');
        });
    ?>
    <div class="module-card">
        <div class="module-card-icon">
            <i class="bi <?= $icono ?>"></i>
        </div>
        <h3><?= htmlspecialchars($padre['nom_menu']) ?></h3>
        <?php if (!empty($submenus)): ?>
        <div class="module-card-links">
            <?php foreach ($submenus as $sub):
                $ic_sub = getIcon($sub['nom_menu']);
                $url_sub = smartcsetUrlNomPrograma($sub['nom_programa']);
            ?>
            <a href="<?= htmlspecialchars($url_sub) ?>">
                <i class="bi <?= $ic_sub ?>"></i>
                <?= htmlspecialchars($sub['nom_menu']) ?>
            </a>
            <?php endforeach; ?>
        </div>
        <?php elseif ($prog_p !== 'no_aplica' && !empty($prog_p)): ?>
        <div class="module-card-links">
            <a href="<?= htmlspecialchars(smartcsetUrlNomPrograma($prog_p)) ?>">
                <i class="bi bi-arrow-right-circle"></i>
                <?= htmlspecialchars($padre['nom_menu']) ?>
            </a>
        </div>
        <?php endif; ?>
    </div>
    <?php endforeach; ?>
</div>
<?php else: ?>
<div class="card guide-card guide-card--warning guide-card--compact border-0 shadow-sm">
    <div class="guide-card-header py-2">
        <div class="guide-card-icon" style="width:2rem;height:2rem;font-size:0.95rem;">
            <i class="bi bi-inbox"></i>
        </div>
        <div>
            <p class="guide-card-title mb-0" style="font-size:0.9rem;">Sin módulos asignados</p>
            <p class="guide-card-subtitle mb-0" style="font-size:0.8rem;">Contacte al administrador para que le asigne accesos.</p>
        </div>
    </div>
</div>
<?php endif; ?>

<?php
if (!empty($_SESSION['flash_msg'])) {
    renderPageFlash($_SESSION['flash_msg'], $_SESSION['flash_tipo'] ?? 'success');
    unset($_SESSION['flash_msg'], $_SESSION['flash_tipo']);
}
?>

<!-- Calculadora flotante -->
<button id="btn_open_calc" class="calc-launcher" title="Calculadora">
    <i class="bi bi-calculator"></i>
</button>
<div id="calc-widget" class="calc-widget calc-hidden">
    <div class="calc-header" id="calc-header">
        <span>Calculadora</span>
        <button type="button" id="calc-close">✕</button>
    </div>
    <input type="text" id="calc-display" class="calc-display" readonly value="0">
    <div class="calc-buttons">
        <button class="calc-button action" data-key="C">C</button>
        <button class="calc-button action" data-key="⌫">⌫</button>
        <button class="calc-button operator" data-key="/">÷</button>
        <button class="calc-button operator" data-key="*">×</button>
        <button class="calc-button" data-key="7">7</button>
        <button class="calc-button" data-key="8">8</button>
        <button class="calc-button" data-key="9">9</button>
        <button class="calc-button operator" data-key="-">−</button>
        <button class="calc-button" data-key="4">4</button>
        <button class="calc-button" data-key="5">5</button>
        <button class="calc-button" data-key="6">6</button>
        <button class="calc-button operator" data-key="+">+</button>
        <button class="calc-button" data-key="1">1</button>
        <button class="calc-button" data-key="2">2</button>
        <button class="calc-button" data-key="3">3</button>
        <button class="calc-button action" data-key="=">=</button>
        <button class="calc-button" style="grid-column:span 2" data-key="0">0</button>
        <button class="calc-button" data-key=".">.</button>
        <button class="calc-button action" data-key="%">%</button>
    </div>
</div>

<style>
.calc-widget {
    position: fixed; right: 20px; bottom: 20px; width: 260px;
    border-radius: 14px; background: #fff;
    box-shadow: 0 12px 30px rgba(0,0,0,0.25); z-index: 2100;
    display: flex; flex-direction: column;
}
.calc-hidden { display: none !important; }
.calc-header {
    background: linear-gradient(90deg, var(--v-oscuro), var(--v-oliva));
    color: white; padding: 10px 12px;
    border-radius: 14px 14px 0 0; cursor: move;
    display: flex; align-items: center; justify-content: space-between;
}
.calc-header span { font-weight: 700; font-size: 0.95rem; }
.calc-header button { border: none; background: transparent; color: rgba(255,255,255,0.9); font-size: 1.1rem; cursor: pointer; }
.calc-display { height: 50px; padding: 10px; font-size: 1.2rem; text-align: right; border: none; outline: none; background: #f7f7f7; border-bottom: 1px solid #e0e0e0; width: 100%; }
.calc-buttons { display: grid; grid-template-columns: repeat(4,1fr); gap: 8px; padding: 12px; }
.calc-button { padding: 12px 0; border-radius: 10px; border: none; background: #f1f1f1; font-size: 1.1rem; cursor: pointer; transition: transform 0.1s ease; }
.calc-button:hover { background: #e0e0e0; }
.calc-button.action { background: var(--v-oliva); color: white; }
.calc-button.operator { background: var(--v-oscuro); color: white; }
.calc-button:active { transform: translateY(1px); }
.calc-launcher {
    position: fixed; right: 20px; bottom: 90px; width: 48px; height: 48px;
    border-radius: 50%; border: none; background: var(--v-oliva); color: #fff;
    box-shadow: 0 6px 16px rgba(0,0,0,0.2); z-index: 2200;
    cursor: pointer; display: flex; align-items: center; justify-content: center;
    font-size: 1.3rem;
}
</style>

<?php include __DIR__ . '/../layout/footer.php'; ?>
<script src="../../js/menu_calculadora.js"></script>
