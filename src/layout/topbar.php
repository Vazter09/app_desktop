<?php
/**
 * TOPBAR PARTIAL - SmartCSET
 * Variables esperadas:
 *   $page_title    — título de la página actual
 *   $wnom_usuario  — nombre del usuario logueado
 */
$_nom = $wnom_usuario ?? $_SESSION['nom_usuario'] ?? '';
$_title = $page_title ?? 'SmartCSET';
$__asset_href = function_exists('smartcsetProjectAssetHref') ? smartcsetProjectAssetHref() : '../../';

// Rutas absolutas relativas a la raíz del proyecto
$_home_url = $__asset_href . 'src/menu/menu_principal.php';
$_logout_url = $__asset_href . 'src/auth/logout.php';
?>

<div class="content-wrapper">

    <header class="topbar">
        <!-- Toggle mobile -->
        <button id="sidebar-toggle-mobile" class="btn btn-sm btn-outline-secondary border-0 me-2"
                title="Abrir menú">
            <i class="bi bi-list fs-5"></i>
        </button>

        <!-- Breadcrumb -->
        <nav class="topbar-breadcrumb" aria-label="breadcrumb">
            <a href="<?= $_home_url ?>"><i class="bi bi-house-fill me-1"></i>Inicio</a>
            <?php if ($_title !== 'Inicio'): ?>
                <span class="separator"><i class="bi bi-chevron-right"></i></span>
                <span class="current"><?= htmlspecialchars($_title) ?></span>
            <?php endif; ?>
        </nav>

        <!-- Usuario y botón salir -->
        <div class="topbar-user">
            <button id="theme-toggle" class="btn-theme-toggle" type="button" title="Cambiar tema" aria-label="Cambiar tema claro u oscuro">
                <i class="bi bi-moon-stars-fill" aria-hidden="true"></i>
                <span class="theme-label">Tema</span>
            </button>
            <div class="topbar-notifications" id="topbar-notifications">
                <button id="notifications-toggle"
                        class="btn-notifications"
                        type="button"
                        title="Notificaciones"
                        aria-label="Notificaciones"
                        aria-expanded="false"
                        aria-controls="notifications-panel">
                    <i class="bi bi-bell" aria-hidden="true"></i>
                    <span id="notifications-badge" class="notifications-badge d-none" aria-hidden="true">0</span>
                </button>
                <div id="notifications-panel"
                     class="notifications-panel"
                     role="region"
                     aria-label="Panel de notificaciones"
                     hidden>
                    <div class="notifications-panel-header">
                        <span class="notifications-panel-title">Notificaciones</span>
                    </div>
                    <div class="notifications-panel-body">
                        <p class="notifications-empty" id="notifications-empty">
                            <i class="bi bi-bell-slash" aria-hidden="true"></i>
                            Sin notificaciones nuevas
                        </p>
                        <ul id="notifications-list" class="notifications-list" hidden></ul>
                    </div>
                </div>
            </div>
            <div class="topbar-user-identity" title="<?= htmlspecialchars($_nom) ?>">
                <i class="bi bi-person-circle" aria-hidden="true"></i>
                <span class="topbar-user-name"><?= htmlspecialchars($_nom) ?></span>
            </div>
            <a href="<?= htmlspecialchars($_logout_url) ?>" class="btn-logout" title="Cerrar sesión">
                <i class="bi bi-box-arrow-right" aria-hidden="true"></i>
                <span>Salir</span>
            </a>
        </div>
    </header>

    <main class="main-content">
