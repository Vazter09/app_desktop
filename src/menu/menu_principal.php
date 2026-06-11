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
        foreach ($item['submenus'] ?? [] as $sub) {
            $walk($sub);
            foreach ($sub['items'] ?? [] as $leaf) {
                $walk($leaf);
            }
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
                foreach ($menu_final as &$abuelo) {
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

$menu_paths   = dashboardFlattenMenuPaths($menu_final);
$es_admin     = usuarioEsAdministrador($pdo, $wid_usuario);

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

$actividad_reciente = array_slice($ingresos_hoy, 0, 8);

$hay_datos_porteria = $kpi_ingresos > 0 || $kpi_salidas > 0 || $personas_dentro > 0;
$show_porteria      = $tiene_porteria || $hay_datos_porteria;

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

$path_ingreso = dashboardFindMenuPath($menu_paths, 'porteria/ingreso');
$path_salida  = dashboardFindMenuPath($menu_paths, 'porteria/salida');
$path_usuarios = dashboardFindMenuPath($menu_paths, 'usuarios/usuarios.php')
    ?? dashboardFindMenuPath($menu_paths, 'usuarios.php');
$path_sesiones = dashboardFindMenuPath($menu_paths, 'admin/sesiones');

$quick_actions = [];
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

$modulo_registro_off = $es_admin && !AppConfig::moduloRegistroHabilitado();
$has_dashboard_body  = !empty($quick_actions) || $show_porteria;

$page_title        = 'Inicio';
$active_menu_id    = '0';
$smartcset_asset_href = '../../';

include __DIR__ . '/../layout/head.php';
include __DIR__ . '/../layout/sidebar.php';
include __DIR__ . '/../layout/topbar.php';
?>

<div class="dashboard-shell">
<header class="dashboard-header">
    <div class="dashboard-welcome">
        <div class="dashboard-eyebrow">
            <i class="bi bi-speedometer2"></i>
            <span>Panel principal</span>
        </div>
        <h2>Bienvenido, <span><?= htmlspecialchars($wnom_usuario) ?></span></h2>
        <p>Resumen operativo del día. Use el menú lateral para navegar o las acciones rápidas para tareas frecuentes.</p>
    </div>
    <?php if ($es_admin): ?>
    <div class="dashboard-admin-strip">
        <?php if ($tiene_sesiones_menu && $path_sesiones !== null): ?>
        <a href="<?= htmlspecialchars(smartcsetUrlNomPrograma($path_sesiones)) ?>" class="dashboard-admin-chip">
            <i class="bi bi-person-lines-fill"></i>
            <span><strong><?= (int) $sesiones_activas_count ?></strong> sesiones activas</span>
            <i class="bi bi-chevron-right dashboard-admin-chip-arrow"></i>
        </a>
        <?php elseif ($sesiones_activas_count > 0): ?>
        <div class="dashboard-admin-chip dashboard-admin-chip--static">
            <i class="bi bi-person-lines-fill"></i>
            <span><strong><?= (int) $sesiones_activas_count ?></strong> sesiones activas en el sistema</span>
        </div>
        <?php endif; ?>
        <?php if ($modulo_registro_off): ?>
        <span class="dashboard-badge-warning" title="El módulo de registro standalone está deshabilitado en configuración">
            <i class="bi bi-exclamation-circle"></i> Módulo registro deshabilitado
        </span>
        <?php endif; ?>
    </div>
    <?php endif; ?>
</header>

<?php if ($kpi_error !== ''): ?>
<div class="alert alert-danger py-2 px-3 dashboard-alert" role="alert">
    <i class="bi bi-exclamation-triangle-fill me-1"></i>
    <?= htmlspecialchars($kpi_error) ?>
</div>
<?php endif; ?>

<?php if ($show_porteria): ?>
<section class="dashboard-kpi-row" aria-label="Indicadores de portería">
    <article class="dashboard-kpi-card">
        <div class="dashboard-kpi-icon"><i class="bi bi-box-arrow-in-right"></i></div>
        <div class="dashboard-kpi-body">
            <span class="dashboard-kpi-value"><?= (int) $kpi_ingresos ?></span>
            <span class="dashboard-kpi-label">Ingresos hoy</span>
        </div>
    </article>
    <article class="dashboard-kpi-card">
        <div class="dashboard-kpi-icon dashboard-kpi-icon--salida"><i class="bi bi-box-arrow-left"></i></div>
        <div class="dashboard-kpi-body">
            <span class="dashboard-kpi-value"><?= (int) $kpi_salidas ?></span>
            <span class="dashboard-kpi-label">Salidas hoy</span>
        </div>
    </article>
    <article class="dashboard-kpi-card dashboard-kpi-card--highlight">
        <div class="dashboard-kpi-icon dashboard-kpi-icon--dentro"><i class="bi bi-people-fill"></i></div>
        <div class="dashboard-kpi-body">
            <span class="dashboard-kpi-value"><?= (int) $personas_dentro ?></span>
            <span class="dashboard-kpi-label">Personas dentro ahora</span>
        </div>
    </article>
</section>
<?php if (!empty($por_tipo_persona)): ?>
<section class="dashboard-tipo-row" aria-label="Por tipo de persona">
    <span class="dashboard-tipo-row-label">Por tipo de persona</span>
    <ul class="dashboard-tipo-chips">
        <?php foreach ($por_tipo_persona as $tipo => $cant): ?>
        <li class="dashboard-tipo-chip">
            <span class="dashboard-tipo-chip-name"><?= htmlspecialchars($tipo) ?></span>
            <strong class="dashboard-tipo-chip-count"><?= (int) $cant ?></strong>
        </li>
        <?php endforeach; ?>
    </ul>
</section>
<?php endif; ?>
<?php endif; ?>

<?php if (!empty($menu_final) && $has_dashboard_body): ?>
<div class="dashboard-main">
    <?php if (!empty($quick_actions)): ?>
    <section class="dashboard-quick-actions" aria-label="Acciones rápidas">
        <h3 class="dashboard-section-title">
            <i class="bi bi-lightning-charge-fill"></i> Acciones rápidas
        </h3>
        <div class="dashboard-cta-row">
            <?php foreach ($quick_actions as $cta): ?>
            <a href="<?= htmlspecialchars($cta['url']) ?>" class="dashboard-cta <?= htmlspecialchars($cta['class']) ?>">
                <i class="bi <?= htmlspecialchars($cta['icon']) ?>"></i>
                <span><?= htmlspecialchars($cta['label']) ?></span>
            </a>
            <?php endforeach; ?>
        </div>
    </section>
    <?php endif; ?>

    <?php if ($show_porteria): ?>
    <section class="dashboard-activity" aria-label="Actividad reciente">
        <h3 class="dashboard-section-title">
            <i class="bi bi-clock-history"></i> Actividad reciente
            <span class="dashboard-section-meta">Últimos ingresos de hoy</span>
        </h3>
        <?php if (empty($actividad_reciente)): ?>
        <div class="dashboard-activity-empty">
            <i class="bi bi-inbox"></i>
            <p>Sin ingresos registrados hoy.</p>
        </div>
        <?php else: ?>
        <div class="dashboard-activity-table-wrap">
            <table class="table table-sm table-hover dashboard-activity-table mb-0">
                <thead>
                    <tr>
                        <th>Hora</th>
                        <th>Persona</th>
                        <th>Tipo</th>
                        <th class="text-end">Puerta</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($actividad_reciente as $row): ?>
                    <?php
                    $nomCompleto = trim((string) ($row['nom_persona'] ?? '') . ' ' . (string) ($row['ape_persona'] ?? ''));
                    ?>
                    <tr>
                        <td class="text-nowrap"><?= htmlspecialchars(smartcsetFormatDbTimestamp($row['fec_ingreso'] ?? null, 'H:i')) ?></td>
                        <td>
                            <span class="dashboard-activity-nombre" title="<?= htmlspecialchars($nomCompleto) ?>">
                                <?= htmlspecialchars($nomCompleto) ?>
                            </span>
                        </td>
                        <td><span class="dashboard-tipo-badge"><?= htmlspecialchars((string) ($row['nom_tipo_persona'] ?? '')) ?></span></td>
                        <td class="text-end text-nowrap">
                            <span class="dashboard-puerta-badge" title="<?= htmlspecialchars((string) ($row['nom_entrada_centro'] ?? '')) ?>">
                                <?= (int) ($row['id_entrada_centro'] ?? 0) ?>
                            </span>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
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
</div>
<?php endif; ?>

</div>

<?php
if (!empty($_SESSION['flash_msg'])) {
    renderPageFlash($_SESSION['flash_msg'], $_SESSION['flash_tipo'] ?? 'success');
    unset($_SESSION['flash_msg'], $_SESSION['flash_tipo']);
}
?>

<?php include __DIR__ . '/../layout/footer.php'; ?>
