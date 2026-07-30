#!/usr/bin/env python3
"""Despliega fix enrolamiento foto → id_persona y limpia rutas basura."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
FILES = [
    ("backend/services/porteria/biometria_photo_service.php", "biometria_photo_service.php"),
    ("backend/routers/porteria/v1/biometria/enrolar.php", "enrolar.php"),
    ("backend/routers/porteria/v1/biometria/identificar.php", "identificar.php"),
    ("backend/routers/porteria/v1/biometria/huella_identificar.php", "huella_identificar.php"),
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
            if idle > 600:
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

    stamp = int(time.time())
    remote_tmp = f"/tmp/deploy_enrol_foto_{stamp}"
    remote_sh = f"/tmp/deploy_enrol_foto_{stamp}.sh"
    sudo_bash(client, env["SERVER_PASS"], f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp} /tmp")

    sftp = client.open_sftp()
    for rel, name in FILES:
        sftp.put(str(ROOT / rel), f"{remote_tmp}/{name}")
        print(f"OK tmp {rel}")

    script = f"""#!/bin/bash
set -e
cp -f {remote_tmp}/biometria_photo_service.php {REMOTE_ROOT}/backend/services/porteria/biometria_photo_service.php
cp -f {remote_tmp}/enrolar.php {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/enrolar.php
cp -f {remote_tmp}/identificar.php {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/identificar.php
cp -f {remote_tmp}/huella_identificar.php {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/huella_identificar.php
chown www-data:www-data \\
  {REMOTE_ROOT}/backend/services/porteria/biometria_photo_service.php \\
  {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/enrolar.php \\
  {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/identificar.php \\
  {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/huella_identificar.php
chmod a+r \\
  {REMOTE_ROOT}/backend/services/porteria/biometria_photo_service.php \\
  {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/enrolar.php \\
  {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/identificar.php \\
  {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/huella_identificar.php
sudo -u postgres psql -d db_smartcset2 -P pager=off -c \\
  "UPDATE tab_personas SET ruta_foto_facial = NULL WHERE ruta_foto_facial IS NOT NULL AND ruta_foto_facial NOT LIKE 'uploads/biometria/%';"
mkdir -p {REMOTE_ROOT}/frontend/web/public/uploads/biometria
chown -R www-data:www-data {REMOTE_ROOT}/frontend/web/public/uploads
chmod 775 {REMOTE_ROOT}/frontend/web/public/uploads {REMOTE_ROOT}/frontend/web/public/uploads/biometria
grep -n 'foto del rostro es obligatoria\\|esRutaFotoValida\\|normalizarBase64' \\
  {REMOTE_ROOT}/backend/routers/porteria/v1/biometria/enrolar.php \\
  {REMOTE_ROOT}/backend/services/porteria/biometria_photo_service.php | head -20
rm -rf {remote_tmp}
echo OK_DEPLOY_ENROL_FOTO
"""
    with sftp.file(remote_sh, "w") as fh:
        fh.write(script.replace("\r\n", "\n"))
    sftp.close()

    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote_sh}; rm -f {remote_sh}")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_DEPLOY_ENROL_FOTO" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
