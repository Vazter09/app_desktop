<?php
/**
 * FUNCIONES DE UTILIDAD COMPARTIDAS - SmartCSET
 */

/** Mínimo de caracteres para pass_usuario (CHECK en tab_usuarios). */
const PASSWORD_MIN_LENGTH = 12;

/** ind_id_padre de menús raíz (tab_menus exige LENGTH >= 2). */
function smartcsetMenuPadreRaiz(): string
{
    return '00';
}

/** true si el menú es de primer nivel (acepta '00' y legacy '0'). */
function smartcsetMenuEsPadreRaiz(?string $indIdPadre): bool
{
    return $indIdPadre === '00' || $indIdPadre === '0';
}

function getIcon(string $nombre): string
{
    $mapa = [
        'config'      => 'bi-gear-fill',
        'configur'    => 'bi-gear-fill',
        'usuarios'    => 'bi-people-fill',
        'perfil'      => 'bi-person-badge-fill',
        'menu'        => 'bi-layout-sidebar',
        'acceso'      => 'bi-shield-lock-fill',
        'departam'    => 'bi-building',
        'cargo'       => 'bi-briefcase-fill',
        'liquidacion' => 'bi-calculator-fill',
        'proceso'     => 'bi-play-circle-fill',
        'nómina'      => 'bi-file-earmark-text-fill',
        'nomina'      => 'bi-file-earmark-text-fill',
        'reportes'    => 'bi-file-bar-graph-fill',
        'tablas'      => 'bi-table',
        'copia'       => 'bi-files',
        'copiar'      => 'bi-files',
        'cambiar'     => 'bi-key-fill',
        'entrada'     => 'bi-door-open-fill',
        'ingreso'     => 'bi-box-arrow-in-right',
        'egreso'      => 'bi-box-arrow-right',
        'fin'         => 'bi-power',
        'exit'        => 'bi-power',
        'salir'       => 'bi-power',
        'inicio'      => 'bi-house-fill',
        'admin'       => 'bi-shield-fill-check',
        'registro'    => 'bi-person-vcard-fill',
        'aprendiz'    => 'bi-mortarboard-fill',
        'instructor'  => 'bi-person-workspace',
        'funcionario' => 'bi-bank2',
        'contratista' => 'bi-briefcase-fill',
    ];

    $lower = strtolower($nombre);
    foreach ($mapa as $palabra => $icono) {
        if (stripos($lower, $palabra) !== false) {
            return $icono;
        }
    }
    return 'bi-grid-fill';
}

/**
 * Usuario con perfil administrador (ind_usuario = TRUE en tab_usuarios).
 */
