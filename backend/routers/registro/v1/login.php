<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/prepare.php';
require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';
require_once dirname(__DIR__, 3) . '/services/registro/access.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

if (!registroModuloHabilitado()) {
    RouterResponse::fail('El módulo de registro está deshabilitado.', 403);
}

$raw = file_get_contents('php://input');
$json = is_string($raw) && trim($raw) !== '' ? json_decode($raw, true) : $_POST;
if (!is_array($json)) {
    $json = $_POST;
}

$usuario = trim((string) ($json['usuario'] ?? ''));
$clave = (string) ($json['clave'] ?? '');

if ($usuario === '' || $clave === '') {
    RouterResponse::fail('Por favor complete todos los campos.');
}

if (!registroAuthenticateStandalone($usuario, $clave)) {
    sleep(1);
    RouterResponse::fail('Credenciales inválidas. Acceso denegado.');
}

RouterResponse::ok([
    'message' => 'Sesión iniciada.',
    'redirect' => registroIndexUrl(),
]);
