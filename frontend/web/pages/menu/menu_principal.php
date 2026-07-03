<?php
session_start();
require_once dirname(__DIR__, 2) . '/init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

$wid_usuario  = $_SESSION['id_usuario'];
$wnom_usuario = $_SESSION['nom_usuario'];

/**
 * @return list<string> Rutas nom_programa asignadas al usuario (árbol de menú).
 */
function dashboardFlattenMenuPaths(array $menuFinal): array
{
    $paths = [];
    $walk = static function (array $item) use (&$paths, &$walk): void {
        $prog = trim((string) ($item['nom_programa'] ?? ''));
        if ($prog !== ''
            && strcasecmp($prog, 'no_aplica') !== 0
            && strcasecmp($prog, 'Exit') !== 0
            && strcasecmp($prog, 'exit.php') !== 0
        ) {
            $paths[] = $prog;
        }
        foreach ($item['hijos'] ?? $item['submenus'] ?? [] as $hijo) {
            $walk($hijo);
        }
    };
    foreach ($menuFinal as $padre) {
        $walk($padre);
    }

    return $paths;
}

/** Primera ruta de menú cuyo nom_programa contiene $needle (insensible a mayúsculas). */
function dashboardFindMenuPath(array $paths, string $needle): ?string
{
    $needle = strtolower($needle);
    foreach ($paths as $path) {
        if (str_contains(strtolower($path), $needle)) {
            return $path;
        }
    }

    return null;
}

// Construir menú del usuario para el dashboard (admin: catálogo completo)
try {
    $menu_raw = obtenerMenusUsuario($pdo, $wid_usuario);
    $menu_final = smartcsetConstruirArbolMenus($menu_raw);
} catch (Exception $e) {
    $menu_final = [];
}

$menu_paths   = dashboardFlattenMenuPaths($menu_final);
$es_admin     = usuarioEsAdministrador($pdo, $wid_usuario);

require_once dirname(__DIR__, 4) . '/backend/services/instructor/asistencia_service.php';
require_once dirname(__DIR__) . '/modulos/instructor/lib/instructor_ui.php';
$id_instructor = instructorResolverIdDesdeSesion($pdo, $wid_usuario);
$es_instructor = $id_instructor !== null;
$path_fichas   = dashboardFindMenuPath($menu_paths, 'instructor/fichas');

$tiene_porteria_ingreso = dashboardFindMenuPath($menu_paths, 'porteria/ingreso') !== null;
$tiene_porteria_salida  = dashboardFindMenuPath($menu_paths, 'porteria/salida') !== null;
$tiene_porteria         = $tiene_porteria_ingreso || $tiene_porteria_salida;
$tiene_usuarios         = dashboardFindMenuPath($menu_paths, 'usuarios/usuarios.php') !== null
    || dashboardFindMenuPath($menu_paths, 'usuarios.php') !== null;
$tiene_sesiones_menu    = dashboardFindMenuPath($menu_paths, 'admin/sesiones') !== null;

$ingresos_hoy      = [];
$salidas_hoy       = [];
$kpi_error         = '';
$kpi_ingresos      = 0;
$kpi_salidas       = 0;
$personas_dentro   = 0;
$por_tipo_persona  = [];
$instructor_resumen = null;

if (!$es_instructor) {
    try {
        $stmt_list_ingresos_hoy->execute();
        $ingresos_hoy = $stmt_list_ingresos_hoy->fetchAll(PDO::FETCH_ASSOC);
        $kpi_ingresos = count($ingresos_hoy);

        foreach ($ingresos_hoy as $row) {
            $tipo = trim((string) ($row['nom_tipo_persona'] ?? 'Sin tipo'));
            $por_tipo_persona[$tipo] = ($por_tipo_persona[$tipo] ?? 0) + 1;
        }
        arsort($por_tipo_persona);

        $stmt_list_salidas_hoy->execute();
        $salidas_hoy = $stmt_list_salidas_hoy->fetchAll(PDO::FETCH_ASSOC);
        $kpi_salidas = count($salidas_hoy);

        $stmt_dentro = $pdo->query(
            "SELECT COUNT(*)::int FROM tab_log_ingresos
             WHERE fec_salida = fec_ingreso"
        );
        $personas_dentro = (int) $stmt_dentro->fetchColumn();
    } catch (PDOException $e) {
        $kpi_error = ErrorHandler::userMessageFromException($e);
    }
} elseif ($id_instructor !== null) {
    try {
        $instructor_fichas = instructorListarFichas($stmt_fun_listar_fichas_instructor, $id_instructor);
        $instructor_ctx = [
            'id_instructor' => $id_instructor,
            'es_admin' => false,
            'modo' => 'instructor',
            'id_usuario' => (string) $_SESSION['id_usuario'],
        ];
        $instructor_resumen = instructorDashboardResumen(
            $stmt_fun_listar_asistencia_ficha,
            $stmt_fun_listar_asistencia_ficha_admin,
            $instructor_ctx,
            $instructor_fichas
        );
    } catch (PDOException $e) {
        $kpi_error = ErrorHandler::userMessageFromException($e);
        $instructor_resumen = [
            'fecha' => date('Y-m-d'),
            'total_fichas' => 0,
            'total_aprendices' => 0,
            'hoy' => [
                'Presente' => 0,
                'Tarde' => 0,
                'Ausente' => 0,
                'Pendiente' => 0,
                'Desconocido' => 0,
                'total' => 0,
            ],
            'por_ficha' => [],
        ];
    }
}

