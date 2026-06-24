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

// Construir jerarquía
$_menu = [];
foreach ($_menu_raw as $_item) {
    if (smartcsetMenuEsPadreRaiz((string) $_item['ind_id_padre'])) {
        $_menu[$_item['id_menu']] = $_item;
        $_menu[$_item['id_menu']]['hijos'] = [];
    } else {
        $_padre = $_item['ind_id_padre'];
        if (isset($_menu[$_padre])) {
            $_menu[$_padre]['hijos'][$_item['id_menu']] = $_item;
        }
    }
}

// Logo: prefijo según profundidad de la página (ver smartcsetModulosAssetHref)
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

        <!-- Inicio (siempre presente) -->
        <div class="nav-section">
            <a class="nav-item <?= ($_active === '0') ? 'active' : '' ?>"
               href="<?= htmlspecialchars(smartcsetUrl('/pages/menu/menu_principal.php')) ?>"
               data-tooltip="Inicio">
                <i class="bi bi-house-fill"></i>
                <span class="nav-label">Inicio</span>
            </a>
        </div>

        <div class="nav-divider"></div>

        <?php foreach ($_menu as $_padre): ?>
            <?php
            $_prog_p   = trim($_padre['nom_programa'] ?? '');
            $_es_exit  = (strcasecmp($_prog_p, 'Exit') === 0 || strcasecmp($_prog_p, 'exit.php') === 0);
            $_has_hijos = !empty($_padre['hijos']);
            $_icono    = getIcon($_padre['nom_menu']);
            $_activo_p = ($_active === $_padre['id_menu']) ? 'active' : '';

            // Si el padre activo tiene hijos, marcar también
            if (!$_activo_p && $_has_hijos) {
                foreach ($_padre['hijos'] as $_h) {
                    if ($_h['id_menu'] === $_active) { $_activo_p = 'active'; break; }
                }
            }
            ?>

            <?php if ($_es_exit): ?>
                <!-- Salir -->
                <div class="nav-section">
                    <div class="nav-divider"></div>
                    <a class="nav-item" href="<?= htmlspecialchars(smartcsetUrl('/routers/auth/v1/logout.php')) ?>" data-tooltip="Salir">
                        <i class="bi bi-power"></i>
                        <span class="nav-label">Salir</span>
                    </a>
                </div>

            <?php elseif ($_has_hijos): ?>
                <!-- Padre con submenús -->
                <div class="nav-section <?= $_activo_p ? 'open' : '' ?>">
                    <div class="nav-item nav-item-parent <?= $_activo_p ?>"
                         data-tooltip="<?= htmlspecialchars($_padre['nom_menu']) ?>">
                        <i class="bi <?= $_icono ?>"></i>
                        <span class="nav-label"><?= htmlspecialchars($_padre['nom_menu']) ?></span>
                        <i class="bi bi-chevron-right nav-arrow"></i>
                    </div>
                    <div class="nav-children">
                        <?php foreach ($_padre['hijos'] as $_hijo): ?>
                            <?php
                            $_prog_h  = trim($_hijo['nom_programa'] ?? '');
                            $_es_ex_h = (strcasecmp($_prog_h, 'Exit') === 0 || strcasecmp($_prog_h, 'exit.php') === 0);
                            $_url_h   = $_es_ex_h ? smartcsetUrl('/routers/auth/v1/logout.php') : smartcsetUrlNomPrograma($_prog_h);
                            $_ic_h    = getIcon($_hijo['nom_menu']);
                            $_act_h   = ($_hijo['id_menu'] === $_active) ? 'active' : '';
                            // Navegación SPA (solo cambia el <main>) para secciones marcadas.
                            $_spa_h   = (!$_es_ex_h && str_starts_with($_prog_h, 'pages/admin/reportes/')) ? ' data-spa-link="1"' : '';
                            ?>
                            <a class="nav-item child <?= $_act_h ?>"
                               href="<?= htmlspecialchars($_url_h) ?>"
                               data-menu-id="<?= htmlspecialchars((string) ($_hijo['id_menu'] ?? ''), ENT_QUOTES, 'UTF-8') ?>"<?= $_spa_h ?>
                               data-tooltip="<?= htmlspecialchars($_hijo['nom_menu']) ?>">
                                <i class="bi <?= $_ic_h ?>"></i>
                                <span class="nav-label"><?= htmlspecialchars($_hijo['nom_menu']) ?></span>
                            </a>
                        <?php endforeach; ?>
                    </div>
                </div>

            <?php else: ?>
                <!-- Padre directo sin hijos -->
                <?php
                $_url_p = smartcsetUrlNomPrograma($_prog_p);
                $_act_p = ($_active === $_padre['id_menu']) ? 'active' : '';
                ?>
                <div class="nav-section">
                    <a class="nav-item <?= $_act_p ?>"
                       href="<?= htmlspecialchars($_url_p) ?>"
                       data-tooltip="<?= htmlspecialchars($_padre['nom_menu']) ?>">
                        <i class="bi <?= $_icono ?>"></i>
                        <span class="nav-label"><?= htmlspecialchars($_padre['nom_menu']) ?></span>
                    </a>
                </div>
            <?php endif; ?>

        <?php endforeach; ?>

    </nav>

</aside>
