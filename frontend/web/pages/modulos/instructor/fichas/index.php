<?php
declare(strict_types=1);

require_once dirname(__DIR__, 4) . '/init.php';
require_once dirname(__DIR__, 6) . '/backend/services/instructor/asistencia_service.php';
require_once __DIR__ . '/../lib/instructor_ui.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

$idUsuario = (string) $_SESSION['id_usuario'];
$esAdmin = usuarioEsAdministrador($pdo, $idUsuario);
$idInstructor = instructorResolverIdDesdeSesion($pdo, $idUsuario);

if ($idInstructor === null && !$esAdmin) {
    http_response_code(403);
    exit('Acceso restringido a instructores registrados o administradores.');
}

$ctx = [
    'id_instructor' => $idInstructor,
    'es_admin' => $esAdmin,
    'modo' => $idInstructor !== null ? 'instructor' : 'admin_lectura',
    'id_usuario' => $idUsuario,
];

$w_mensaje = '';
$w_tipo_alerta = 'success';
$fichas = [];
$asistencia = [
    'id_ficha' => 0,
    'desde' => date('Y-m-d'),
    'hasta' => date('Y-m-d'),
    'rows' => [],
    'por_fecha' => [],
];
$idFichaSel = null;
$fichaSel = null;
$vistaDetalle = false;
$puedeEscribir = ($ctx['modo'] === 'instructor');
$programaSel = trim((string) ($_GET['programa'] ?? ''));
$carreras = [];
$fichasPrograma = [];
$vistaCarrerasAdmin = false;
$vistaFichasProgramaAdmin = false;

try {
    $fichas = instructorListarFichasPorContexto(
        $stmt_fun_listar_fichas_instructor,
        $stmt_fun_listar_fichas_admin,
        $ctx
    );
    $rango = instructorNormalizarRangoFechas($_GET);

    $idFichaGet = (int) ($_GET['id_ficha'] ?? 0);
    if ($idFichaGet > 0) {
        $idFichaSel = instructorResolverFichaSeleccionada($fichas, $_GET);
        if ($idFichaSel === null && ($ctx['modo'] ?? '') === 'admin_lectura') {
            if (instructorPuedeAccederFicha(
                $pdo,
                $stmt_fun_listar_fichas_instructor,
                $stmt_fun_listar_fichas_admin,
                $ctx,
                $idFichaGet
            )) {
                $idFichaSel = $idFichaGet;
            }
        }
    } elseif (count($fichas) === 1 && ($ctx['modo'] ?? '') === 'instructor') {
        $idFichaSel = (int) ($fichas[0]['id_ficha'] ?? 0) ?: null;
    }

    if ($idFichaSel !== null) {
        $fichaSel = instructorBuscarFichaEnListado($fichas, $idFichaSel);
        if ($fichaSel === null && ($ctx['modo'] ?? '') === 'admin_lectura') {
            if (instructorPuedeAccederFicha(
                $pdo,
                $stmt_fun_listar_fichas_instructor,
                $stmt_fun_listar_fichas_admin,
                $ctx,
                $idFichaSel
            )) {
                $fichaSel = [
                    'id_ficha' => $idFichaSel,
                    'nom_programa' => 'Consulta administrador',
                    'nom_jornada' => '',
                ];
            }
        }

        if ($fichaSel === null) {
            $idFichaSel = null;
        } else {
            $vistaDetalle = true;
            $asistencia = instructorListarAsistenciaPorContexto(
                $stmt_fun_listar_asistencia_ficha,
                $stmt_fun_listar_asistencia_ficha_admin,
                $ctx,
                $idFichaSel,
                $rango['desde'],
                $rango['hasta']
            );
        }
    }
} catch (InvalidArgumentException $e) {
    $w_mensaje = $e->getMessage();
    $w_tipo_alerta = 'warning';
} catch (PDOException $e) {
    $w_mensaje = ErrorHandler::userMessageFromException($e);
    $w_tipo_alerta = 'danger';
}

if (!$vistaDetalle && ($ctx['modo'] ?? '') === 'admin_lectura') {
    $carreras = instructorAgruparFichasPorPrograma($fichas);
    if ($programaSel !== '') {
        $fichasPrograma = instructorFichasDePrograma($carreras, $programaSel);
        if ($fichasPrograma === []) {
            $w_mensaje = 'El programa seleccionado no tiene fichas en ejecución.';
            $w_tipo_alerta = 'warning';
            $programaSel = '';
        } else {
            $vistaFichasProgramaAdmin = true;
        }
    } else {
        $vistaCarrerasAdmin = true;
    }
}

