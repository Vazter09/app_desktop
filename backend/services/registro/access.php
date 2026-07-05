<?php
declare(strict_types=1);

function registroModuloHabilitado(): bool
{
    return AppConfig::moduloRegistroHabilitado();
}

function registroUsaLoginStandalone(): bool
{
    // El módulo de registro usa la sesión principal + menú '0300' asignado por el admin,
    // igual que el resto de módulos (portería, SIEM, usuarios...).
    return false;
}

function registroTieneSesionPrincipal(): bool
{
    return !empty($_SESSION['id_usuario']);
}

function registroTieneSesionStandalone(): bool
{
    return !empty($_SESSION['registro_authenticated']);
}

function registroRequireModuloHabilitado(): void
{
    if (!registroModuloHabilitado()) {
        // El módulo está deshabilitado por configuración, no por caída del servicio.
        http_response_code(403);
        header('Content-Type: text/html; charset=UTF-8');
        echo '<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><title>Módulo no disponible</title></head>';
        echo '<body style="font-family:sans-serif;padding:2rem;text-align:center;">';
        echo '<h1>Módulo de registro deshabilitado</h1>';
        echo '<p>El administrador ha desactivado el registro de personas. Contacte al administrador del sistema.</p>';
        echo '</body></html>';
        exit;
    }
}

function registroLoginUrl(): string
{
    return smartcsetUrl('/pages/modulos/registro/login.php');
}

function registroIndexUrl(): string
{
    return smartcsetUrl('/pages/modulos/registro/index.php');
}

function registroMainLoginUrl(): string
{
    return smartcsetUrl('/index.php');
}

function registroMenuUrl(): string
{
    return smartcsetUrl('/pages/menu/menu_principal.php');
}

function registroRequireAccess(PDO $pdo): void
{
    registroRequireModuloHabilitado();

    if (registroUsaLoginStandalone()) {
        if (!registroTieneSesionStandalone()) {
            header('Location: ' . registroLoginUrl());
            exit;
        }
        return;
    }

    if (!registroTieneSesionPrincipal()) {
        header('Location: ' . registroMainLoginUrl());
        exit;
    }

    if (!usuarioTieneMenu($pdo, (string) $_SESSION['id_usuario'], '0300')) {
        http_response_code(403);
        die('Acceso denegado. No tiene el módulo de registro asignado.');
    }
}

function registroAuthenticateStandalone(string $user, string $pass): bool
{
    $cfgUser = AppConfig::usrRegistro();
    $hash = AppConfig::passRegistroHash();

    if ($cfgUser === null || $hash === null) {
        return false;
    }

    if ($user !== $cfgUser) {
        return false;
    }

    if (!password_verify($pass, $hash)) {
        return false;
    }

    $_SESSION['registro_authenticated'] = true;
    $_SESSION['registro_username'] = $user;
    $_SESSION['registro_login_time'] = time();
    return true;
}

function registroLogout(): void
{
    unset($_SESSION['registro_authenticated'], $_SESSION['registro_username'], $_SESSION['registro_login_time']);
    header('Location: ' . registroLoginUrl());
    exit;
}

function registroDisplayUsername(): string
{
    if (registroUsaLoginStandalone()) {
        return registroTieneSesionStandalone()
            ? (string) ($_SESSION['registro_username'] ?? 'registro')
            : 'registro';
    }

    return (string) ($_SESSION['id_usuario'] ?? 'registro');
}
