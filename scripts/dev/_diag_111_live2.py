#!/usr/bin/env python3
"""Lee fragmentos live de prepare/Payload/salida y el vhost."""
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
    cmds = [
        "sed -n '250,265p' /var/www/html/smartcset/src/backend/includes/prepare.php",
        "sed -n '45,70p' /var/www/html/smartcset/src/backend/_lib_porteria/Payload.php",
        "ls /var/www/html/smartcset/src/backend/services",
        "grep -n 'function salidaRegistrarManual\\|sel_entrada' /var/www/html/smartcset/src/backend/services/porteria/salida_service.php 2>/dev/null | head",
        "ls /var/www/html/smartcset/src/backend/porteria",
        "grep -n 'prepare.php\\|prepare_login' /var/www/html/smartcset/src/backend/api/auth_login.php",
        "grep -n 'stmt_login\\|PrepareAuthSql' /var/www/html/smartcset/src/backend/includes/prepare.php | head",
        "grep -n 'Alias\\|DocumentRoot\\|Rewrite' /etc/apache2/sites-enabled/smartcset.conf | head -40",
        "ls -l --time-style=long-iso /var/www/html/smartcset/src/backend/api/auth_login.php /var/www/html/smartcset/src/backend/includes/prepare.php /var/www/html/smartcset/src/backend/_lib_porteria/Payload.php",
        "find /var/www/html/smartcset/src/backend -name 'salida_service.php' -o -name 'registrar.php' | head",
    ]
    pwd = env.get("SERVER_PASS", "")
    for cmd in cmds:
        print(">>>", cmd)
        out = sudo_bash(client, pwd, cmd)
        print(out.encode("utf-8", "replace").decode("ascii", "replace"))
        print()
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
