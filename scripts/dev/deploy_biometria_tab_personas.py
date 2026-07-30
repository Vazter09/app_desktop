#!/usr/bin/env python3
"""Despliega biometría facial alineada a tab_personas.val_patron_facial (sin tab_enrolamiento_facial)."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
FILES = [
    "backend/routers/porteria/v1/biometria/identificar.php",
    "backend/routers/porteria/v1/biometria/enrolar.php",
    "backend/services/porteria/biometria_service.php",
    "backend/services/porteria/biometria_photo_service.php",
    "backend/core/prepare.php",
    "database/functions/porteria/fun_identificar_persona_por_rostro.sql",
    "database/functions/porteria/fun_guardar_enrolamiento_facial.sql",
    "database/migrations/migrate_biometria_a_tab_personas.sql",
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
            if idle > 800:
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
    host = env.get("SERVER_HOST") or env.get("DB_HOST", "10.5.213.103")
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

    remote_tmp = f"/tmp/deploy_bio_personas_{int(time.time())}"
    sudo_bash(client, env["SERVER_PASS"], f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}")
    sftp = client.open_sftp()
    for rel in FILES:
        sftp.put(str(ROOT / rel), f"{remote_tmp}/{Path(rel).name}")
        print("OK tmp", rel)
    sftp.close()

    run = f"""#!/bin/bash
set -e
TMP={remote_tmp}
RR={REMOTE_ROOT}

# PHP
cp -f "$TMP/identificar.php" "$RR/backend/routers/porteria/v1/biometria/identificar.php"
cp -f "$TMP/enrolar.php" "$RR/backend/routers/porteria/v1/biometria/enrolar.php"
cp -f "$TMP/biometria_service.php" "$RR/backend/services/porteria/biometria_service.php"
cp -f "$TMP/biometria_photo_service.php" "$RR/backend/services/porteria/biometria_photo_service.php"
cp -f "$TMP/prepare.php" "$RR/backend/core/prepare.php"
chown www-data:www-data \\
  "$RR/backend/routers/porteria/v1/biometria/identificar.php" \\
  "$RR/backend/routers/porteria/v1/biometria/enrolar.php" \\
  "$RR/backend/services/porteria/biometria_service.php" \\
  "$RR/backend/services/porteria/biometria_photo_service.php" \\
  "$RR/backend/core/prepare.php"

echo '=== verificar SQL viejo en identificar.php ==='
if grep -n 'tab_enrolamiento_facial' "$RR/backend/routers/porteria/v1/biometria/identificar.php"; then
  echo FAIL_STILL_OLD_IDENTIFICAR
  exit 1
fi
grep -n 'ruta_foto_facial' "$RR/backend/routers/porteria/v1/biometria/identificar.php" || true
echo PHP_OK_NO_ENROLAMIENTO_TABLE

# SQL peer
echo '=== SQL migrate + funcs ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -v ON_ERROR_STOP=1 -f "$TMP/migrate_biometria_a_tab_personas.sql"
sudo -u postgres psql -d db_smartcset2 -P pager=off -v ON_ERROR_STOP=1 -f "$TMP/fun_guardar_enrolamiento_facial.sql"
sudo -u postgres psql -d db_smartcset2 -P pager=off -v ON_ERROR_STOP=1 -f "$TMP/fun_identificar_persona_por_rostro.sql"

echo '=== firmas ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT oid::regprocedure::text FROM pg_proc WHERE proname IN ('fun_identificar_persona_por_rostro','fun_guardar_enrolamiento_facial') ORDER BY 1;"
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT COUNT(*) AS con_patron FROM tab_personas WHERE val_patron_facial IS NOT NULL;"

rm -rf "$TMP"
echo OK_BIO_PERSONAS_DEPLOY
"""
    run_path = f"{remote_tmp}/run.sh"
    sftp = client.open_sftp()
    with sftp.file(run_path, "w") as fh:
        fh.write(run.replace("\r\n", "\n"))
    sftp.close()

    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {run_path}")
    (ROOT / "scripts/dev/_last_deploy_bio_personas.txt").write_text(out, encoding="utf-8")
    print(out[:6000])
    print("exit", code)
    client.close()
    return 0 if "OK_BIO_PERSONAS_DEPLOY" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
