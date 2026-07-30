#!/usr/bin/env python3
"""Diagnostica biometría en BD 103 (peer): tablas, columnas, firmas funciones."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]

RUN = r"""#!/bin/bash
set -e
DB=db_smartcset2
echo '=== tablas biometria / personas ==='
sudo -u postgres psql -d "$DB" -P pager=off -c "SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename IN ('tab_enrolamiento_facial','tab_personas','tab_novedades_ingreso') ORDER BY 1;"
echo '=== columnas facial tab_personas ==='
sudo -u postgres psql -d "$DB" -P pager=off -c "SELECT column_name, data_type, udt_name FROM information_schema.columns WHERE table_name='tab_personas' AND column_name IN ('val_patron_facial','ruta_foto_facial','facial_embedding') ORDER BY 1;"
echo '=== firmas funciones facial ==='
sudo -u postgres psql -d "$DB" -P pager=off -c "SELECT oid::regprocedure::text FROM pg_proc WHERE proname IN ('fun_identificar_persona_por_rostro','fun_guardar_enrolamiento_facial') ORDER BY 1;"
echo '=== cuerpo identificar (grep tabla) ==='
sudo -u postgres psql -d "$DB" -P pager=off -t -c "SELECT prosrc FROM pg_proc WHERE proname='fun_identificar_persona_por_rostro' LIMIT 1;" | tr -s ' \n' ' ' | fold -s -w 120
echo
echo '=== cuerpo guardar (grep tabla) ==='
sudo -u postgres psql -d "$DB" -P pager=off -t -c "SELECT prosrc FROM pg_proc WHERE proname='fun_guardar_enrolamiento_facial' LIMIT 1;" | tr -s ' \n' ' ' | fold -s -w 120
echo
echo '=== extension vector ==='
sudo -u postgres psql -d "$DB" -P pager=off -c "SELECT extname, extversion FROM pg_extension WHERE extname='vector';"
echo OK_DIAG
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
            if idle > 700:
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
    remote = f"/tmp/diag_bio_{int(time.time())}.sh"
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(RUN)
    sftp.close()
    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote}; rm -f {remote}")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_DIAG" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
