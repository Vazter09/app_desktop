<?php
/**
 * TOPBAR PARTIAL - SmartCSET
 * Variables esperadas:
 *   $page_title    — título de la página actual
 *   $wnom_usuario  — nombre del usuario logueado
 */
$_nom = $wnom_usuario ?? $_SESSION['nom_usuario'] ?? '';
$_title = $page_title ?? 'SmartCSET';

// Ruta al menu_principal relativa al archivo que incluye este partial
$_home_url = (strpos($_SERVER['PHP_SELF'], '/menu/') !== false)
    ? 'menu_principal.php'
    : '../menu/menu_principal.php';
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
            <div class="topbar-user-identity" title="<?= htmlspecialchars($_nom) ?>">
                <i class="bi bi-person-circle" aria-hidden="true"></i>
                <span class="topbar-user-name"><?= htmlspecialchars($_nom) ?></span>
            </div>
            <a href="../auth/logout.php" class="btn-logout" title="Cerrar sesión">
                <i class="bi bi-box-arrow-right" aria-hidden="true"></i>
                <span>Salir</span>
            </a>
        </div>
    </header>

    <main class="main-content">
