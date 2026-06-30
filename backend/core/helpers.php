<?php
/**
 * FUNCIONES DE UTILIDAD COMPARTIDAS - SmartCSET
 */

/** Mínimo de caracteres para pass_usuario (CHECK en tab_usuarios). */
const PASSWORD_MIN_LENGTH = 12;

/** Convierte booleanos PostgreSQL/PHP a bool nativo. */
function smartcsetPgBool(mixed $value): bool
{
    if ($value === true || $value === 1 || $value === '1') {
        return true;
    }
    if ($value === false || $value === 0 || $value === '0' || $value === null || $value === '') {
        return false;
    }
    if (is_string($value)) {
        return in_array(strtolower(trim($value)), ['t', 'true', 'yes', 'on'], true);
    }

    return (bool) $value;
}

/**
 * Sincroniza flags de sesión con tab_usuarios (evita ind_usuario desactualizado tras cambios en BD).
 */
function smartcsetSincronizarSesionUsuario(PDO $pdo): void
{
    if (session_status() !== PHP_SESSION_ACTIVE || empty($_SESSION['id_usuario'])) {
        return;
    }

    static $sincronizado = false;
    if ($sincronizado) {
        return;
    }
    $sincronizado = true;

    $stmt = $pdo->prepare(
        'SELECT nom_usuario, ind_usuario, ind_estado
         FROM tab_usuarios
         WHERE id_usuario = CAST(? AS TEXT)'
    );
    $stmt->execute([(string) $_SESSION['id_usuario']]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        return;
    }

    $_SESSION['nom_usuario'] = (string) ($row['nom_usuario'] ?? $_SESSION['nom_usuario'] ?? '');
    $_SESSION['ind_usuario'] = smartcsetPgBool($row['ind_usuario'] ?? false);
    $_SESSION['ind_estado'] = smartcsetPgBool($row['ind_estado'] ?? true);
}

/**
 * Prefijo de URL bajo el dominio (vacío en raíz, '/smartcset' en subcarpeta Apache).
 */
function smartcsetBasePath(): string
{
    return defined('APP_BASE_PATH') && APP_BASE_PATH !== ''
        ? '/' . APP_BASE_PATH
        : '';
}

/**
 * Ruta absoluta de aplicación (incluye APP_BASE_PATH).
 */
function smartcsetUrl(string $path): string
{
    $path = '/' . ltrim(str_replace('\\', '/', $path), '/');

    return smartcsetBasePath() . $path;
}

/** Prefijo hacia /assets/ (con APP_BASE_PATH si aplica). */
function smartcsetAssetHref(): string
{
    return smartcsetUrl('/assets/');
}

/** URL versionada bajo /assets/ */
function smartcsetAsset(string $relativePath): string
{
    return smartcsetAssetHref() . ltrim(str_replace('\\', '/', $relativePath), '/');
}

/** Query ?v= para cache-bust de assets estáticos. */
function smartcsetAssetVersion(string $relativePath): int
{
    $root = dirname(__DIR__, 2) . '/frontend/web/public/assets/';
    return @filemtime($root . ltrim(str_replace('\\', '/', $relativePath), '/')) ?: time();
}

/** Tag script hacia /assets/ con cache-bust. */
function smartcsetAssetScript(string $relativePath): string
{
    $src = smartcsetAsset($relativePath);
    $ver = smartcsetAssetVersion($relativePath);

    return '<script src="' . htmlspecialchars($src, ENT_QUOTES, 'UTF-8') . '?v=' . $ver . '"></script>';
}

/** Inyecta meta + variable JS para clientes (cargar antes de http-client.js). */
function smartcsetRenderBasePathBootstrap(): void
{
    $base = smartcsetBasePath();
    echo '<meta name="smartcset-base-path" content="'
        . htmlspecialchars($base, ENT_QUOTES, 'UTF-8') . '">' . "\n";
}

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
        'ficha'       => 'bi-journal-bookmark-fill',
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
 * Los administradores tienen acceso total al catálogo de menús y módulos.
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

    $esAdmin = smartcsetPgBool($row['ind_usuario'] ?? false);

    if (
        $esAdmin
        && isset($_SESSION['id_usuario'])
        && (string) $_SESSION['id_usuario'] === $idUsuario
    ) {
        $_SESSION['ind_usuario'] = true;
    }

    $cache[$idUsuario] = $esAdmin;
    return $esAdmin;
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
    return smartcsetUrl('/index.php');
}

/**
 * IP del cliente para sesiones (login y validación).
 * Con SESION_TRUST_PROXY=1 usa el primer X-Forwarded-For si es IP válida.
 */