function usuarioEsAdministrador(PDO $pdo, string $idUsuario): bool
{
    static $cache = [];

    if (isset($cache[$idUsuario])) {
        return $cache[$idUsuario];
    }

    $stmt = $pdo->prepare(
        'SELECT ind_usuario FROM tab_usuarios WHERE id_usuario = CAST(? AS TEXT)'
    );
    $stmt->execute([$idUsuario]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    $cache[$idUsuario] = $row && !empty($row['ind_usuario']);
    return $cache[$idUsuario];
}

/**
 * Menús visibles en sidebar/dashboard: administrador = catálogo completo.
 */
function obtenerMenusUsuario(PDO $pdo, string $idUsuario): array
{
    if (usuarioEsAdministrador($pdo, $idUsuario)) {
        $stmt = $pdo->query(
            'SELECT id_menu, nom_menu, ind_id_padre, nom_programa
             FROM tab_menus
             ORDER BY id_menu ASC'
        );
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    $stmt = $pdo->prepare(
        'SELECT m.id_menu, m.nom_menu, m.ind_id_padre, m.nom_programa
         FROM tab_menu_usuarios mu
         INNER JOIN tab_menus m ON mu.id_menu = m.id_menu
         WHERE mu.id_usuario = CAST(? AS TEXT)
         ORDER BY m.id_menu ASC'
    );
    $stmt->execute([$idUsuario]);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

/**
 * Mensaje flash → toast Bootstrap (leído por smartcset-toast.js al cargar).
 */
function renderPageFlash(?string $mensaje, string $tipo = 'success', ?string $titulo = null): void
{
    if ($mensaje === null || $mensaje === '') {
        return;
    }

    $tipo = in_array($tipo, ['success', 'danger', 'warning', 'info'], true) ? $tipo : 'success';

    if ($titulo === null) {
        $titulo = match ($tipo) {
            'danger'  => 'No se pudo completar',
            'warning' => 'Atención',
            'info'    => 'Información',
            default   => 'Listo',
        };
    }

    echo '<div id="page-flash-data" class="d-none"'
        . ' data-type="' . htmlspecialchars($tipo) . '"'
        . ' data-title="' . htmlspecialchars($titulo) . '"'
        . ' data-message="' . htmlspecialchars($mensaje) . '"></div>';
}

/**
 * Valida longitud mínima de contraseña según regla de BD.
 */
function validarLongitudPassword(string $password, bool $esObligatoria = true): void
{
    if ($esObligatoria && $password === '') {
        throw new Exception('La contraseña es obligatoria.');
    }
    if ($password !== '' && strlen($password) < PASSWORD_MIN_LENGTH) {
        throw new Exception(
            'La contraseña debe tener al menos ' . PASSWORD_MIN_LENGTH . ' caracteres.'
        );
    }
}

/**
 * Prefijo relativo (../…) desde la página actual hasta la raíz del proyecto (css/, js/).
 * Cubre src/modulos/*, src/admin/*, src/menu, src/usuarios, etc.
 */
/** URL relativa al login (index.php) desde la página actual. */
function smartcsetLoginUrl(): string
{
    return smartcsetProjectAssetHref() . 'index.php';
}

/** Endpoint POST del heartbeat de presencia (relativo a la página actual). */
function smartcsetSesionHeartbeatUrl(): string
{
    return smartcsetProjectAssetHref() . 'src/core/ajax_sesion_heartbeat.php';
}

/** Zona horaria de visualización (Colombia por defecto). */
function smartcsetAppTimezone(): string
{
    return defined('APP_TIMEZONE') ? APP_TIMEZONE : 'America/Bogota';
}

/** Zona en la que PostgreSQL escribe CURRENT_TIMESTAMP (servidor suele ser UTC). */
function smartcsetDbTimezone(): string
{
    return defined('DB_TIMEZONE') ? DB_TIMEZONE : 'UTC';
}

/**
 * Formatea un TIMESTAMP de BD (sin zona) a hora local de la aplicación.
 */
function smartcsetFormatDbTimestamp(?string $timestamp, string $format = 'd/m/Y H:i'): string
{
    $timestamp = trim((string) $timestamp);
    if ($timestamp === '') {
        return '—';
    }

    try {
        $dt = new DateTimeImmutable($timestamp, new DateTimeZone(smartcsetDbTimezone()));

        return $dt->setTimezone(new DateTimeZone(smartcsetAppTimezone()))->format($format);
    } catch (Exception) {
        return '—';
    }
}

/** Epoch UTC para comparar timeouts con timestamps de BD. */
function smartcsetDbTimestampEpoch(?string $timestamp): ?int
{
    $timestamp = trim((string) $timestamp);
    if ($timestamp === '') {
        return null;
    }

    try {
        return (new DateTimeImmutable($timestamp, new DateTimeZone(smartcsetDbTimezone())))->getTimestamp();
    } catch (Exception) {
        return null;
    }
}

function smartcsetProjectAssetHref(): string
{
    $scriptDir = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '/'));
    if (preg_match('#/src/(.*)$#', $scriptDir, $m)) {
        $rel = trim((string) $m[1], '/');
        if ($rel === '') {
            return '../';
        }

        return str_repeat('../', count(explode('/', $rel)) + 1);
    }

    return '../../';
}

/**
 * @deprecated Use smartcsetProjectAssetHref()
 */
function smartcsetModulosAssetHref(): string
{
    return smartcsetProjectAssetHref();
}

/**
 * Enlace a nom_programa (ruta desde raíz del proyecto, ej. src/modulos/porteria/ingreso/index.php).
 */
function smartcsetUrlNomPrograma(string $nomPrograma): string
{
    $nomPrograma = trim($nomPrograma);
    if ($nomPrograma === '' || strcasecmp($nomPrograma, 'no_aplica') === 0) {
        return '#';
    }

    return smartcsetProjectAssetHref() . ltrim($nomPrograma, '/');
}

/**
 * URL del logo para <img src> (ruta relativa desde la página actual).
 */
function smartcsetLogoUrl(string $assetHref = ''): string
{
    $path = 'img/logo-sena.png';
    if (class_exists('AppConfig', false) && AppConfig::hasDbConfig()) {
        $path = AppConfig::pathLogo();
    } elseif (defined('PATH_LOGO') && PATH_LOGO !== '') {
        $path = PATH_LOGO;
    }

    $path = ltrim(str_replace('\\', '/', $path), '/');

    return $assetHref . $path;
}
