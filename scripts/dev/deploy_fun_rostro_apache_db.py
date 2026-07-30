#!/usr/bin/env python3
"""Aplica funciones facial en la BD que usa Apache remoto (DB_HOST del .env)."""
from __future__ import annotations

import sys
import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
SQL_FILES = [
    "database/migrations/migrate_biometria_a_tab_personas.sql",
    "database/functions/porteria/fun_guardar_enrolamiento_facial.sql",
    "database/functions/porteria/fun_identificar_persona_por_rostro.sql",
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
            if idle > 900:
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
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )

    remote_tmp = f"/tmp/deploy_fun_rostro_dbhost_{int(time.time())}"
    code0, out0 = sudo_bash(
        client, env["SERVER_PASS"], f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}"
    )
    if code0 != 0:
        print(out0)
        return 1

    sftp = client.open_sftp()
    for rel in SQL_FILES:
        sftp.put(str(ROOT / rel), f"{remote_tmp}/{Path(rel).name}")
    with sftp.file(f"{remote_tmp}/pgpass.txt", "w") as fh:
        fh.write(env["DB_PASS"])
    sftp.close()

    # Lee DB_* del .env de Apache y aplica SQL ahí (puede ser 111 o localhost).
    remote_sh = f"{remote_tmp}/run.sh"
    script = f"""#!/bin/bash
set -euo pipefail
source /dev/null
ENVF={REMOTE_ROOT}/.env
DB_HOST=$(grep -E '^DB_HOST=' "$ENVF" | head -1 | cut -d= -f2- | tr -d '\\r' | tr -d '\"' | tr -d \"'\")
DB_NAME=$(grep -E '^DB_NAME=' "$ENVF" | head -1 | cut -d= -f2- | tr -d '\\r' | tr -d '\"' | tr -d \"'\")
DB_USER=$(grep -E '^DB_USER=' "$ENVF" | head -1 | cut -d= -f2- | tr -d '\\r' | tr -d '\"' | tr -d \"'\")
DB_PORT=$(grep -E '^DB_PORT=' "$ENVF" | head -1 | cut -d= -f2- | tr -d '\\r' | tr -d '\"' | tr -d \"'\" || true)
DB_PORT=${{DB_PORT:-5432}}
export PGPASSWORD=$(cat {remote_tmp}/pgpass.txt)
export PGSSLMODE=require
echo "TARGET ${{DB_USER}}@${{DB_HOST}}:${{DB_PORT}}/${{DB_NAME}}"
echo '=== FIRMAS ANTES ==='
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -P pager=off -c \\
  "SELECT oid::regprocedure::text FROM pg_proc WHERE proname IN ('fun_identificar_persona_por_rostro','fun_guardar_enrolamiento_facial') ORDER BY 1;" || true
for f in migrate_biometria_a_tab_personas.sql fun_guardar_enrolamiento_facial.sql fun_identificar_persona_por_rostro.sql; do
  echo "=== APPLY $f ==="
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -P pager=off -v ON_ERROR_STOP=1 -f "{remote_tmp}/$f"
done
echo '=== FIRMAS DESPUES ==='
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -P pager=off -c \\
  "SELECT oid::regprocedure::text FROM pg_proc WHERE proname IN ('fun_identificar_persona_por_rostro','fun_guardar_enrolamiento_facial') ORDER BY 1;"
VEC=$(python3 -c 'print("[" + ",".join(["0.01"]*128) + "]")')
echo '=== SMOKE ==='
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -P pager=off -v ON_ERROR_STOP=1 -c \\
  "SET search_path TO public; SELECT fun_identificar_persona_por_rostro('${{VEC}}'::vector, 0.35::numeric) AS id;"
rm -rf {remote_tmp}
echo OK_DEPLOY_ON_APACHE_DB
"""
    sftp = client.open_sftp()
    with sftp.file(remote_sh, "w") as fh:
        fh.write(script)
    sftp.close()

    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote_sh}")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_DEPLOY_ON_APACHE_DB" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