$basePath = parse_url((string) ($_SERVER['REQUEST_URI'] ?? ''), PHP_URL_PATH) ?: '';
$fechaHoy = date('Y-m-d');
$modoRango = isset($_GET['desde'], $_GET['hasta'])
    && trim((string) $_GET['desde']) !== ''
    && trim((string) $_GET['hasta']) !== ''
    && trim((string) ($_GET['desde'] ?? '')) !== trim((string) ($_GET['hasta'] ?? ''));

$page_title = $vistaDetalle && $idFichaSel !== null
    ? 'Ficha ' . $idFichaSel
    : instructorTituloListado($ctx, $programaSel);
$active_menu_id = ($vistaDetalle && $idFichaSel !== null)
    ? instructorMenuIdFicha($idFichaSel)
    : '0601';
$wnom_usuario = (string) ($_SESSION['nom_usuario'] ?? '');
$_root = smartcsetProjectRoot();
$_css_v = @filemtime($_root . '/frontend/web/public/assets/css/modulo_instructor_fichas.css') ?: time();
$_js_http_v = @filemtime($_root . '/frontend/web/public/assets/js/services/http-client.js') ?: time();
$_js_router_v = @filemtime($_root . '/frontend/web/public/assets/js/services/instructor-router.js') ?: time();
$_js_v = @filemtime($_root . '/frontend/web/public/assets/js/instructor-fichas.js') ?: time();
$extra_stylesheets = '<link rel="stylesheet" href="' . htmlspecialchars(smartcsetAsset('css/modulo_instructor_fichas.css'))
    . '?v=' . (int) $_css_v . '">';
$extra_js = $vistaDetalle
    ? '<script src="' . htmlspecialchars(smartcsetAsset('js/services/http-client.js')) . '?v=' . (int) $_js_http_v . '"></script>'
    . '<script src="' . htmlspecialchars(smartcsetAsset('js/services/instructor-router.js')) . '?v=' . (int) $_js_router_v . '"></script>'
    . '<script src="' . htmlspecialchars(smartcsetAsset('js/instructor-fichas.js')) . '?v=' . (int) $_js_v . '"></script>'
    : '';

include smartcsetLayoutPath('head.php');
include smartcsetLayoutPath('sidebar.php');
include smartcsetLayoutPath('topbar.php');

renderPageFlash($w_mensaje, $w_tipo_alerta);
?>
<div class="inst-fichas-page" id="inst-fichas-page"
     data-base-path="<?= htmlspecialchars($basePath) ?>"
     data-modo="<?= htmlspecialchars((string) $ctx['modo']) ?>"
     data-puede-escribir="<?= $puedeEscribir ? '1' : '0' ?>"
     <?php if ($vistaDetalle && $idFichaSel !== null): ?>
     data-id-ficha="<?= (int) $idFichaSel ?>"
     data-nom-programa="<?= htmlspecialchars((string) ($fichaSel['nom_programa'] ?? '')) ?>"
     data-nom-jornada="<?= htmlspecialchars((string) ($fichaSel['nom_jornada'] ?? '')) ?>"
     <?php endif; ?>>

    <?php if ($vistaDetalle): ?>
        <div class="inst-fichas-header mb-3">
            <h2 class="inst-fichas-title h4 mb-0">
                <i class="bi bi-people-fill me-2"></i>Asistencia de aprendices
            </h2>
            <?php if (($ctx['modo'] ?? '') === 'admin_lectura'): ?>
                <p class="text-muted small mb-0 mt-1">Modo consulta administrador (solo lectura).</p>
            <?php endif; ?>
        </div>
        <div id="inst-fichas-detalle">
            <?php include __DIR__ . '/fragment_detalle.php'; ?>
        </div>

    <?php else: ?>
        <div class="inst-fichas-header mb-4">
            <h2 class="inst-fichas-title h4 mb-1">
                <i class="bi bi-<?= $vistaFichasProgramaAdmin ? 'collection' : ($vistaCarrerasAdmin ? 'mortarboard-fill' : 'journal-bookmark-fill') ?> me-2"></i>
                <?= htmlspecialchars(instructorTituloListado($ctx, $programaSel)) ?>
            </h2>
            <p class="inst-fichas-subtitle mb-0">
                <?= htmlspecialchars(instructorSubtituloListado($ctx, $programaSel)) ?>
            </p>
        </div>

        <?php if ($fichas === []): ?>
            <div class="alert alert-info">No hay fichas en ejecución disponibles para consultar.</div>
        <?php elseif ($vistaCarrerasAdmin): ?>
            <?php include __DIR__ . '/fragment_lista_carreras.php'; ?>
        <?php elseif ($vistaFichasProgramaAdmin): ?>
            <?php include __DIR__ . '/fragment_lista_fichas_programa.php'; ?>
        <?php else: ?>
            <?php include __DIR__ . '/fragment_lista.php'; ?>
        <?php endif; ?>
    <?php endif; ?>

</div>
<?php
include smartcsetLayoutPath('footer.php');