$actividad_reciente = array_slice($ingresos_hoy, 0, 8);

$hay_datos_porteria = $kpi_ingresos > 0 || $kpi_salidas > 0 || $personas_dentro > 0;
$show_porteria      = !$es_instructor && ($tiene_porteria || $hay_datos_porteria);

$sesiones_activas_count = 0;
if ($es_admin) {
    try {
        $stmt_list_sesiones_activas->execute();
        $sesiones_activas_count = count($stmt_list_sesiones_activas->fetchAll(PDO::FETCH_ASSOC));
    } catch (PDOException $e) {
        if ($kpi_error === '') {
            $kpi_error = ErrorHandler::userMessageFromException($e);
        }
    }
}

// Inventario del sistema (solo admin) — datos reales para llenar el panel de resumen.
$sistema_totales   = [];
$personas_por_tipo = [];
if ($es_admin) {
    try {
        $sistema_totales = $pdo->query(
            "SELECT
                (SELECT COUNT(*) FROM tab_personas)        AS personas,
                (SELECT COUNT(*) FROM tab_fichas)          AS fichas,
                (SELECT COUNT(*) FROM tab_programas)       AS programas,
                (SELECT COUNT(*) FROM tab_usuarios)        AS usuarios,
                (SELECT COUNT(*) FROM tab_entradas_centro) AS entradas"
        )->fetch(PDO::FETCH_ASSOC) ?: [];

        $personas_por_tipo = $pdo->query(
            "SELECT tp.nom_tipo_persona, COUNT(p.id_persona) AS total
               FROM tab_tipos_persona tp
               JOIN tab_personas p ON p.id_tipo_persona = tp.id_tipo_persona
              GROUP BY tp.nom_tipo_persona
             HAVING COUNT(p.id_persona) > 0
              ORDER BY 2 DESC"
        )->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        $sistema_totales   = [];
        $personas_por_tipo = [];
    }
}

$path_ingreso = dashboardFindMenuPath($menu_paths, 'porteria/ingreso');
$path_salida  = dashboardFindMenuPath($menu_paths, 'porteria/salida');
$path_usuarios = dashboardFindMenuPath($menu_paths, 'usuarios/usuarios.php')
    ?? dashboardFindMenuPath($menu_paths, 'usuarios.php');
$path_sesiones = dashboardFindMenuPath($menu_paths, 'admin/sesiones');

$quick_actions = [];
if ($es_instructor && $path_fichas !== null) {
    $quick_actions[] = [
        'url'   => smartcsetUrlNomPrograma($path_fichas),
        'label' => 'Las fichas del instructor',
        'icon'  => 'bi-journal-bookmark-fill',
        'class' => 'dashboard-cta--instructor',
    ];
} else {
    if ($path_ingreso !== null) {
        $quick_actions[] = [
            'url'   => smartcsetUrlNomPrograma($path_ingreso),
            'label' => 'Registro de ingreso',
            'icon'  => 'bi-box-arrow-in-right',
            'class' => 'dashboard-cta--ingreso',
        ];
    }
    if ($path_salida !== null) {
        $quick_actions[] = [
            'url'   => smartcsetUrlNomPrograma($path_salida),
            'label' => 'Registro de salida',
            'icon'  => 'bi-box-arrow-left',
            'class' => 'dashboard-cta--salida',
        ];
    }
    if ($path_usuarios !== null) {
        $quick_actions[] = [
            'url'   => smartcsetUrlNomPrograma($path_usuarios),
            'label' => 'Usuarios',
            'icon'  => 'bi-people-fill',
            'class' => 'dashboard-cta--admin',
        ];
    }
    if ($path_sesiones !== null) {
        $quick_actions[] = [
            'url'   => smartcsetUrlNomPrograma($path_sesiones),
            'label' => 'Auditoría de sesiones',
            'icon'  => 'bi-shield-check',
            'class' => 'dashboard-cta--admin',
        ];
    }
    $quick_actions = array_slice($quick_actions, 0, 3);
}

