#!/usr/bin/env python3
"""Aplica funciones facial en la BD real que usa Apache (lee .env remoto)."""
from __future__ import annotations

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

DIAG_SQL = """SELECT oid::regprocedure::text AS firma
  FROM pg_proc
 WHERE proname IN (
       'fun_identificar_persona_por_rostro',
       'fun_guardar_enrolamiento_facial'
 )
 ORDER BY 1;
"""

SMOKE_SQL = """SET search_path TO public;
SELECT fun_identificar_persona_por_rostro(
  (SELECT ('[' || string_agg('0.01', ',') || ']')::vector
     FROM generate_series(1, 128)),
  0.35::numeric
) AS id;
"""

RUN_SH = r"""#!/bin/bash
set +e
ENVF=/var/www/html/smartcset/.env
strip_val() { printf '%s' "$1" | tr -d '\r' | tr -d '"' | tr -d "'"; }
DB_HOST=$(strip_val "$(grep -E '^DB_HOST=' "$ENVF" | head -1 | cut -d= -f2-)")
DB_NAME=$(strip_val "$(grep -E '^DB_NAME=' "$ENVF" | head -1 | cut -d= -f2-)")
DB_USER=$(strip_val "$(grep -E '^DB_USER=' "$ENVF" | head -1 | cut -d= -f2-)")
DB_PASS=$(strip_val "$(grep -E '^DB_PASS=' "$ENVF" | head -1 | cut -d= -f2-)")
DB_PORT=$(strip_val "$(grep -E '^DB_PORT=' "$ENVF" | head -1 | cut -d= -f2-)")
DB_SSLMODE=$(strip_val "$(grep -E '^DB_SSLMODE=' "$ENVF" | head -1 | cut -d= -f2-)")
DB_PORT=${DB_PORT:-5432}
DB_SSLMODE=${DB_SSLMODE:-require}
export PGPASSWORD="$DB_PASS"
export PGSSLMODE="$DB_SSLMODE"
echo "Apache DB_HOST=$DB_HOST DB_NAME=$DB_NAME SSL=$DB_SSLMODE USER=$DB_USER"

TMPDIR=__TMPDIR__

echo "--- connect test ---"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1 AS ok;" 2>&1
RC1=$?
echo RC_CONNECT=$RC1

if [ "$RC1" -ne 0 ]; then
  echo "--- retry sslmode=prefer ---"
  export PGSSLMODE=prefer
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1 AS ok;" 2>&1
  RC1=$?
  echo RC_CONNECT_PREFER=$RC1
fi

if [ "$RC1" -ne 0 ]; then
  echo FAIL_CONNECT_APACHE_DB
  exit 2
fi

echo "=== FIRMAS ANTES ==="
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -P pager=off -f "$TMPDIR/diag.sql" 2>&1

set -e
for f in migrate_biometria_a_tab_personas.sql fun_guardar_enrolamiento_facial.sql fun_identificar_persona_por_rostro.sql; do
  echo "=== APPLY $f ==="
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -P pager=off -v ON_ERROR_STOP=1 -f "$TMPDIR/$f"
done

echo "=== FIRMAS DESPUES ==="
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -P pager=off -f "$TMPDIR/diag.sql"

echo "=== SMOKE ==="
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -P pager=off -v ON_ERROR_STOP=1 -f "$TMPDIR/smoke.sql"

rm -rf "$TMPDIR"
echo OK_FIXED_APACHE_DB
"""


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

    remote_tmp = f"/tmp/deploy_apache_db_{int(time.time())}"
    sudo_bash(client, env["SERVER_PASS"], f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}")

    sftp = client.open_sftp()
    for rel in SQL_FILES:
        sftp.put(str(ROOT / rel), f"{remote_tmp}/{Path(rel).name}")

    with sftp.file(f"{remote_tmp}/diag.sql", "w") as fh:
        fh.write(DIAG_SQL)
    with sftp.file(f"{remote_tmp}/smoke.sql", "w") as fh:
        fh.write(SMOKE_SQL)
    with sftp.file(f"{remote_tmp}/run.sh", "w") as fh:
        fh.write(RUN_SH.replace("__TMPDIR__", remote_tmp))
    sftp.close()

    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote_tmp}/run.sh")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_FIXED_APACHE_DB" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
