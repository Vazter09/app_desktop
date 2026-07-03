<?php
/**
 * SIDEBAR PARTIAL - SmartCSET
 * Variables esperadas del archivo que lo incluye:
 *   $_SESSION['id_usuario']  — usuario logueado
 *   $stmt_menu               — prepared statement de prepare.php
 *   $active_menu_id          — ID del menú activo (string, opcional)
 */

$_active = $active_menu_id ?? '';
$__asset_href = function_exists('smartcsetProjectAssetHref') ? smartcsetProjectAssetHref() : '../../';

// Cargar menú del usuario (administrador: acceso fijo a todo el catálogo)
$_menu_raw = obtenerMenusUsuario($pdo, $_SESSION['id_usuario']);

if (isset($stmt_fun_listar_fichas_instructor) && !usuarioEsAdministrador($pdo, (string) $_SESSION['id_usuario'])) {
    require_once dirname(__DIR__, 3) . '/backend/services/instructor/asistencia_service.php';
    $_menu_raw = instructorFiltrarMenusUsuario($pdo, (string) $_SESSION['id_usuario'], $_menu_raw);
}

$_menu = smartcsetConstruirArbolMenus($_menu_raw);

// Mis Fichas (206): hijos dinámicos por ficha del instructor
if (isset($stmt_fun_listar_fichas_instructor)) {
    if (!function_exists('instructorExpandirMenuSidebar')) {
        require_once dirname(__DIR__, 3) . '/backend/services/instructor/asistencia_service.php';
    }
    $_menu = instructorExpandirMenuSidebar(
        $pdo,
        $stmt_fun_listar_fichas_instructor,
        (string) $_SESSION['id_usuario'],
        $_menu
    );
}

// Etiquetas del módulo 206 solo para administrador (instructores ven nombres de tab_menus).
if (isset($_menu['20']['hijos']['206']) && usuarioEsAdministrador($pdo, (string) $_SESSION['id_usuario'])) {
    if (!function_exists('instructorMenuLabelAdminPadre')) {
        require_once dirname(__DIR__) . '/pages/modulos/instructor/lib/instructor_ui.php';
    }
    $_menu['20']['hijos']['206']['nom_menu'] = instructorMenuLabelAdminPadre();
    if (isset($_menu['20']['hijos']['206']['hijos']['20601'])) {
        $_menu['20']['hijos']['206']['hijos']['20601']['nom_menu'] = instructorMenuLabelAdminHijo();
    }
}

/**
 * @param array<string, mixed> $item
 */
