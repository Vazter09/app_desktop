#!/usr/bin/env python3
"""Diagnostico rapido: log Apache + firmas prepare en .111."""
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
    host = env.get("SERVER_HOST", "10.5.213.111")
    user = env.get("SERVER_USER", "")
    password = env.get("SERVER_PASS", "")
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
    cmds = [
        "grep -n prepare /var/www/html/smartcset/backend/routers/auth/v1/login.php",
        "ls /var/log/apache2",
        "ls /var/www/html/smartcset/backend/core/prepare_login.php /var/www/html/smartcset/backend/core/PrepareAuthSql.php /var/www/html/smartcset/backend/core/PmtrosGralesDefaults.php",
        "php -l /var/www/html/smartcset/backend/core/prepare_login.php",
        "php -l /var/www/html/smartcset/backend/core/prepare.php",
        "tail -n 20 /var/log/apache2/other_vhosts_access.log",
    ]
    for cmd in cmds:
        print(">>>", cmd)
        print(sudo_bash(client, password, cmd))
        print()
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
