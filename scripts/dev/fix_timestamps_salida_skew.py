#!/usr/bin/env python3
"""Completa correccion de timestamps sesgados (UTC) en ingresos abiertos."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
RUN = r"""#!/bin/bash
set -e
echo '=== check constraint ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
SELECT conname, pg_get_constraintdef(oid)
  FROM pg_constraint
 WHERE conrelid = 'tab_log_ingresos'::regclass
   AND contype = 'c';"

echo '=== .env TZ ==='
grep -E 'DB_TIMEZONE|APP_TIMEZONE' /var/www/html/smartcset/.env

echo '=== fix timestamps abiertos futuros ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -v ON_ERROR_STOP=1 <<'SQL'
BEGIN;

-- Ajuste de reloj: valores escritos con sesion UTC mientras APP lee Bogota.
UPDATE tab_log_ingresos
   SET fec_ingreso = fec_ingreso - interval '5 hours',
       fec_salida  = CASE
                       WHEN fec_salida = fec_ingreso THEN fec_ingreso - interval '5 hours'
                       ELSE fec_salida - interval '5 hours'
                     END,
       fec_insert  = CASE
                       WHEN fec_insert > (now() AT TIME ZONE 'America/Bogota')
                        AND fec_insert < (now() AT TIME ZONE 'America/Bogota') + interval '6 hours'
                       THEN fec_insert - interval '5 hours'
                       ELSE fec_insert
                     END,
       fec_update  = CASE
                       WHEN fec_update IS NOT NULL
                        AND fec_update > (now() AT TIME ZONE 'America/Bogota')
                        AND fec_update < (now() AT TIME ZONE 'America/Bogota') + interval '6 hours'
                       THEN fec_update - interval '5 hours'
                       ELSE fec_update
                     END
 WHERE id_ingreso IN (
     SELECT id_ingreso FROM tab_log_ingresos
      WHERE fec_salida = fec_ingreso
        AND fec_ingreso > (now() AT TIME ZONE 'America/Bogota')
        AND fec_ingreso < (now() AT TIME ZONE 'America/Bogota') + interval '6 hours'
 );

UPDATE tab_personas p
   SET fec_ultima_entrada = sub.fec_ingreso,
       fec_ultima_salida = GREATEST(sub.fec_ingreso, COALESCE(p.fec_ultima_salida, sub.fec_ingreso))
  FROM (
        SELECT DISTINCT ON (id_visitante) id_visitante, fec_ingreso
          FROM tab_log_ingresos
         WHERE fec_salida = fec_ingreso
         ORDER BY id_visitante, id_ingreso DESC
       ) sub
 WHERE p.id_persona = sub.id_visitante
   AND p.fec_ultima_entrada IS DISTINCT FROM sub.fec_ingreso
   AND sub.fec_ingreso > (now() AT TIME ZONE 'America/Bogota') - interval '1 day';

SELECT id_ingreso, id_visitante, fec_ingreso, fec_insert,
       ROUND(EXTRACT(EPOCH FROM ((now() AT TIME ZONE 'America/Bogota') - fec_ingreso))) AS seg,
       CASE WHEN EXTRACT(EPOCH FROM ((now() AT TIME ZONE 'America/Bogota') - fec_ingreso)) >= 300
            THEN 'PUEDE_SALIR' ELSE 'ESPERA_<5MIN' END AS estado
  FROM tab_log_ingresos
 WHERE fec_salida = fec_ingreso
 ORDER BY id_ingreso DESC
 LIMIT 8;

COMMIT;
SQL
echo OK_FIX_TS
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
    remote = f"/tmp/fix_ts_salida_{int(time.time())}.sh"
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(RUN.replace("\r\n", "\n"))
    sftp.close()
    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote}; rm -f {remote}")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_FIX_TS" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
