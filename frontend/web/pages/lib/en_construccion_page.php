<?php
declare(strict_types=1);

/**
 * Vista compartida «módulo en construcción».
 * Cada página define $enConstruccionMenuId (obligatorio) antes de incluir este archivo.
 *
 * Opcional: $enConstruccionDetalle (string), $enConstruccionIcono (clase Bootstrap Icons).
 */

if (!isset($enConstruccionMenuId) || trim((string) $enConstruccionMenuId) === '') {
    http_response_code(500);
    die('Configuración de módulo incompleta.');
}

require_once dirname(__DIR__, 2) . '/init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

$idUsuario = (string) $_SESSION['id_usuario'];
$idMenu = trim((string) $enConstruccionMenuId);

if (!usuarioTieneAccesoMenu($pdo, $idUsuario, $idMenu)) {
    http_response_code(403);
    die('No tiene permiso para acceder a este módulo.');
}

$stmtMenu = $pdo->prepare(
    'SELECT nom_menu, nom_programa FROM tab_menus WHERE id_menu = CAST(? AS TEXT)'
);
$stmtMenu->execute([$idMenu]);
$menuRow = $stmtMenu->fetch(PDO::FETCH_ASSOC) ?: [];

$page_title = trim((string) ($menuRow['nom_menu'] ?? '')) !== ''
    ? (string) $menuRow['nom_menu']
    : 'Módulo';
$active_menu_id = $idMenu;
$wnom_usuario = (string) ($_SESSION['nom_usuario'] ?? '');

$detalle = trim((string) ($enConstruccionDetalle ?? ''));
if ($detalle === '') {
    $detalle = 'Este módulo forma parte del plan de desarrollo de SmartCSET y estará disponible próximamente.';
}

$icono = trim((string) ($enConstruccionIcono ?? ''));
if ($icono === '') {
    $icono = getIcon($page_title);
}

$_css_v = @filemtime(smartcsetProjectRoot() . '/frontend/web/public/assets/css/en_construccion.css') ?: time();
$extra_stylesheets = '<link rel="stylesheet" href="'
    . htmlspecialchars(smartcsetAsset('css/en_construccion.css'), ENT_QUOTES, 'UTF-8')
    . '?v=' . (int) $_css_v . '">';

include smartcsetLayoutPath('head.php');
include smartcsetLayoutPath('sidebar.php');
include smartcsetLayoutPath('topbar.php');
?>

<?php renderPageFlash($w_mensaje ?? null, $w_tipo_alerta ?? 'info'); ?>

<div class="en-construccion-wrap">
    <div class="card shadow-sm border-0 en-construccion-card">
        <div class="card-body text-center py-5 px-4">
            <div class="en-construccion-icon" aria-hidden="true">
                <i class="bi <?= htmlspecialchars($icono, ENT_QUOTES, 'UTF-8') ?>"></i>
            </div>
            <p class="en-construccion-badge mb-3">
                <i class="bi bi-hourglass-split me-1"></i> En construcción
            </p>
            <h1 class="h4 mb-3 en-construccion-title"><?= htmlspecialchars($page_title) ?></h1>
            <p class="text-muted mb-4 en-construccion-text"><?= htmlspecialchars($detalle) ?></p>
            <a class="btn btn-outline-corporativo btn-sm"
               href="<?= htmlspecialchars(smartcsetUrl('/pages/menu/menu_principal.php')) ?>"
               data-spa-link="1">
                <i class="bi bi-house-door me-1"></i> Volver al inicio
            </a>
        </div>
    </div>
</div>

<?php include smartcsetLayoutPath('footer.php'); ?>
