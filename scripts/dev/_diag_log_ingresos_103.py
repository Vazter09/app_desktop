#!/usr/bin/env python3
"""Dump remote log columns + restore-critical check."""
from __future__ import annotations

import sys
import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]


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
    time.sleep(0.5)
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
            if idle > 1200:
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
    host = env.get("SERVER_HOST") or env.get("DB_HOST") or "10.5.213.103"
    print(f"connect {host}", flush=True)
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=45,
        allow_agent=False,
        look_for_keys=False,
    )
    # Write query to tmp via echo to avoid quoting hell.
    remote_tmp = f"/tmp/diag_log_{int(time.time())}.sql"
    sql = (
        "\\pset pager off\n"
        "SELECT column_name, data_type "
        "FROM information_schema.columns "
        "WHERE table_schema='public' AND table_name='tab_log_ingresos' "
        "ORDER BY ordinal_position;\n"
        "SELECT oid::regprocedure::text AS firma FROM pg_proc "
        "WHERE proname IN ("
        "'fun_insert_log_ingreso',"
        "'fun_registrar_ingreso_manual',"
        "'fun_update_log_salida',"
        "'fun_registrar_salida_manual',"
        "'fun_actualizar_captura_ingreso_abierto',"
        "'fun_insert_novedad_diaria'"
        ") ORDER BY 1;\n"
    )
    sftp = client.open_sftp()
    code, out = sudo_bash(
        client, env["SERVER_PASS"], f"mkdir -p /tmp && chmod 777 /tmp"
    )
    print(out, flush=True)
    with sftp.file(remote_tmp, "w") as fh:
        fh.write(sql)
    sftp.close()
    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        f"sudo -u postgres env PAGER=cat psql -P pager=off "
        f"-d db_smartcset2 -f {remote_tmp}",
    )
    print(out, flush=True)
    print(f"exit={code}", flush=True)
    client.close()
    return 0 if code == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
