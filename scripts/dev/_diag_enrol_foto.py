#!/usr/bin/env python3
"""Diagnostica enrolamiento facial + foto en 10.5.213.103."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE = "/var/www/html/smartcset"

RUN_SH = f"""#!/bin/bash
set +e
echo '=== uploads/biometria ==='
ls -lad {REMOTE}/frontend/web/public/uploads/biometria
ls -la {REMOTE}/frontend/web/public/uploads/biometria | head -15
echo '=== photo service ==='
grep -n 'UPLOAD_BASE\\|dirname\\|asegurarDirectorio\\|file_put' \\
  {REMOTE}/backend/services/porteria/biometria_photo_service.php | head -30
echo '=== enrolar.php ==='
grep -n 'guardarFoto\\|rutaFoto\\|nom_persona\\|id_persona\\|biometriaGuardar' \\
  {REMOTE}/backend/routers/porteria/v1/biometria/enrolar.php | head -30
echo '=== prepare ==='
grep -n 'fun_guardar_enrolamiento_facial\\|ruta_foto_facial' \\
  {REMOTE}/backend/core/prepare.php | head -20
echo '=== columnas ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c \\
  "SELECT column_name FROM information_schema.columns WHERE table_name='tab_personas' AND column_name IN ('val_patron_facial','ruta_foto_facial') ORDER BY 1;"
echo '=== firma ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c \\
  "SELECT oid::regprocedure::text FROM pg_proc WHERE proname='fun_guardar_enrolamiento_facial';"
echo '=== sample ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c \\
  "SELECT id_persona, LEFT(COALESCE(ruta_foto_facial,''),80) AS ruta, (val_patron_facial IS NOT NULL) AS tiene_v FROM tab_personas WHERE val_patron_facial IS NOT NULL OR COALESCE(ruta_foto_facial,'') <> '' ORDER BY fec_update DESC NULLS LAST LIMIT 8;"
echo '=== write test ==='
sudo -u www-data bash -lc 'mkdir -p {REMOTE}/frontend/web/public/uploads/biometria/_probe && echo ok > {REMOTE}/frontend/web/public/uploads/biometria/_probe/t.txt && cat {REMOTE}/frontend/web/public/uploads/biometria/_probe/t.txt && rm -rf {REMOTE}/frontend/web/public/uploads/biometria/_probe'
echo '=== apache errors ==='
tail -n 120 /var/log/apache2/error.log 2>/dev/null | grep -iE 'biometria|enrol|foto|permission|Fatal|Warning|InvalidArgument' | tail -30
echo DONE_DIAG
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


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> tuple[int, str]:
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
            if idle > 600:
                break
            time.sleep(0.05)
    code = channel.recv_exit_status() if channel.exit_status_ready() else 1
    text = "\n".join(
        ln
        for ln in out.decode("utf-8", errors="replace").splitlines()
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
    remote = f"/tmp/diag_enrol_foto_{int(time.time())}.sh"
    sudo_bash(client, env["SERVER_PASS"], "mkdir -p /tmp && chmod 777 /tmp")
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(RUN_SH.replace("\r\n", "\n"))
    sftp.close()
    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote}; rm -f {remote}")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "DONE_DIAG" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
