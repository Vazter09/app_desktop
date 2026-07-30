#!/usr/bin/env python3
"""Despliega endpoints y servicios de biometría facial a 10.5.213.103.

Corrige HTTP 404 en /routers/porteria/v1/biometria/identificar.php
cuando el código no está en el document root remoto.

Uso: python scripts/dev/deploy_biometria_routers.py
"""
from __future__ import annotations

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
DEFAULT_HOST = "10.5.213.103"

# Archivos PHP necesarios para enrolar/identificar (facial).
FILES = [
    "backend/routers/porteria/v1/biometria/enrolar.php",
    "backend/routers/porteria/v1/biometria/identificar.php",
    "backend/routers/porteria/v1/biometria/huella_enrolar.php",
    "backend/routers/porteria/v1/biometria/huella_identificar.php",
    "backend/services/porteria/biometria_service.php",
    "backend/services/porteria/biometria_photo_service.php",
    "backend/services/porteria/biometria_huella_service.php",
    "backend/routers/porteria/prepare.php",
    "backend/routers/porteria/_lib/Payload.php",
    "backend/core/prepare.php",
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
    host = env.get("SERVER_HOST", DEFAULT_HOST)
    user = env.get("SERVER_USER", "")
    password = env.get("SERVER_PASS", "")
    if not user or not password:
        print("FAIL: defina SERVER_USER y SERVER_PASS en .env")
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

    # Diagnóstico previo
    check_cmd = (
        f"ls -la {REMOTE_ROOT}/backend/routers/porteria/v1/biometria 2>&1; "
        f"ls -la {REMOTE_ROOT}/frontend/web/public/routers 2>&1; "
        f"readlink -f {REMOTE_ROOT}/frontend/web/public/routers 2>&1; "
        f"test -f {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/identificar.php "
        f"&& echo IDENTIFICAR_OK || echo IDENTIFICAR_MISSING"
    )
    code, out = sudo_bash(client, password, check_cmd)
    print("--- estado remoto antes ---")
    print(out)
    print(f"(exit={code})")

    # Subir a /tmp (writable) y luego sudo cp al document root.
    remote_tmp = f"/tmp/smartcset_deploy_biometria_{int(time.time())}"
    code_m, out_m = sudo_bash(client, password, f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}")
    if code_m != 0:
        print("FAIL mkdir tmp:", out_m)
        client.close()
        return 1

    sftp = client.open_sftp()
    for rel in FILES:
        local = ROOT / rel
        # Mantener estructura bajo /tmp/.../backend/...
        remote_tmp_file = f"{remote_tmp}/{rel}"
        ensure_remote_dir(sftp, str(Path(remote_tmp_file).parent).replace("\\", "/"))
        sftp.put(str(local), remote_tmp_file)
        print(f"OK subido tmp {rel}")
    sftp.close()

    # Copiar al destino real + symlink + permisos
    copy_parts = []
    for rel in FILES:
        dest_dir = str(Path(f"{REMOTE_ROOT}/{rel}").parent).replace("\\", "/")
        copy_parts.append(f"mkdir -p {dest_dir}")
        copy_parts.append(f"cp -f {remote_tmp}/{rel} {REMOTE_ROOT}/{rel}")
    fix_cmd = (
        " && ".join(copy_parts)
        + f" && mkdir -p {REMOTE_ROOT}/frontend/web/public/uploads/biometria"
        + f" && cd {REMOTE_ROOT}/frontend/web/public"
        + " && if [ ! -e routers ]; then ln -s ../../../backend/routers routers; fi"
        + f" && chown -R www-data:www-data {REMOTE_ROOT}/backend/routers/porteria/v1/biometria"
        + f" {REMOTE_ROOT}/backend/services/porteria/biometria_service.php"
        + f" {REMOTE_ROOT}/backend/services/porteria/biometria_photo_service.php"
        + f" {REMOTE_ROOT}/backend/services/porteria/biometria_huella_service.php"
        + f" {REMOTE_ROOT}/backend/routers/porteria/prepare.php"
        + f" {REMOTE_ROOT}/backend/routers/porteria/_lib/Payload.php"
        + f" {REMOTE_ROOT}/backend/core/prepare.php 2>/dev/null || true"
        + f" && chmod -R a+rX {REMOTE_ROOT}/backend/routers/porteria/v1/biometria"
        + f" && rm -rf {remote_tmp}"
        + f" && test -f {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/identificar.php"
        + " && echo IDENTIFICAR_OK || echo IDENTIFICAR_MISSING"
        + f" && test -f {REMOTE_ROOT}/frontend/web/public/routers/porteria/v1/biometria/identificar.php"
        + " && echo VIA_PUBLIC_OK || echo VIA_PUBLIC_MISSING"
    )
    code2, out2 = sudo_bash(client, password, fix_cmd)
    print("--- estado remoto despues ---")
    print(out2)
    print(f"(exit={code2})")

    client.close()
    if "IDENTIFICAR_OK" not in out2 or "VIA_PUBLIC_OK" not in out2:
        print("FAIL: identificar.php no queda accesible vía public/routers")
        return 1
    print("OK deploy biometria routers")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
