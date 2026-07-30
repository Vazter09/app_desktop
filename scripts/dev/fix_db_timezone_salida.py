#!/usr/bin/env python3
"""Corrige DB_TIMEZONE=America/Bogota en .env remoto (rompe salida 5 min)."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ENV = "/var/www/html/smartcset/.env"
RUN = f"""#!/bin/bash
set -e
ENV={REMOTE_ENV}
cp -a "$ENV" "$ENV.bak_tz_$(date +%Y%m%d%H%M%S)"
# Forzar DB_TIMEZONE a America/Bogota (alineado con APP y timestamp without tz)
if grep -q '^DB_TIMEZONE=' "$ENV"; then
  sed -i 's/^DB_TIMEZONE=.*/DB_TIMEZONE=America\\/Bogota/' "$ENV"
else
  echo 'DB_TIMEZONE=America/Bogota' >> "$ENV"
fi
if grep -q '^APP_TIMEZONE=' "$ENV"; then
  sed -i 's/^APP_TIMEZONE=.*/APP_TIMEZONE=America\\/Bogota/' "$ENV"
else
  echo 'APP_TIMEZONE=America/Bogota' >> "$ENV"
fi
grep -E 'DB_TIMEZONE|APP_TIMEZONE' "$ENV"
chown www-data:www-data "$ENV"
# Corregir ingresos abiertos recientes escritos en UTC wall-clock (~ +5h vs Bogota)
sudo -u postgres psql -d db_smartcset2 -P pager=off -v ON_ERROR_STOP=1 <<'SQL'
UPDATE tab_log_ingresos
   SET fec_ingreso = fec_ingreso - interval '5 hours',
       fec_salida  = fec_salida  - interval '5 hours'
 WHERE fec_salida = fec_ingreso
   AND fec_ingreso > (now() AT TIME ZONE 'America/Bogota')
   AND fec_ingreso < (now() AT TIME ZONE 'America/Bogota') + interval '6 hours';

UPDATE tab_personas p
   SET fec_ultima_entrada = l.fec_ingreso
  FROM tab_log_ingresos l
 WHERE l.id_visitante = p.id_persona
   AND l.fec_salida = l.fec_ingreso
   AND l.id_ingreso = (
         SELECT MAX(l2.id_ingreso) FROM tab_log_ingresos l2
          WHERE l2.id_visitante = p.id_persona AND l2.fec_salida = l2.fec_ingreso
       );

SELECT id_ingreso, id_visitante, fec_ingreso,
       ROUND(EXTRACT(EPOCH FROM ((now() AT TIME ZONE 'America/Bogota') - fec_ingreso))) AS seg,
       CASE WHEN EXTRACT(EPOCH FROM ((now() AT TIME ZONE 'America/Bogota') - fec_ingreso)) >= 300
            THEN 'PUEDE_SALIR' ELSE 'ESPERA' END AS estado
  FROM tab_log_ingresos
 WHERE fec_salida = fec_ingreso
 ORDER BY id_ingreso DESC
 LIMIT 8;
SQL
echo OK_FIX_TZ_SALIDA
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
    remote = f"/tmp/fix_tz_salida_{int(time.time())}.sh"
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(RUN.replace("\r\n", "\n"))
    sftp.close()
    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote}; rm -f {remote}")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_FIX_TZ_SALIDA" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
