#!/usr/bin/env python3
"""Trae ingreso_service + firma SQL de equipo en .103."""
from __future__ import annotations

import os
import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "scripts" / "dev" / "_tmp_live103"
REMOTE = "/var/www/html/smartcset"


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
    host = os.environ.get("SERVER_HOST") or "10.5.213.103"
    user = os.environ.get("SERVER_USER") or "adsocset"
    password = os.environ.get("SERVER_PASS") or env.get("SERVER_PASS", "")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=user,
        password=password,
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    sftp = client.open_sftp()
    OUT.mkdir(parents=True, exist_ok=True)
    for rel, name in (
        ("src/services/porteria/ingreso_service.php", "ingreso_service.php"),
        ("src/core/prepare.php", "prepare_core.php"),
    ):
        sftp.get(f"{REMOTE}/{rel}", str(OUT / name))
        text = (OUT / name).read_text(encoding="utf-8", errors="replace")
        print(f"=== {rel} ===")
        for i, line in enumerate(text.splitlines(), 1):
            low = line.lower()
            if any(k in low for k in ("id_equipo", "hid_id_equipo", "fun_registrar", "equipo")):
                print(f"  {i}:{line[:180]}")
    sftp.close()

    inner = (
        "sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
        "\"SELECT oid::regprocedure::text FROM pg_proc WHERE proname IN "
        "('fun_registrar_ingreso_manual','fun_insert_log_ingreso',"
        "'fun_upsert_equipo_persona') ORDER BY 1;\""
    )
    code, out = sudo_bash(client, password, inner)
    print("=== SQL FIRMAS ===")
    print(out)
    print("exit", code)
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
