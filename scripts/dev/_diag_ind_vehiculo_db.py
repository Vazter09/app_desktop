#!/usr/bin/env python3
"""Diagnostica columnas ind_vehiculo en BD Apache (DB_HOST del .env remoto)."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]

RUN = r"""#!/bin/bash
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
export PGPASSWORD="$DB_PASS"
export PGSSLMODE=${DB_SSLMODE:-require}
echo "DB=$DB_HOST/$DB_NAME"

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -P pager=off <<'SQL'
\echo === tab_instructores columnas vehiculo/estado/contrato ===
SELECT column_name, data_type, column_default
  FROM information_schema.columns
 WHERE table_schema='public' AND table_name='tab_instructores'
   AND column_name IN ('ind_vehiculo','ind_estado','ind_tipo_contrato','id_instructor')
 ORDER BY 1;

\echo === tab_aprendices columnas relacionadas ===
SELECT column_name, data_type
  FROM information_schema.columns
 WHERE table_schema='public' AND table_name='tab_aprendices'
   AND column_name IN ('id_aprendiz','id_ficha','ind_etdo_formacion','ind_vehiculo')
 ORDER BY 1;

\echo === tab_log_ingresos columnas vehiculo ===
SELECT column_name, data_type, column_default
  FROM information_schema.columns
 WHERE table_schema='public' AND table_name='tab_log_ingresos'
   AND column_name IN ('ind_vehiculo','id_vehiculo','id_ingreso','id_visitante')
 ORDER BY 1;

\echo === smoke buscar persona aprendiz (misma firma prepare) ===
SELECT p.id_persona, p.id_tipo_persona, i.ind_estado AS ind_estado_instructor,
       i.ind_tipo_contrato, i.ind_vehiculo
  FROM tab_personas p
  LEFT JOIN tab_instructores i ON i.id_instructor = p.id_persona
 WHERE p.id_persona = 1005553190
 LIMIT 1;
SQL
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


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> str:
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
    return "\n".join(
        ln
        for ln in out_buf.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )


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
    remote = f"/tmp/diag_vehiculo_{int(time.time())}.sh"
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(RUN)
    sftp.close()
    print(sudo_bash(client, env["SERVER_PASS"], f"bash {remote}; rm -f {remote}"))
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
