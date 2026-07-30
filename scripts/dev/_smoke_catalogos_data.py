#!/usr/bin/env python3
"""Verifica porteriaApiCatalogos() vía PHP CLI en el servidor (sin sesión)."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]

PHP = r"""<?php
declare(strict_types=1);
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['REMOTE_ADDR'] = '127.0.0.1';
require_once '/var/www/html/smartcset/backend/routers/porteria/prepare.php';
$c = porteriaApiCatalogos();
echo 'tipos_doc=' . count($c['tipos_doc'] ?? []) . PHP_EOL;
echo 'tipos_persona=' . count($c['tipos_persona'] ?? []) . PHP_EOL;
echo 'entradas=' . count($c['entradas'] ?? []) . PHP_EOL;
if (!empty($c['tipos_doc'][0])) {
    echo 'doc0=' . json_encode($c['tipos_doc'][0], JSON_UNESCAPED_UNICODE) . PHP_EOL;
}
echo 'CATALOGOS_DATA_OK' . PHP_EOL;
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
    return "\n".join(
        ln
        for ln in out_buf.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )


def main() -> int:
    env = load_env()
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    remote = f"/tmp/smoke_catalogos_{int(time.time())}.php"
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(PHP)
    sftp.close()
    out = sudo_bash(client, env["SERVER_PASS"], f"php {remote}; rm -f {remote}")
    print(out)
    client.close()
    return 0 if "CATALOGOS_DATA_OK" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
