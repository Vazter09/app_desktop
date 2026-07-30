#!/usr/bin/env python3
"""Diag corto: fotos en disco, rutas basura, post_max_size."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE = "/var/www/html/smartcset"
RUN = f"""#!/bin/bash
set +e
echo '=== disco persona ejemplo ==='
ls -la {REMOTE}/frontend/web/public/uploads/biometria/1092342075/ 2>&1
echo '=== rutas invalidas ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT id_persona, ruta_foto_facial FROM tab_personas WHERE ruta_foto_facial IS NOT NULL AND ruta_foto_facial NOT LIKE 'uploads/biometria/%' LIMIT 20;"
echo '=== sin foto con vector ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT COUNT(*) FROM tab_personas WHERE val_patron_facial IS NOT NULL AND (ruta_foto_facial IS NULL OR btrim(ruta_foto_facial)='');"
echo '=== php limits ==='
php -i 2>/dev/null | grep -E 'post_max_size|upload_max_filesize|memory_limit' | head -10
echo '=== leer foto php ==='
php <<'PHP'
<?php
require '{REMOTE}/backend/services/porteria/biometria_photo_service.php';
$r = BiometriaPhotoService::leerFoto('uploads/biometria/1092342075/1092342075_josegregorio.jpg');
echo ($r === null) ? "LEER_NULL\\n" : ("LEER_OK len=".strlen($r)."\\n");
PHP
echo '=== apache recent ==='
tail -n 60 /var/log/apache2/error.log
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
            if idle > 600:
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
    remote = f"/tmp/diag_enrol_foto2_{int(time.time())}.sh"
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(RUN.replace("\r\n", "\n"))
    sftp.close()
    print(sudo_bash(client, env["SERVER_PASS"], f"bash {remote}; rm -f {remote}"))
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
