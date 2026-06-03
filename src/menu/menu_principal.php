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
        if (smartcsetMenuEsPadreRaiz((string) $item['ind_id_padre'])) {
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
$smartcset_asset_href = '../../';

include __DIR__ . '/../layout/head.php';
include __DIR__ . '/../layout/sidebar.php';
include __DIR__ . '/../layout/topbar.php';
?>

<div class="dashboard-welcome">
    <div class="dashboard-eyebrow">
        <i class="bi bi-grid-1x2-fill"></i>
        <span>Panel principal</span>
    </div>
    <h2>Bienvenido, <span><?= htmlspecialchars($wnom_usuario) ?></span></h2>
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

<?php include __DIR__ . '/../layout/footer.php'; ?>