$_sidebar_render_item = static function (array $item, int $depth = 1) use (&$_sidebar_render_item, $_active): void {
    $prog = trim((string) ($item['nom_programa'] ?? ''));
    $esExit = (strcasecmp($prog, 'Exit') === 0 || strcasecmp($prog, 'exit.php') === 0);
    $hijos = $item['hijos'] ?? [];
    $tieneHijos = is_array($hijos) && $hijos !== [];
    $icono = getIcon((string) ($item['nom_menu'] ?? ''));
    $ramaAbierta = smartcsetMenuRamaActiva($item, (string) $_active);
    $itemActivo = smartcsetMenuItemActivo($item, (string) $_active);
    $idMenu = (string) ($item['id_menu'] ?? '');
    $nomMenu = (string) ($item['nom_menu'] ?? '');
    $esEnlace = !$tieneHijos && $prog !== '' && strcasecmp($prog, 'no_aplica') !== 0 && !$esExit;
    $esPlaceholder = !$tieneHijos && !$esEnlace && !$esExit;
    $wrapperClass = $depth === 1 ? 'nav-section' : 'nav-subsection';

    if ($esExit) {
        echo '<div class="nav-section"><div class="nav-divider"></div>';
        echo '<a class="nav-item" href="' . htmlspecialchars(smartcsetUrl('/routers/auth/v1/logout.php')) . '" data-tooltip="Salir">';
        echo '<i class="bi bi-power"></i><span class="nav-label">Salir</span></a></div>';
        return;
    }

    if ($tieneHijos) {
        $parentClass = $depth === 1 ? 'nav-item-parent' : 'nav-item-group';
        echo '<div class="' . $wrapperClass . ($ramaAbierta ? ' open' : '') . '">';
        echo '<div class="nav-item ' . $parentClass . ($itemActivo ? ' active' : '') . ($ramaAbierta && !$itemActivo ? ' has-active-child' : '') . '"';
        echo ' data-tooltip="' . htmlspecialchars($nomMenu) . '">';
        echo '<i class="bi ' . htmlspecialchars($icono) . '"></i>';
        echo '<span class="nav-label">' . htmlspecialchars($nomMenu) . '</span>';
        echo '<i class="bi bi-chevron-right nav-arrow"></i></div>';
        echo '<div class="nav-children nav-depth-' . $depth . '">';
        foreach ($hijos as $hijo) {
            $_sidebar_render_item($hijo, $depth + 1);
        }
        echo '</div></div>';
        return;
    }

    if ($esPlaceholder) {
        echo '<span class="nav-item child placeholder nav-depth-' . $depth . '"';
        echo ' data-tooltip="' . htmlspecialchars($nomMenu . ' (próximamente)') . '">';
        echo '<i class="bi bi-circle nav-placeholder-dot"></i>';
        echo '<span class="nav-label nav-label-muted">' . htmlspecialchars($nomMenu) . '</span></span>';
        return;
    }

    if ($esEnlace) {
        $url = smartcsetUrlNomPrograma($prog);
        $actH = smartcsetMenuItemActivo($item, (string) $_active) ? ' active' : '';
        $tip = trim((string) ($item['menu_tooltip'] ?? $nomMenu));
        $spa = smartcsetAttrSpaLink($prog);
        $childClass = $depth > 1 ? ' child' : '';
        echo '<a class="nav-item' . $childClass . ' nav-depth-' . $depth . $actH . '"';
        echo ' href="' . htmlspecialchars($url) . '"';
        echo ' data-menu-id="' . htmlspecialchars($idMenu, ENT_QUOTES, 'UTF-8') . '"' . $spa;
        echo ' data-tooltip="' . htmlspecialchars($tip) . '">';
        echo '<i class="bi ' . htmlspecialchars($icono) . '"></i>';
        echo '<span class="nav-label">' . htmlspecialchars($nomMenu) . '</span></a>';
    }
};

$_asset_href_logo = $smartcset_asset_href ?? '../../';
$_logo_path = smartcsetLogoUrl($_asset_href_logo);
?>

<!-- OVERLAY MOBILE -->
<div class="sidebar-overlay" id="sidebar-overlay"></div>

<!-- SIDEBAR -->
<aside class="sidebar" id="sidebar">

    <div class="sidebar-header">
        <span class="sidebar-title"><?= htmlspecialchars(AppConfig::nomSistema()) ?></span>
        <button id="sidebar-toggle" title="Colapsar menú">
            <i class="bi bi-layout-sidebar-reverse"></i>
        </button>
    </div>

    <nav class="sidebar-nav">

        <div class="nav-section">
            <a class="nav-item <?= ($_active === '0') ? 'active' : '' ?>"
               href="<?= htmlspecialchars(smartcsetUrl('/pages/menu/menu_principal.php')) ?>"
               data-menu-id="0"
               data-spa-link="1"
               data-tooltip="Inicio">
                <i class="bi bi-house-fill"></i>
                <span class="nav-label">Inicio</span>
            </a>
        </div>

        <div class="nav-divider"></div>

        <?php foreach ($_menu as $_abuelo): ?>
            <?php $_sidebar_render_item($_abuelo, 1); ?>
        <?php endforeach; ?>

    </nav>

</aside>
