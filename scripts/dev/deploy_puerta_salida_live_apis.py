#!/usr/bin/env python3
"""Crea APIs porteria faltantes en src/backend/api y deps de salida."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
API = "/var/www/html/smartcset/src/backend/api"
MW = "/var/www/html/smartcset/src/backend/middleware"
SVC = "/var/www/html/smartcset/src/backend/services/porteria"
AUTH = "/var/www/html/smartcset/src/backend/_lib_porteria/Auth.php"

MW_PHP = r"""<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/includes/prepare.php';
require_once dirname(__DIR__) . '/includes/RouterResponse.php';
require_once dirname(__DIR__) . '/includes/lib/acceso_sesion.php';
require_once dirname(__DIR__) . '/_lib_porteria/Auth.php';

function porteriaRequireSessionOrDevice(): array
{
    global $pdo;

    $bearer = PorteriaRouterAuth::extractBearerToken();
    if ($bearer !== null && $bearer !== '') {
        return ['type' => 'device', 'row' => PorteriaRouterAuth::requireDevice($pdo)];
    }

    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    if (empty($_SESSION['id_usuario'])) {
        RouterResponse::unauthorized('Sesión no válida.');
    }

    $idUsuario = (string) $_SESSION['id_usuario'];

    return [
        'type' => 'web',
        'id_usuario' => $idUsuario,
        'usr_audit' => $idUsuario,
        'origen_cliente' => (string) ($_SESSION['origen_cliente'] ?? 'web'),
    ];
}

function porteriaAuthAuditUser(array $auth): string
{
    if (($auth['type'] ?? '') === 'device') {
        return (string) ($auth['row']['id_usuario_audit'] ?? 'device');
    }

    return (string) ($auth['usr_audit'] ?? accesoUsuarioAuditoriaSesion());
}
"""

CATALOGOS_PHP = r"""<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/api/porteria_prepare.php';
require_once dirname(__DIR__) . '/middleware/require_session_or_device.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    RouterResponse::fail('Método no permitido.', 405);
}

porteriaRequireSessionOrDevice();

try {
    RouterResponse::ok(porteriaApiCatalogos());
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e), 500);
}
"""

INGRESO_REG_PHP = r"""<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/api/porteria_prepare.php';
require_once dirname(__DIR__) . '/middleware/require_session_or_device.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$auth = porteriaRequireSessionOrDevice();
$device = ($auth['type'] ?? '') === 'device'
    ? $auth['row']
    : ['id_usuario_audit' => porteriaAuthAuditUser($auth), 'usr_audit' => porteriaAuthAuditUser($auth)];
$json = PorteriaRouterPayload::readJsonBody();

try {
    $result = porteriaApiRegistrarIngreso($device, $json);
    RouterResponse::ok($result);
} catch (PDOException $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
"""

SALIDA_REG_PHP = r"""<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/api/porteria_prepare.php';
require_once dirname(__DIR__) . '/middleware/require_session_or_device.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    RouterResponse::fail('Método no permitido.', 405);
}

$auth = porteriaRequireSessionOrDevice();
$device = ($auth['type'] ?? '') === 'device'
    ? $auth['row']
    : ['id_usuario_audit' => porteriaAuthAuditUser($auth), 'usr_audit' => porteriaAuthAuditUser($auth)];
$json = PorteriaRouterPayload::readJsonBody();

try {
    $result = porteriaApiRegistrarSalida($device, $json);
    RouterResponse::ok($result);
} catch (PDOException $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
} catch (Throwable $e) {
    RouterResponse::fail(ErrorHandler::userMessageFromException($e));
}
"""


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        values[key.strip()] = val.strip().strip('"').strip("'")
    return values


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> tuple[int, str]:
    transport = client.get_transport()
    assert transport is not None
    channel = transport.open_session()
    channel.get_pty()
    channel.exec_command("sudo -S bash -lc " + repr(inner))
    time.sleep(0.3)
    if channel.send_ready():
        channel.send(password + "\n")
    out_buf = b""
    idle = 0
    while True:
        got = False
        if channel.recv_ready():
            out_buf += channel.recv(8192)
            got = True
            idle = 0
        if channel.recv_stderr_ready():
            out_buf += channel.recv_stderr(8192)
            got = True
            idle = 0
        if channel.exit_status_ready():
            while channel.recv_ready():
                out_buf += channel.recv(8192)
            while channel.recv_stderr_ready():
                out_buf += channel.recv_stderr(8192)
            break
        if not got:
            idle += 1
            if idle > 500:
                break
            time.sleep(0.05)
    code = channel.recv_exit_status() if channel.exit_status_ready() else 1
    text = out_buf.decode("utf-8", errors="replace")
    filtered = [
        ln
        for ln in text.splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    ]
    return code, "\n".join(filtered)


def main() -> int:
    env = load_env()
    password = env.get("SERVER_PASS", "")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.111"),
        username=env.get("SERVER_USER", ""),
        password=password,
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    sftp = client.open_sftp()
    tmp = f"/tmp/smartcset_api_{int(time.time())}"
    sudo_bash(client, password, f"mkdir -p {tmp} {MW} {API} {SVC} && chmod 777 {tmp}")

    blobs = {
        f"{tmp}/mw.php": MW_PHP,
        f"{tmp}/cat.php": CATALOGOS_PHP,
        f"{tmp}/ing.php": INGRESO_REG_PHP,
        f"{tmp}/sal.php": SALIDA_REG_PHP,
    }
    for path, content in blobs.items():
        with sftp.open(path, "w") as fh:
            fh.write(content.encode("utf-8"))

    sftp.put(str(ROOT / "backend/services/porteria/documento_service.php"), f"{tmp}/documento_service.php")
    sftp.put(str(ROOT / "backend/services/porteria/parse_captura_service.php"), f"{tmp}/parse_captura_service.php")

    with sftp.open(AUTH, "r") as fh:
        auth = fh.read().decode("utf-8")
    auth2 = auth.replace(
        "require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';",
        "require_once dirname(__DIR__) . '/includes/RouterResponse.php';",
        1,
    )
    with sftp.open(f"{tmp}/Auth.php", "w") as fh:
        fh.write(auth2.encode("utf-8"))
    sftp.close()

    cmd = (
        f"cp -f {tmp}/mw.php {MW}/require_session_or_device.php && "
        f"cp -f {tmp}/cat.php {API}/porteria_catalogos.php && "
        f"cp -f {tmp}/ing.php {API}/porteria_ingreso_registrar.php && "
        f"cp -f {tmp}/sal.php {API}/porteria_salida_registrar.php && "
        f"cp -f {tmp}/documento_service.php {SVC}/documento_service.php && "
        f"cp -f {tmp}/parse_captura_service.php {SVC}/parse_captura_service.php && "
        f"cp -f {tmp}/Auth.php {AUTH} && "
        f"php -l {API}/porteria_catalogos.php && "
        f"php -l {API}/porteria_salida_registrar.php && "
        f"php -l {MW}/require_session_or_device.php && "
        "echo DEPLOY8_OK"
    )
    code, out = sudo_bash(client, password, cmd)
    print(out)
    client.close()
    if code != 0 or "DEPLOY8_OK" not in out:
        print("FAIL deploy8")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