$modulo_registro_off = $es_admin && !AppConfig::moduloRegistroHabilitado();
$has_dashboard_body  = $es_instructor
    ? ($path_fichas !== null || !empty($instructor_resumen['por_ficha'] ?? []))
    : (!empty($quick_actions) || $show_porteria);

$page_title        = 'Inicio';
$active_menu_id    = '0';

$extra_stylesheets = '<link rel="stylesheet" href="' . htmlspecialchars(smartcsetAsset('css/style_menu_principal.css?v='
    . (int) (@filemtime(dirname(__DIR__, 2) . '/public/assets/css/style_menu_principal.css') ?: time()))) . '">';

include smartcsetLayoutPath('head.php');
include smartcsetLayoutPath('sidebar.php');
include smartcsetLayoutPath('topbar.php');
?>

<div class="dash2">

<?php if ($es_instructor && is_array($instructor_resumen)): ?>
<?php include __DIR__ . '/partials/dashboard_instructor.php'; ?>
<?php else: ?>

<header class="dash2-hero">
    <div class="dash2-hero-top">
        <div class="dash2-welcome">
            <span class="dash2-eyebrow"><i class="bi bi-speedometer2"></i> Panel principal</span>
            <h2>Bienvenido, <span><?= htmlspecialchars($wnom_usuario) ?></span></h2>
            <p>Resumen operativo del día. Use el menú lateral o las acciones rápidas para tareas frecuentes.</p>
        </div>
        <?php if ($es_admin): ?>
        <div class="dash2-chips">
            <?php if ($tiene_sesiones_menu && $path_sesiones !== null): ?>
            <a href="<?= htmlspecialchars(smartcsetUrlNomPrograma($path_sesiones)) ?>" class="dash2-chip">
                <i class="bi bi-person-lines-fill"></i>
                <span><strong><?= (int) $sesiones_activas_count ?></strong> sesiones activas</span>
                <i class="bi bi-chevron-right"></i>
            </a>
            <?php elseif ($sesiones_activas_count > 0): ?>
            <span class="dash2-chip dash2-chip--static">
                <i class="bi bi-person-lines-fill"></i>
                <span><strong><?= (int) $sesiones_activas_count ?></strong> sesiones activas</span>
            </span>
            <?php endif; ?>
            <?php if ($modulo_registro_off): ?>
            <span class="dash2-chip dash2-chip--warn" title="El módulo de registro standalone está deshabilitado en configuración">
                <i class="bi bi-exclamation-circle"></i> Módulo registro deshabilitado
            </span>
            <?php endif; ?>
        </div>
        <?php endif; ?>
    </div>

    <?php if ($show_porteria): ?>
    <div class="dash2-kpis" aria-label="Indicadores de portería">
        <div class="dash2-kpi">
            <span class="dash2-kpi-icon"><i class="bi bi-box-arrow-in-right"></i></span>
            <div class="dash2-kpi-body">
                <span class="dash2-kpi-value"><?= (int) $kpi_ingresos ?></span>
                <span class="dash2-kpi-label">Ingresos hoy</span>
            </div>
        </div>
        <div class="dash2-kpi">
            <span class="dash2-kpi-icon"><i class="bi bi-box-arrow-left"></i></span>
            <div class="dash2-kpi-body">
                <span class="dash2-kpi-value"><?= (int) $kpi_salidas ?></span>
                <span class="dash2-kpi-label">Salidas hoy</span>
            </div>
        </div>
        <div class="dash2-kpi dash2-kpi--highlight">
            <span class="dash2-kpi-icon"><i class="bi bi-people-fill"></i></span>
            <div class="dash2-kpi-body">
                <span class="dash2-kpi-value"><?= (int) $personas_dentro ?></span>
                <span class="dash2-kpi-label">Personas dentro ahora</span>
            </div>
        </div>
    </div>
    <?php endif; ?>
</header>

<?php if ($kpi_error !== ''): ?>
<div class="alert alert-danger py-2 px-3" role="alert">
    <i class="bi bi-exclamation-triangle-fill me-1"></i>
    <?= htmlspecialchars($kpi_error) ?>
</div>
<?php endif; ?>

