#!/usr/bin/env python3
"""Verifica TZ y si la regla de 5 min de salida se evalua bien."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
RUN = r"""#!/bin/bash
set +e
echo '=== timezone sesion postgres ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SHOW timezone; SELECT now(), CURRENT_TIMESTAMP, clock_timestamp();"

echo '=== open ingresos vs now (segundos) ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
SELECT id_ingreso, id_visitante, fec_ingreso,
       now() AS ahora,
       ROUND(EXTRACT(EPOCH FROM (now() - fec_ingreso))) AS seg_desde_ingreso,
       CASE
         WHEN EXTRACT(EPOCH FROM (now() - fec_ingreso)) < 0 THEN 'FUTURO_TZ_SKEW'
         WHEN EXTRACT(EPOCH FROM (now() - fec_ingreso)) < 300 THEN 'BLOQUEA_SALIDA_<5MIN'
         ELSE 'PUEDE_SALIR'
       END AS regla_fun_update_log_salida
  FROM tab_log_ingresos
 WHERE fec_salida = fec_ingreso
 ORDER BY id_ingreso DESC
 LIMIT 10;"

echo '=== prueba seca update salida id reciente abierto ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
DO \$\$
DECLARE
  wid INTEGER;
  msg TEXT;
BEGIN
  SELECT id_ingreso INTO wid FROM tab_log_ingresos
   WHERE fec_salida = fec_ingreso ORDER BY id_ingreso DESC LIMIT 1;
  BEGIN
    PERFORM fun_update_log_salida(wid, 'VALIDACION_DRY_RUN_NO_COMMIT');
    RAISE NOTICE 'SALIDA_OK id=%', wid;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS msg = MESSAGE_TEXT;
    RAISE NOTICE 'SALIDA_FAIL id=% msg=%', wid, msg;
  END;
  RAISE EXCEPTION 'rollback_dry_run';
END \$\$;"

echo DONE_TZ
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
    remote = f"/tmp/valida_salida_tz_{int(time.time())}.sh"
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
