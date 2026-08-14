#!/usr/bin/env python3
"""Verifica parche TZ en prepare/Db/helpers live .111."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
SRC = "/var/www/html/smartcset/src"


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
            if idle > 500:
                break
            time.sleep(0.05)
    return "\n".join(
        ln
        for ln in out.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )


def main() -> int:
    env = load_env()
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST") or "10.5.213.111",
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    sftp = client.open_sftp()
    sh = "/tmp/check_tz_php.sh"
    with sftp.file(sh, "w") as fh:
        fh.write(
            "#!/bin/bash\n"
            "set +e\n"
            "echo '=== prepare around connect ==='\n"
            f"grep -n -C4 'Db::connect\\|SET TIME ZONE' {SRC}/backend/includes/prepare.php | head -40\n"
            "echo '=== Db.php ==='\n"
            f"ls -l {SRC}/backend/includes/Db.php {SRC}/backend/core/Db.php 2>/dev/null\n"
            f"grep -n 'TIME ZONE\\|DB_TIMEZONE' {SRC}/backend/includes/Db.php {SRC}/backend/core/Db.php 2>/dev/null | head -30\n"
            "echo '=== helpers TZ ==='\n"
            f"grep -n 'smartcsetDbTimezone\\|DB_TIMEZONE\\|UTC\\|America/Bogota' "
            f"{SRC}/backend/core/helpers.php {SRC}/backend/includes/helpers.php "
            f"{SRC}/backend/core/helpers.php 2>/dev/null | head -40\n"
            "echo '=== .env TZ ==='\n"
            "grep -E 'TIMEZONE' /var/www/html/smartcset/.env || true\n"
            "echo DONE\n"
        )
    sftp.close()
    print(sudo_bash(client, env["SERVER_PASS"], f"bash {sh}"))
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
