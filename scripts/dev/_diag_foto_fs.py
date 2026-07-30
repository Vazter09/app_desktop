#!/usr/bin/env python3
"""Buscar fotos biometria en disco + permisos + docroot real."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
RUN = r"""#!/bin/bash
set +e
echo '=== find franzanderson / 1095814477 ==='
sudo find /var/www/html -iname '*1095814477*' 2>/dev/null | head -40
sudo find /var/www -iname '*franzanderson*' 2>/dev/null | head -20
echo '=== uploads/biometria tree ==='
ls -la /var/www/html/smartcset/frontend/web/public/uploads/ 2>&1
ls -la /var/www/html/smartcset/frontend/web/public/uploads/biometria/ 2>&1 | head -40
echo '=== symlink public? ==='
ls -la /var/www/html/smartcset/frontend/web/public 2>&1 | head -20
echo '=== php resolve path ==='
php -r '
require "/var/www/html/smartcset/backend/services/porteria/biometria_photo_service.php";
$r="uploads/biometria/1095814477/1095814477_franzanderson.jpg";
echo "valid=". (BiometriaPhotoService::esRutaFotoValida($r)?"1":"0") ."\n";
$b=BiometriaPhotoService::leerFoto($r);
echo ($b===null)?"LEER_NULL\n":("LEER_OK len=".strlen($b)."\n");
$ref = new ReflectionClass("BiometriaPhotoService");
echo "file=".$ref->getFileName()."\n";
'
echo '=== storage porteria ==='
ls /var/www/html/smartcset/storage/porteria 2>&1 | head
find /var/www/html/smartcset/storage -iname '*1095814477*' 2>/dev/null | head
echo DONE
"""


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        values[k.strip()] = v.strip().strip('"').strip("'")
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
    out = b""
    idle = 0
    while True:
        got = False
        if channel.recv_ready():
            out += channel.recv(8192)
            got = True
            idle = 0
        if channel.recv_stderr_ready():
            out += channel.recv_stderr(8192)
            got = True
            idle = 0
        if channel.exit_status_ready():
            while channel.recv_ready():
                out += channel.recv(8192)
            while channel.recv_stderr_ready():
                out += channel.recv_stderr(8192)
            break
        if not got:
            idle += 1
            if idle > 800:
                break
            time.sleep(0.05)
    return "\n".join(
        ln
        for ln in out.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )


def main() -> int:
    env = load_env()
    host = env.get("SERVER_HOST") or env.get("DB_HOST") or "10.5.213.103"
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
    remote = f"/tmp/diag_foto_fs_{int(time.time())}.sh"
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(RUN)
    sftp.chmod(remote, 0o755)
    sftp.close()
    print(sudo_bash(client, env["SERVER_PASS"], f"bash {remote}"))
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
