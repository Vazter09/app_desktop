#!/usr/bin/env python3
"""Despliega fix Estado/Ficha (+ foto consultar) del modal portería a .111.

Archivos:
  - backend/core/prepare.php  ($stmt_buscar_persona_doc + JOIN aprendices)
  - backend/routers/porteria/_lib/Payload.php  (formatPersona: id_ficha/estado)
  - backend/routers/porteria/v1/ingreso/consultar.php
  - backend/services/porteria/biometria_photo_service.php

Uso:
  set SERVER_HOST=10.5.213.111
  python scripts/dev/deploy_ficha_modal_consultar.py

Requiere SERVER_USER y SERVER_PASS en .env (o en el entorno).
"""
from __future__ import annotations

import os
import sys
import time
from pathlib import Path

try:
    import paramiko
except ImportError:
    print("FAIL: falta paramiko. Ejecute: python -m pip install paramiko")
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
DEFAULT_HOST = "10.5.213.111"

FILES = [
    "backend/core/prepare.php",
    "backend/routers/porteria/_lib/Payload.php",
    "backend/routers/porteria/v1/ingreso/consultar.php",
    "backend/services/porteria/biometria_photo_service.php",
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


def ensure_remote_dir(sftp: paramiko.SFTPClient, remote_dir: str) -> None:
    parts = remote_dir.strip("/").split("/")
    cur = ""
    for part in parts:
        cur += "/" + part
        try:
            sftp.stat(cur)
        except OSError:
            sftp.mkdir(cur)


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
            if idle > 400:
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
    host = os.environ.get("SERVER_HOST") or env.get("SERVER_HOST") or DEFAULT_HOST
    user = os.environ.get("SERVER_USER") or env.get("SERVER_USER", "")
    password = os.environ.get("SERVER_PASS") or env.get("SERVER_PASS", "")
    if not user or not password:
        print("FAIL: defina SERVER_USER y SERVER_PASS en .env (o en el entorno).")
        print(f"Host objetivo: {host}")
        print("Archivos a desplegar:")
        for rel in FILES:
            print(f"  - {rel}")
        return 1

    for rel in FILES:
        if not (ROOT / rel).is_file():
            print(f"FAIL: falta local {rel}")
            return 1

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"Conectando a {user}@{host}...")
    client.connect(
        hostname=host,
        username=user,
        password=password,
        timeout=20,
        allow_agent=False,
        look_for_keys=False,
    )

    remote_tmp = f"/tmp/smartcset_deploy_ficha_{int(time.time())}"
    code_m, out_m = sudo_bash(
        client, password, f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}"
    )
    if code_m != 0:
        print("FAIL mkdir tmp:", out_m)
        client.close()
        return 1

    sftp = client.open_sftp()
    for rel in FILES:
        remote_tmp_file = f"{remote_tmp}/{rel}"
        ensure_remote_dir(
            sftp, str(Path(remote_tmp_file).parent).replace("\\", "/")
        )
        sftp.put(str(ROOT / rel), remote_tmp_file)
        print(f"OK subido tmp {rel}")
    sftp.close()

    copy_parts = []
    for rel in FILES:
        dest_dir = str(Path(f"{REMOTE_ROOT}/{rel}").parent).replace("\\", "/")
        copy_parts.append(f"mkdir -p {dest_dir}")
        copy_parts.append(f"cp -f {remote_tmp}/{rel} {REMOTE_ROOT}/{rel}")
    verify = (
        f"grep -n \"ap.id_ficha\" {REMOTE_ROOT}/backend/core/prepare.php | head -3"
        f" && grep -n \"estado_formacion\" "
        f"{REMOTE_ROOT}/backend/routers/porteria/_lib/Payload.php | head -5"
        f" && rm -rf {remote_tmp}"
        f" && echo DEPLOY_FICHA_OK"
    )
    code2, out2 = sudo_bash(
        client, password, " && ".join(copy_parts) + " && " + verify
    )
    print(out2)
    client.close()
    if code2 != 0 or "DEPLOY_FICHA_OK" not in out2:
        print("FAIL deploy")
        return 1
    print(f"OK deploy ficha/modal a {host}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
