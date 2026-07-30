#!/usr/bin/env python3
"""Aplica add_ind_vehiculo_tab_instructores.sql en la BD de Apache."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
SQL_REL = "database/migrations/add_ind_vehiculo_tab_instructores.sql"

RUN = r"""#!/bin/bash
set -e
ENVF=/var/www/html/smartcset/.env
strip_val() { printf '%s' "$1" | tr -d '\r' | tr -d '"' | tr -d "'"; }
DB_HOST=$(strip_val "$(grep -E '^DB_HOST=' "$ENVF" | head -1 | cut -d= -f2-)")
DB_NAME=$(strip_val "$(grep -E '^DB_NAME=' "$ENVF" | head -1 | cut -d= -f2-)")
DB_USER=$(strip_val "$(grep -E '^DB_USER=' "$ENVF" | head -1 | cut -d= -f2-)")
DB_PASS=$(strip_val "$(grep -E '^DB_PASS=' "$ENVF" | head -1 | cut -d= -f2-)")
DB_PORT=$(strip_val "$(grep -E '^DB_PORT=' "$ENVF" | head -1 | cut -d= -f2-)")
DB_SSLMODE=$(strip_val "$(grep -E '^DB_SSLMODE=' "$ENVF" | head -1 | cut -d= -f2-)")
DB_PORT=${DB_PORT:-5432}
export PGPASSWORD="$DB_PASS"
export PGSSLMODE=${DB_SSLMODE:-require}
TMP=__TMP__
echo "DB=$DB_HOST/$DB_NAME"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -P pager=off -v ON_ERROR_STOP=1 -f "$TMP/add_ind_vehiculo_tab_instructores.sql"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -P pager=off -c "SELECT column_name, data_type, column_default FROM information_schema.columns WHERE table_name='tab_instructores' AND column_name='ind_vehiculo';"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -P pager=off -v ON_ERROR_STOP=1 -c "SELECT p.id_persona, p.id_tipo_persona, i.ind_vehiculo FROM tab_personas p LEFT JOIN tab_instructores i ON i.id_instructor = p.id_persona WHERE p.id_persona = 1005553190 LIMIT 1;"
rm -rf "$TMP"
echo OK_IND_VEHICULO
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
    remote_tmp = f"/tmp/mig_vehiculo_{int(time.time())}"
    sudo_bash(client, env["SERVER_PASS"], f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}")
    sftp = client.open_sftp()
    sftp.put(str(ROOT / SQL_REL), f"{remote_tmp}/add_ind_vehiculo_tab_instructores.sql")
    with sftp.file(f"{remote_tmp}/run.sh", "w") as fh:
        fh.write(RUN.replace("__TMP__", remote_tmp))
    sftp.close()
    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote_tmp}/run.sh")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_IND_VEHICULO" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
