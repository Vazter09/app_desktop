#!/usr/bin/env python3
"""Despliega BiometriaPhotoService y corrige permisos uploads/biometria en remoto.

Lee SERVER_USER / SERVER_PASS / SERVER_HOST (opcional) del .env.
Uso: python scripts/dev/deploy_fix_biometria_uploads.py
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
BASE = f"{REMOTE_ROOT}/frontend/web/public/uploads/biometria"
PHOTO_SERVICE = "backend/services/porteria/biometria_photo_service.php"
PERMS_SCRIPT = "scripts/infra/fix_permisos_uploads_biometria.sh"


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    env_path = ROOT / ".env"
    for raw in env_path.read_text(encoding="utf-8").splitlines():
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
    while True:
        if channel.recv_ready():
            out_buf += channel.recv(4096)
        if channel.recv_stderr_ready():
            out_buf += channel.recv_stderr(4096)
        if channel.exit_status_ready():
            while channel.recv_ready():
                out_buf += channel.recv(4096)
            while channel.recv_stderr_ready():
                out_buf += channel.recv_stderr(4096)
            break
        time.sleep(0.05)
    code = channel.recv_exit_status()
    text = out_buf.decode("utf-8", errors="replace")
    filtered_lines = []
    for line in text.splitlines():
        low = line.lower()
        if "password" in low or "[sudo]" in low:
            continue
        filtered_lines.append(line)
    return code, "\n".join(filtered_lines)


def main() -> int:
    env = load_env()
    host = env.get("SERVER_HOST", DEFAULT_HOST)
    user = env.get("SERVER_USER", "")
    password = env.get("SERVER_PASS", "")
    if not user or not password:
        print("FAIL: defina SERVER_USER y SERVER_PASS en .env")
        return 1

    local_photo = ROOT / PHOTO_SERVICE
    local_perms = ROOT / PERMS_SCRIPT
    if not local_photo.is_file() or not local_perms.is_file():
        print("FAIL: faltan archivos locales a desplegar")
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

    sftp = client.open_sftp()
    remote_photo = f"{REMOTE_ROOT}/{PHOTO_SERVICE}"
    remote_perms = f"{REMOTE_ROOT}/{PERMS_SCRIPT}"
    ensure_remote_dir(sftp, str(Path(remote_photo).parent).replace("\\", "/"))
    ensure_remote_dir(sftp, str(Path(remote_perms).parent).replace("\\", "/"))
    sftp.put(str(local_photo), remote_photo)
    sftp.put(str(local_perms), remote_perms)
    sftp.chmod(remote_perms, 0o755)
    sftp.close()
    print(f"OK subido {PHOTO_SERVICE}")
    print(f"OK subido {PERMS_SCRIPT}")

    print("Aplicando permisos www-data en uploads/biometria...")
    code, out = sudo_bash(
        client,
        password,
        (
            f"bash '{remote_perms}' && "
            f"chown -R www-data:www-data '{BASE}' && "
            f"find '{BASE}' -type d -exec chmod 775 {{}} \\; && "
            f"find '{BASE}' -type f -exec chmod 664 {{}} \\; && "
            f"sudo -u www-data test -w '{BASE}' && echo OK_WRITABLE && "
            f"sudo -u www-data touch '{BASE}/.write_test' && "
            f"sudo -u www-data rm -f '{BASE}/.write_test' && echo OK_TOUCH"
        ),
    )
    if out.strip():
        print(out)
    if code != 0 or "OK_WRITABLE" not in out:
        print(f"FAIL: permisos exit={code}", file=sys.stderr)
        client.close()
        return 1

    client.close()
    print("Despliegue + permisos biometria OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
