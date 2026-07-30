#!/usr/bin/env python3
"""Reproduce identificar vía PHP CLI contra prepare.php (error real)."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]

PHP = r"""<?php
declare(strict_types=1);
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['REMOTE_ADDR'] = '127.0.0.1';
$_SERVER['HTTP_USER_AGENT'] = 'cli-smoke';
session_start();
$_SESSION['id_usuario'] = 'porteria';
require_once '/var/www/html/smartcset/backend/routers/porteria/prepare.php';
$vec = '[' . implode(',', array_fill(0, 128, '0.01')) . ']';
try {
    global $stmt_fun_identificar_persona_por_rostro, $pdo;
    $stmt_fun_identificar_persona_por_rostro->execute([$vec, 0.35]);
    $id = $stmt_fun_identificar_persona_por_rostro->fetchColumn();
    echo 'ID=' . var_export($id, true) . PHP_EOL;
    echo 'PDO_IDENTIFY_OK' . PHP_EOL;
} catch (Throwable $e) {
    echo 'ERR_CLASS=' . get_class($e) . PHP_EOL;
    echo 'ERR_MSG=' . $e->getMessage() . PHP_EOL;
    if ($e instanceof PDOException) {
        echo 'SQLSTATE=' . ($e->errorInfo[0] ?? '') . PHP_EOL;
        echo 'DRIVER=' . ($e->errorInfo[1] ?? '') . PHP_EOL;
        echo 'INFO=' . ($e->errorInfo[2] ?? '') . PHP_EOL;
    }
    echo 'PDO_IDENTIFY_FAIL' . PHP_EOL;
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


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> str:
    transport = client.get_transport()
    assert transport is not None
    channel = transport.open_session()
    channel.get_pty()
    channel.exec_command("sudo -S bash -lc " + repr(inner))
    time.sleep(0.4)
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
            if idle > 700:
                break
            time.sleep(0.05)
    return "\n".join(
        ln
        for ln in out_buf.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )


def main() -> int:
    env = load_env()
    host = env.get("SERVER_HOST") or env.get("DB_HOST", "10.5.213.103")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    remote = f"/tmp/php_id_{int(time.time())}.php"
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(PHP)
    sftp.close()
    out = sudo_bash(client, env["SERVER_PASS"], f"php {remote}; rm -f {remote}")
    (ROOT / "scripts/dev/_last_php_identify.txt").write_text(out, encoding="utf-8")
    print(out[:5000])
    client.close()
    return 0 if "PDO_IDENTIFY_OK" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