function smartcsetClientIp(): string
{
    if (defined('SESION_TRUST_PROXY') && SESION_TRUST_PROXY) {
        $forwarded = trim((string) ($_SERVER['HTTP_X_FORWARDED_FOR'] ?? ''));
        if ($forwarded !== '') {
            $first = trim(explode(',', $forwarded)[0]);
            if (filter_var($first, FILTER_VALIDATE_IP)) {
                return substr($first, 0, 45);
            }
        }
    }

    $remote = trim((string) ($_SERVER['REMOTE_ADDR'] ?? ''));
    if ($remote !== '' && filter_var($remote, FILTER_VALIDATE_IP)) {
        return substr($remote, 0, 45);
    }

    return '';
}

/** true si SESION_VALIDAR_IP está activo en .env. */
function smartcsetSesionValidarIp(): bool
{
    return defined('SESION_VALIDAR_IP') && SESION_VALIDAR_IP;
}

/**
 * Compara IP guardada en tab_sesiones con la IP actual del request.
 * Si no hay IP registrada (sesión antigua), no bloquea.
 */
function smartcsetSesionIpCoincide(?string $ipRegistrada, string $ipActual): bool
{
    $ipRegistrada = $ipRegistrada !== null ? trim($ipRegistrada) : '';
    $ipActual = trim($ipActual);

    if ($ipRegistrada === '') {
        return true;
    }

    if ($ipActual === '') {
        return false;
    }

    if (str_contains($ipRegistrada, ':') || str_contains($ipActual, ':')) {
        return strtolower($ipRegistrada) === strtolower($ipActual);
    }

    return $ipRegistrada === $ipActual;
}

/** Endpoint POST del heartbeat de presencia. */
function smartcsetSesionHeartbeatUrl(): string
{
    return smartcsetUrl('/routers/sesion/v1/heartbeat.php');
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
    return smartcsetAssetHref();
}

/**
 * @deprecated Use smartcsetProjectAssetHref()
 */
function smartcsetModulosAssetHref(): string
{
    return smartcsetProjectAssetHref();
}

/**
 * Convierte nom_programa legacy (src/, ../, hermanos de menu/) a ruta bajo pages/.
 */
function smartcsetNormalizeNomPrograma(string $nomPrograma): string
{
    $path = trim(str_replace('\\', '/', $nomPrograma));
    if ($path === '') {
        return '';
    }

    if (preg_match('#^https?://#i', $path)) {
        return $path;
    }

    if (strcasecmp($path, 'Exit') === 0 || strcasecmp($path, 'exit.php') === 0) {
        return '/routers/auth/v1/logout.php';
    }

    if (str_contains(strtolower($path), 'logout.php')) {
        return '/routers/auth/v1/logout.php';
    }

    if (str_starts_with($path, 'pages/')) {
        return $path;
    }

    if (str_starts_with($path, 'src/')) {
        return 'pages/' . substr($path, 4);
    }

    if (str_starts_with($path, '../')) {
        $path = 'pages/' . ltrim(substr($path, 3), '/');
    } elseif (!str_contains($path, '/') && str_ends_with($path, '.php')) {
        // Antiguo src/menu/*.php (hermano de menu_principal.php)
        $path = 'pages/menu/' . $path;
    } elseif (!str_starts_with($path, 'pages/') && !preg_match('#^(assets|uploads|img)/#', $path)) {
        $path = 'pages/' . ltrim($path, '/');
    }

    return match ($path) {
        'pages/modulos/entradas.php' => 'pages/modulos/entradas/index.php',
        'pages/modulos/ingresos.php', 'pages/modulos/porteria/ingresos.php' => 'pages/modulos/porteria/ingreso/index.php',
        'pages/modulos/salidas.php', 'pages/modulos/porteria/salidas.php' => 'pages/modulos/porteria/salida/index.php',
        default => $path,
    };
}

/**
 * Enlace a nom_programa (ruta relativa al document root public/, ej. pages/modulos/porteria/ingreso/index.php).
 */
function smartcsetUrlNomPrograma(string $nomPrograma): string
{
    $nomPrograma = trim($nomPrograma);
    if ($nomPrograma === '' || strcasecmp($nomPrograma, 'no_aplica') === 0) {
        return '#';
    }

    $normalized = smartcsetNormalizeNomPrograma($nomPrograma);
    if ($normalized === '') {
        return '#';
    }

    if (preg_match('#^https?://#i', $normalized)) {
        return $normalized;
    }

    if (str_starts_with($normalized, '/')) {
        return smartcsetUrl($normalized);
    }

    if (preg_match('#^(assets|uploads|img)/#', $normalized)) {
        return smartcsetUrl('/' . $normalized);
    }

    if (str_contains($normalized, '.php') || str_contains($normalized, '/')) {
        return smartcsetUrl('/' . ltrim($normalized, '/'));
    }

    return smartcsetAssetHref() . ltrim($normalized, '/');
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
    if (str_starts_with($path, 'assets/') || str_starts_with($path, 'uploads/')) {
        return smartcsetUrl('/' . $path);
    }

    return ($assetHref !== '' ? $assetHref : smartcsetAssetHref()) . $path;
}
