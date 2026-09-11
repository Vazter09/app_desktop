#!/usr/bin/env python3
"""Despliega SOLO consultar ingreso/salida (con foto) al src/api live de .103."""
from __future__ import annotations

import os
import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "scripts" / "dev" / "_tmp_live103"
REMOTE_API = "/var/www/html/smartcset/src/api"
FILES = [
    "porteria_ingreso_consultar.php",
    "porteria_salida_consultar.php",
]


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
    text = "\n".join(
        ln
        for ln in out_buf.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )
    return code, text


def main() -> int:
    env = load_env()
    host = os.environ.get("SERVER_HOST") or "10.5.213.103"
    user = os.environ.get("SERVER_USER") or "adsocset"
    password = os.environ.get("SERVER_PASS") or env.get("SERVER_PASS", "")
    if not password:
        print("FAIL: SERVER_PASS vacio")
        return 1

    for name in FILES:
        local = SRC / name
        if not local.is_file():
            print(f"FAIL falta {local}")
            return 1

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=user,
        password=password,
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    stamp = int(time.time())
    tmp = f"/tmp/consultar_foto_{stamp}"
    code, out = sudo_bash(
        client,
        password,
        f"mkdir -p {tmp} && chmod 777 {tmp} && "
        f"test -f /var/www/html/smartcset/src/services/porteria/biometria_photo_service.php "
        f"&& echo PHOTO_SVC_OK || echo PHOTO_SVC_MISSING",
    )
    print(out)
    if "PHOTO_SVC_MISSING" in out:
        client.close()
        print("FAIL: falta biometria_photo_service.php")
        return 1

    sftp = client.open_sftp()
    for name in FILES:
        sftp.put(str(SRC / name), f"{tmp}/{name}")
    sftp.close()

    copies = " && ".join(
        f"cp -a {REMOTE_API}/{name} {tmp}/{name}.bak && "
        f"cp -f {tmp}/{name} {REMOTE_API}/{name} && "
        f"php -l {REMOTE_API}/{name}"
        for name in FILES
    )
    verify = " && ".join(
        f"grep -q foto_base64 {REMOTE_API}/{name}"
        for name in FILES
    )
    cmd = (
        f"{copies} && {verify} && "
        "chown www-data:www-data "
        f"{REMOTE_API}/porteria_ingreso_consultar.php "
        f"{REMOTE_API}/porteria_salida_consultar.php && "
        "echo DEPLOY_CONSULTAR_FOTO_OK"
    )
    code, out = sudo_bash(client, password, cmd)
    print(out)
    client.close()
    if code != 0 or "DEPLOY_CONSULTAR_FOTO_OK" not in out:
        print("FAIL deploy consultar foto")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
