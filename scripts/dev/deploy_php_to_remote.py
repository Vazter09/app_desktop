#!/usr/bin/env python3
"""Despliega backend PHP (+ public routers) a 10.5.213.103 vía SSH/SFTP.

Lee SERVER_USER / SERVER_PASS / host opcional del .env.
Uso: python scripts/dev/deploy_php_to_remote.py
"""
from __future__ import annotations

import os
import stat
import sys
from pathlib import Path

try:
    import paramiko
except ImportError:
    print("FAIL: falta paramiko. Ejecute: python -m pip install paramiko")
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
REMOTE_HOST = "10.5.213.103"

# Rutas relativas a sincronizar (PHP de biometría + dependencias del flujo).
SYNC_PATHS = [
    "backend/core",
    "backend/middleware",
    "backend/routers/porteria",
    "backend/routers/auth",
    "backend/services/porteria",
    "frontend/web/public/router.php",
    "frontend/web/public/index.php",
    "frontend/web/public/.htaccess",
]


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    env_path = ROOT / ".env"
    for raw in env_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        values[key.strip()] = val.strip()
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


def upload_file(sftp: paramiko.SFTPClient, local: Path, remote: str) -> None:
    ensure_remote_dir(sftp, str(Path(remote).parent).replace("\\", "/"))
    sftp.put(str(local), remote)


def upload_tree(sftp: paramiko.SFTPClient, local_root: Path, remote_root: str) -> int:
    count = 0
    if local_root.is_file():
        upload_file(sftp, local_root, remote_root)
        return 1
    for dirpath, _dirnames, filenames in os.walk(local_root):
        rel = os.path.relpath(dirpath, local_root)
        remote_dir = remote_root if rel == "." else f"{remote_root}/{rel.replace(os.sep, '/')}"
        ensure_remote_dir(sftp, remote_dir)
        for name in filenames:
            if name.endswith((".pyc", ".md")):
                continue
            local_file = Path(dirpath) / name
            remote_file = f"{remote_dir}/{name}"
            upload_file(sftp, local_file, remote_file)
            count += 1
            print(f"  OK {remote_file}")
    return count


def main() -> int:
    env = load_env()
    user = os.environ.get("SERVER_USER") or env.get("SERVER_USER", "adsocset")
    password = os.environ.get("SERVER_PASS") or env.get("SERVER_PASS", "")
    host = os.environ.get("SERVER_HOST") or env.get("SERVER_HOST", REMOTE_HOST)
    if not password:
        print("FAIL: SERVER_PASS vacío en .env")
        return 1

    print(f"Conectando {user}@{host} ...")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=user,
        password=password,
        timeout=20,
        allow_agent=False,
        look_for_keys=False,
    )

    # Comprobar destino
    stdin, stdout, stderr = client.exec_command(
        f"test -d {REMOTE_ROOT} && echo EXISTS || echo MISSING"
    )
    check = stdout.read().decode().strip()
    print(f"Remote root: {check} ({REMOTE_ROOT})")
    if check != "EXISTS":
        print("FAIL: no existe el directorio remoto esperado")
        client.close()
        return 1

    sftp = client.open_sftp()
    total = 0
    for rel in SYNC_PATHS:
        local = ROOT / rel
        remote = f"{REMOTE_ROOT}/{rel.replace(chr(92), '/')}"
        if not local.exists():
            print(f"SKIP (no local): {rel}")
            continue
        print(f"==> {rel}")
        total += upload_tree(sftp, local, remote)

    # Symlink routers en public si falta
    cmd = (
        f"cd {REMOTE_ROOT}/frontend/web/public && "
        "if [ ! -e routers ]; then ln -sfn ../../../backend/routers routers && echo LINK_OK; "
        "else echo LINK_EXISTS; fi && "
        f"ls -la {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/ 2>&1 | head -20"
    )
    stdin, stdout, stderr = client.exec_command(cmd)
    print(stdout.read().decode())
    err = stderr.read().decode().strip()
    if err:
        print("stderr:", err)

    sftp.close()
    client.close()
    print(f"Despliegue listo: {total} archivos.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
