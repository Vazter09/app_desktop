#!/usr/bin/env python3
"""Diag remoto + smoke API ingreso 1007692289."""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "app_desktop" / "app"
sys.path.insert(0, str(APP))

DOC = "1007692289"
RUN = r"""#!/bin/bash
set +e
echo '=== PERSONA ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT id_persona, nom_persona, ape_persona, id_tipo_persona, id_tipo_docum, fec_ultima_entrada, fec_ultima_salida FROM tab_personas WHERE id_persona = 1007692289;"
echo '=== INGRESOS PERSONA ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT id_ingreso, id_visitante, fec_ingreso, fec_salida, id_metodo_aut, usr_insert, id_entrada_centro FROM tab_log_ingresos WHERE id_visitante = 1007692289 ORDER BY fec_ingreso DESC LIMIT 15;"
echo '=== INGRESOS HOY ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT id_ingreso, id_visitante, fec_ingreso, id_metodo_aut, usr_insert FROM tab_log_ingresos WHERE fec_ingreso::date = CURRENT_DATE ORDER BY fec_ingreso DESC LIMIT 25;"
echo '=== NOVEDADES ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "\d tab_novedades_ingreso" 2>&1 | head -40
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT * FROM tab_novedades_ingreso WHERE id_persona = 1007692289 OR CAST(nom_persona AS TEXT) ILIKE '%1007692289%' ORDER BY 1 DESC LIMIT 5;" 2>&1
echo '=== FUN signature ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT oid::regprocedure::text FROM pg_proc WHERE proname LIKE 'fun_registrar_ingreso%' ORDER BY 1;"
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
            if idle > 800:
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
    remote = f"/tmp/diag_ingreso_{int(time.time())}.sh"
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(RUN)
    sftp.chmod(remote, 0o755)
    sftp.close()
    print(sudo_bash(client, env["SERVER_PASS"], f"bash {remote}"))
    client.close()

    # Smoke API with desktop client
    from smartcset_client import SmartcsetApiError, SmartcsetClient

    c = SmartcsetClient("https://10.5.213.103/smartcset", verify_tls=False)
    login = c.login("porteria", "Porteria2026!")
    print("LOGIN", json.dumps(login, ensure_ascii=False)[:200])
    consulta = c.ingreso_consultar(DOC, "CC")
    print("CONSULTAR", json.dumps(consulta, ensure_ascii=False)[:1000])
    cats = c.catalogos()
    entradas = cats.get("entradas") or []
    print("ENTRADAS", len(entradas), entradas[:3] if entradas else None)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
