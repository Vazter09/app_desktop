#!/usr/bin/env python3
"""Diagnóstico rápido: ¿existe tab_log_ingresos en el servidor?"""
from __future__ import annotations

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
    time.sleep(0.3)
    if channel.send_ready():
        channel.send(password + "\n")
    out_buf = b""
    while True:
        if channel.recv_ready():
            out_buf += channel.recv(4096)
        if channel.recv_stderr_ready():
            out_buf += channel.recv_stderr(4096)
        if channel.exit_status_ready():
            while channel.recv_ready():
                out_buf += channel.recv(4096)
            while channel.recv_stderr_ready():
                out_buf += channel.recv_stderr(4096)
            break
        time.sleep(0.05)
    code = channel.recv_exit_status()
    text = out_buf.decode("utf-8", errors="replace")
    lines = []
    for line in text.splitlines():
        low = line.lower()
        if "password" in low or "[sudo]" in low:
            continue
        lines.append(line)
    return code, "\n".join(lines)


def main() -> int:
    env = load_env()
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=20,
        allow_agent=False,
        look_for_keys=False,
    )
    sql = (
        "SELECT current_database(), current_user, current_setting('search_path'); "
        "SELECT to_regclass('public.tab_log_ingresos') AS tbl; "
        "SELECT column_name FROM information_schema.columns "
        "WHERE table_schema='public' AND table_name='tab_log_ingresos' "
        "AND column_name IN ('val_datos_origen','facial_embedding','val_observaciones') "
        "ORDER BY 1; "
        "SELECT oid::regprocedure::text FROM pg_proc WHERE proname='fun_insert_log_ingreso' ORDER BY 1;"
    )
    cmd = f"sudo -u postgres psql -d db_smartcset2 -v ON_ERROR_STOP=1 -c {sql!r}"
    code, out = sudo_bash(client, env["SERVER_PASS"], cmd)
    print(out)
    print("exit", code)
    client.close()
    return code


if __name__ == "__main__":
    raise SystemExit(main())
