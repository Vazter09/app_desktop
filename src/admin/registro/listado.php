<?php
require_once __DIR__ . '/../../core/prepare.php';
require_once __DIR__ . '/../../core/ErrorHandler.php';
require_once __DIR__ . '/../../core/helpers.php';
require_once __DIR__ . '/../../modulos/registro/lib/personas_list.php';

session_start();

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ../../../index.php');
    exit();
}

$menuTipoMap = [
    '0301' => ['tipo' => 1, 'titulo' => 'Aprendiz', 'form' => 'aprendiz.php'],
    '0302' => ['tipo' => 2, 'titulo' => 'Instructor', 'form' => 'instructor.php'],
    '0303' => ['tipo' => 3, 'titulo' => 'Funcionario', 'form' => 'funcionario.php'],
    '0304' => ['tipo' => 4, 'titulo' => 'Contratista', 'form' => 'contratista.php'],
];

$active_menu_id = trim((string) ($_GET['menu'] ?? ''));
if ($active_menu_id === '' || !isset($menuTipoMap[$active_menu_id])) {
    foreach ($menuTipoMap as $id => $cfg) {
        $active_menu_id = $id;
        break;
    }
}

$cfg = $menuTipoMap[$active_menu_id];
$tipo = (int) $cfg['tipo'];
$tituloTipo = (string) $cfg['titulo'];
$formFile = (string) $cfg['form'];

$w_mensaje = '';
$w_tipo_alerta = 'success';
$personas = [];

try {
    $personas = registroFetchPersonasPorTipo($pdo, $tipo);
} catch (PDOException $e) {
    $w_mensaje = ErrorHandler::handleDatabaseException($e)['message'];
    $w_tipo_alerta = 'danger';
}

$smartcset_asset_href = smartcsetProjectAssetHref();

if (isset($_GET['partial']) && $_GET['partial'] === '1') {
    header('Content-Type: text/html; charset=UTF-8');
    include __DIR__ . '/listado_fragment.php';
    exit;
}

$page_title = 'Listado — ' . $tituloTipo;
$wnom_usuario = $_SESSION['nom_usuario'] ?? '';

$vListadoCss = @filemtime(dirname(__DIR__, 3) . '/css/registro-listado-admin.css') ?: time();
$extra_stylesheets = '<link rel="stylesheet" href="'
    . htmlspecialchars($smartcset_asset_href, ENT_QUOTES, 'UTF-8')
    . 'css/registro-listado-admin.css?v=' . (int) $vListadoCss . '">';

$extra_css = '';

include __DIR__ . '/../../layout/head.php';
include __DIR__ . '/../../layout/sidebar.php';
include __DIR__ . '/../../layout/topbar.php';
?>

<?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

<div id="registro-listado-host">
<?php include __DIR__ . '/listado_fragment.php'; ?>
</div>

<?php
$vListadoJs = @filemtime(dirname(__DIR__, 3) . '/js/registro-listado-admin.js') ?: time();
$extra_js = '<script src="'
    . htmlspecialchars($smartcset_asset_href, ENT_QUOTES, 'UTF-8')
    . 'js/registro-listado-admin.js?v=' . (int) $vListadoJs . '"></script>';
include __DIR__ . '/../../layout/footer.php';
?>
