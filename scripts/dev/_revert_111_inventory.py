#!/usr/bin/env python3
"""Inventario de backups y archivos subidos hoy en .111 (solo lectura)."""
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
            if idle > 400:
                break
            time.sleep(0.05)
    text = out_buf.decode("utf-8", errors="replace")
    return "\n".join(
        ln
        for ln in text.splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )


def main() -> int:
    env = load_env()
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.111"),
        username=env.get("SERVER_USER", ""),
        password=env.get("SERVER_PASS", ""),
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    pwd = env.get("SERVER_PASS", "")
    cmds = [
        "find /var/www/html/smartcset -name '*bak_puerta*' -o -name '*.bak_puerta_20260813' 2>/dev/null",
        "ls -la /var/www/html/smartcset/src/backend/includes /var/www/html/smartcset/src/backend/includes/lib 2>&1 | cat",
        "ls -la /var/www/html/smartcset/src/backend/api /var/www/html/smartcset/src/backend/middleware 2>&1 | cat",
        "ls -la /var/www/html/smartcset/src/backend/services/porteria /var/www/html/smartcset/src/backend/_lib_porteria 2>&1 | cat",
        "ls -la /var/www/html/smartcset/src/.env /var/www/html/smartcset/backend/core 2>&1 | cat",
        "ls -la --time-style=long-iso /var/www/html/smartcset/src/frontend/js/modules/porteria/salidas.js",
    ]
    for cmd in cmds:
        print(">>>", cmd)
        print(sudo_bash(client, pwd, cmd))
        print()
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
