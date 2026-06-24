<?php
declare(strict_types=1);

/**
 * Entrada común de listados admin por tipo.
 * Requiere $personasListado: menu_id, titulo, fetch (callable).
 */

require_once dirname(__DIR__, 4) . '/init.php';
require_once dirname(__DIR__, 6) . '/backend/core/listado_ui.php';
require_once __DIR__ . '/listado_config.php';

if (!isset($personasListado) || !is_array($personasListado)) {
    http_response_code(500);
    exit('Configuración de listado no definida.');
}

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

$menuId = (string) ($personasListado['menu_id'] ?? '');
$tituloTipo = (string) ($personasListado['titulo'] ?? 'Personas');
$fetchFn = $personasListado['fetch'] ?? null;

if ($menuId === '' || !is_string($fetchFn) || $fetchFn === '' || !function_exists($fetchFn)) {
    http_response_code(500);
    exit('Listado de personas mal configurado.');
}

$w_mensaje = '';
$w_tipo_alerta = 'success';
$filters = $_GET;
$basePath = parse_url((string) ($_SERVER['REQUEST_URI'] ?? ''), PHP_URL_PATH) ?: '';
$listadoResult = [
    'rows' => [],
    'total' => 0,
    'page' => 1,
    'per_page' => 25,
    'total_pages' => 1,
    'from' => 0,
    'to' => 0,
];

try {
    $raw = $fetchFn($pdo, $filters);
    $listadoResult = listadoNormalizeResult(is_array($raw) ? $raw : [], $filters);
} catch (PDOException $e) {
    $w_mensaje = ErrorHandler::handleDatabaseException($e)['message'];
    $w_tipo_alerta = 'danger';
}

$filtrosFields = $personasListado['filtros_fields'] ?? null;
if (is_string($filtrosFields) && $filtrosFields !== '' && function_exists($filtrosFields)) {
    $filtrosFields = $filtrosFields($pdo);
} elseif (!is_array($filtrosFields)) {
    $filtrosFields = null;
}

$listadoShellConfig = personasListadoBuildShellConfig(
    $listadoResult,
    [
        'titulo' => $tituloTipo,
        'base_path' => $basePath,
        'filtros_fields' => $filtrosFields,
        'tabla_columns' => $personasListado['tabla_columns'] ?? null,
        'empty_message' => $personasListado['empty_message'] ?? null,
    ],
    $filters
);

$personasListadoMenuId = $menuId;

$fragmentPath = (string) ($personasListado['fragment'] ?? '');
if ($fragmentPath === '' || !is_readable($fragmentPath)) {
    $fragmentPath = __DIR__ . '/fragment_listado.php';
}

if (isset($_GET['partial']) && $_GET['partial'] === '1') {
    header('Content-Type: text/html; charset=UTF-8');
    include $fragmentPath;
    exit;
}

$page_title = 'Listado — ' . $tituloTipo;
$wnom_usuario = $_SESSION['nom_usuario'] ?? '';

$_asset_root = dirname(__DIR__, 4) . '/public/assets';
$vListadoCss = @filemtime($_asset_root . '/css/personas-listado-admin.css') ?: time();
$vComponentsCss = @filemtime($_asset_root . '/css/smartcset-listado.css') ?: time();
$extra_stylesheets = '<link rel="stylesheet" href="' . htmlspecialchars(smartcsetAsset('css/personas-listado-admin.css')) . '?v=' . (int) $vListadoCss . '">'
    . '<link rel="stylesheet" href="' . htmlspecialchars(smartcsetAsset('css/smartcset-listado.css?v=' . (int) $vComponentsCss . '')) . '">';

$extra_css = '';

include smartcsetLayoutPath('head.php');
include smartcsetLayoutPath('sidebar.php');
include smartcsetLayoutPath('topbar.php');
?>

<?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

<div id="personas-listado-host"
     data-smart-listado-host="1"
     data-active-menu="<?= htmlspecialchars($menuId, ENT_QUOTES, 'UTF-8') ?>">
<?php include $fragmentPath; ?>
</div>

<?php
$vListadoJs = @filemtime($_asset_root . '/js/core/smartcset-listado.js') ?: time();
$vPersonasJs = @filemtime($_asset_root . '/js/core/personas-listado-admin.js') ?: time();
$extra_js = '<script src="' . htmlspecialchars(smartcsetAsset('js/core/smartcset-listado.js')) . '?v=' . (int) $vListadoJs . '"></script>'
    . '<script src="' . htmlspecialchars(smartcsetAsset('js/core/personas-listado-admin.js')) . '?v=' . (int) $vPersonasJs . '"></script>';
include smartcsetLayoutPath('footer.php');
