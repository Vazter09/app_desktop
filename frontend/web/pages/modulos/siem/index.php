<?php
declare(strict_types=1);

require_once __DIR__ . '/init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

if (!usuarioTieneMenu($pdo, (string) $_SESSION['id_usuario'], '21101')) {
    http_response_code(403);
    die('Acceso denegado. No tiene el módulo SIEM asignado.');
}

$kpis         = ['total_intentos_hoy' => 0, 'fallos_hoy' => 0, 'ips_bloqueadas' => 0, 'sesiones_activas' => 0];
$top_ips      = [];
$alertas      = [];
$w_mensaje    = '';
$w_tipo_alerta = 'danger';

try {
    // Umbrales de rate limiting sincronizados desde .env (E3) y
    // zona horaria local para "hoy" / horas de la gráfica
    $w_tz = smartcsetAppTimezone();

    $stmt = $pdo->prepare("SELECT * FROM fun_siem_dashboard_kpis(?, ?, ?)");
    $stmt->execute([LOGIN_MAX_INTENTOS, LOGIN_VENTANA_MINUTOS, $w_tz]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row) {
        $kpis = $row;
    }

    $stmt = $pdo->prepare("SELECT * FROM fun_siem_top_ips_fallidas(?, ?, ?)");
    $stmt->execute([LOGIN_MAX_INTENTOS, LOGIN_VENTANA_MINUTOS, $w_tz]);
    $top_ips = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $stmt = $pdo->prepare("SELECT * FROM fun_siem_alertas_recientes(?, ?)");
    $stmt->execute([LOGIN_MAX_INTENTOS, LOGIN_VENTANA_MINUTOS]);
    $alertas = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $w_mensaje = ErrorHandler::userMessageFromException($e);
}

// Respuesta parcial (solo el fragmento HTML) para el auto-refresh vía
// SmartcsetListado.loadIntoHost() — evita duplicar el render en JS.
if (isset($_GET['partial']) && $_GET['partial'] === '1') {
    header('Content-Type: text/html; charset=UTF-8');
    include __DIR__ . '/dashboard_fragment.php';
    exit;
}

$page_title    = 'SIEM — Panel de Control';
$active_menu_id = '21101';
$wnom_usuario  = $_SESSION['nom_usuario'];

$_root   = modulosProjectRoot();
$_assets = $_root . '/frontend/web/public/assets';
$_css_v  = @filemtime($_assets . '/css/siem.css') ?: time();
$extra_stylesheets = '<link rel="stylesheet" href="'
    . htmlspecialchars($smartcset_asset_href) . 'css/siem.css?v=' . (int) $_css_v . '">';

include modulosLayout('layout/head.php');
include modulosLayout('layout/sidebar.php');
include modulosLayout('layout/topbar.php');
?>

<div id="siem-panel-host">
<?php include __DIR__ . '/dashboard_fragment.php'; ?>
</div>

<?php
$_v_listado = @filemtime($_assets . '/js/core/smartcset-listado.js') ?: time();
$_v_panel   = @filemtime($_assets . '/js/core/siem_dashboard.js') ?: time();

$extra_js = '<script src="' . htmlspecialchars(smartcsetAsset('js/core/smartcset-listado.js')) . '?v=' . (int) $_v_listado . '"></script>'
    . '<script src="' . htmlspecialchars(smartcsetAsset('js/core/siem_dashboard.js')) . '?v=' . (int) $_v_panel . '"></script>';

include modulosLayout('layout/footer.php');
?>