<?php if ($es_admin && !empty($sistema_totales)): ?>
<section class="dash2-panel dash2-summary" aria-label="Inventario del sistema">
    <div class="dash2-section-title"><i class="bi bi-database-fill"></i> Inventario del sistema</div>
    <div class="dash2-stats">
        <div class="dash2-stat">
            <span class="dash2-stat-icon"><i class="bi bi-person-vcard"></i></span>
            <div><span class="dash2-stat-value"><?= number_format((int) $sistema_totales['personas'], 0, ',', '.') ?></span><span class="dash2-stat-label">Personas registradas</span></div>
        </div>
        <div class="dash2-stat">
            <span class="dash2-stat-icon"><i class="bi bi-card-list"></i></span>
            <div><span class="dash2-stat-value"><?= number_format((int) $sistema_totales['fichas'], 0, ',', '.') ?></span><span class="dash2-stat-label">Fichas</span></div>
        </div>
        <div class="dash2-stat">
            <span class="dash2-stat-icon"><i class="bi bi-mortarboard"></i></span>
            <div><span class="dash2-stat-value"><?= number_format((int) $sistema_totales['programas'], 0, ',', '.') ?></span><span class="dash2-stat-label">Programas</span></div>
        </div>
        <div class="dash2-stat">
            <span class="dash2-stat-icon"><i class="bi bi-people"></i></span>
            <div><span class="dash2-stat-value"><?= number_format((int) $sistema_totales['usuarios'], 0, ',', '.') ?></span><span class="dash2-stat-label">Usuarios</span></div>
        </div>
        <div class="dash2-stat">
            <span class="dash2-stat-icon"><i class="bi bi-door-open"></i></span>
            <div><span class="dash2-stat-value"><?= number_format((int) $sistema_totales['entradas'], 0, ',', '.') ?></span><span class="dash2-stat-label">Entradas</span></div>
        </div>
    </div>
    <?php if (!empty($personas_por_tipo)): ?>
    <div class="dash2-tipos">
        <span class="dash2-tipos-label">Personas por tipo</span>
        <?php foreach ($personas_por_tipo as $t): ?>
        <span class="dash2-tipo-chip"><?= htmlspecialchars((string) $t['nom_tipo_persona']) ?> <strong><?= number_format((int) $t['total'], 0, ',', '.') ?></strong></span>
        <?php endforeach; ?>
    </div>
    <?php endif; ?>
</section>
<?php endif; ?>

<?php if (!empty($menu_final) && $has_dashboard_body): ?>
<div class="dash2-main">
    <?php if (!empty($quick_actions)): ?>
    <section class="dash2-panel dash2-actions" aria-label="Acciones rápidas">
        <div class="dash2-section-title"><i class="bi bi-lightning-charge-fill"></i> Acciones rápidas</div>
        <div class="dash2-actions-list">
            <?php foreach ($quick_actions as $cta): ?>
            <a href="<?= htmlspecialchars($cta['url']) ?>" class="dash2-action <?= htmlspecialchars($cta['class']) ?>">
                <span class="dash2-action-icon"><i class="bi <?= htmlspecialchars($cta['icon']) ?>"></i></span>
                <span class="dash2-action-label"><?= htmlspecialchars($cta['label']) ?></span>
                <i class="bi bi-arrow-right dash2-action-arrow"></i>
            </a>
            <?php endforeach; ?>
        </div>
    </section>
    <?php endif; ?>

    <?php if ($show_porteria): ?>
    <section class="dash2-panel dash2-activity" aria-label="Actividad reciente">
        <div class="dash2-section-title"><i class="bi bi-clock-history"></i> Actividad reciente <span class="dash2-section-meta">últimos ingresos de hoy</span></div>
        <?php if (empty($actividad_reciente)): ?>
        <div class="dash2-empty">
            <i class="bi bi-inbox"></i>
            <p>Sin ingresos registrados hoy.</p>
        </div>
        <?php else: ?>
        <div class="dash2-activity-list">
            <?php foreach ($actividad_reciente as $row): ?>
            <?php $nomCompleto = trim((string) ($row['nom_persona'] ?? '') . ' ' . (string) ($row['ape_persona'] ?? '')); ?>
            <div class="dash2-activity-row">
                <span class="dash2-activity-time"><?= htmlspecialchars(smartcsetFormatDbTimestamp($row['fec_ingreso'] ?? null, 'H:i')) ?></span>
                <span class="dash2-activity-name" title="<?= htmlspecialchars($nomCompleto) ?>"><?= htmlspecialchars($nomCompleto) ?></span>
                <span class="dash2-activity-tipo"><?= htmlspecialchars((string) ($row['nom_tipo_persona'] ?? '')) ?></span>
                <span class="dash2-activity-puerta" title="<?= htmlspecialchars((string) ($row['nom_entrada_centro'] ?? '')) ?>"><?= (int) ($row['id_entrada_centro'] ?? 0) ?></span>
            </div>
            <?php endforeach; ?>
        </div>
        <?php endif; ?>
    </section>
    <?php endif; ?>
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

<?php endif; ?>

</div>

<?php
if (!empty($_SESSION['flash_msg'])) {
    renderPageFlash($_SESSION['flash_msg'], $_SESSION['flash_tipo'] ?? 'success');
    unset($_SESSION['flash_msg'], $_SESSION['flash_tipo']);
}
?>

<?php include smartcsetLayoutPath('footer.php'); ?>
