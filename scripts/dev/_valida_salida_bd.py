#!/usr/bin/env python3
"""Valida en BD 103 si salida cumple reglas de script_control_ingreso.sql."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
RUN = r"""#!/bin/bash
set +e
echo '=== objetos salida / control ingreso ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
SELECT n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) AS args,
       CASE p.prokind WHEN 'f' THEN 'function' WHEN 'p' THEN 'procedure' ELSE p.prokind::text END AS kind
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
 WHERE p.proname IN (
       'sp_registrar_salida','sp_registrar_ingreso','fn_diferencia_minutos',
       'fn_trg_validar_salida_directa','fn_trg_validar_ingreso_directo',
       'fun_registrar_salida_manual','fun_update_log_salida',
       'fun_update_persona_tras_salida','fun_buscar_ingreso_abierto'
 )
 ORDER BY 2,3;"

echo '=== triggers tab_log_ingresos ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
SELECT tgname, pg_get_triggerdef(oid) AS def
  FROM pg_trigger
 WHERE tgrelid = 'tab_log_ingresos'::regclass
   AND NOT tgisinternal
 ORDER BY 1;"

echo '=== cuerpo fun_update_log_salida (extracto) ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
SELECT substring(prosrc from 1 for 1800)
  FROM pg_proc WHERE proname='fun_update_log_salida';"

echo '=== cuerpo fun_registrar_salida_manual (extracto) ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
SELECT substring(prosrc from 1 for 1600)
  FROM pg_proc WHERE proname='fun_registrar_salida_manual';"

echo '=== indices control ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
SELECT indexname FROM pg_indexes
 WHERE tablename='tab_log_ingresos'
   AND indexname IN ('idx_log_activos_persona','idx_log_persona_fechas','idx_log_ultima_salida')
 ORDER BY 1;"

echo '=== muestra ingresos abiertos / salidas recientes ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
SELECT id_ingreso, id_visitante,
       fec_ingreso, fec_salida,
       (fec_salida = fec_ingreso) AS abierto,
       ROUND(EXTRACT(EPOCH FROM (COALESCE(NULLIF(fec_salida, fec_ingreso), NOW()) - fec_ingreso))/60.0, 2) AS min_en_centro
  FROM tab_log_ingresos
 ORDER BY id_ingreso DESC
 LIMIT 12;"

echo DONE_VALIDA_SALIDA
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
    remote = f"/tmp/valida_salida_{int(time.time())}.sh"
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
