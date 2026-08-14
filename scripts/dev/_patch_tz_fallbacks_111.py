#!/usr/bin/env python3
"""Fallback UTC -> America/Bogota en Db.php y helpers live (solo TZ)."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
FILES = (
    "/var/www/html/smartcset/src/backend/includes/Db.php",
    "/var/www/html/smartcset/src/backend/includes/helpers.php",
)


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
            if idle > 500:
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
    password = env["SERVER_PASS"]
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST") or "10.5.213.111",
        username=env["SERVER_USER"],
        password=password,
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    sftp = client.open_sftp()
    for path in FILES:
        with sftp.file(path, "r") as fh:
            text = fh.read().decode("utf-8")
        new = text.replace(
            "? DB_TIMEZONE : 'UTC'",
            "? DB_TIMEZONE : 'America/Bogota'",
        )
        new = new.replace(
            '? DB_TIMEZONE : "UTC"',
            '? DB_TIMEZONE : "America/Bogota"',
        )
        if new == text:
            print(f"SKIP no UTC {path}")
            continue
        tmp = f"/tmp/{Path(path).name}_{int(time.time())}"
        bak = f"{path}.bak_tz_{int(time.time())}"
        with sftp.file(tmp, "w") as fh:
            fh.write(new)
        code, out = sudo_bash(
            client,
            password,
            f"cp -f {path} {bak} && cp -f {tmp} {path} && echo OK {path}",
        )
        print(out)
        if code != 0:
            sftp.close()
            client.close()
            return 1
    sftp.close()
    code, out = sudo_bash(
        client,
        password,
        "grep -n \"TIME ZONE\\|DB_TIMEZONE\\|America/Bogota\\|UTC\" "
        "/var/www/html/smartcset/src/backend/includes/Db.php "
        "/var/www/html/smartcset/src/backend/includes/helpers.php | "
        "grep -E 'UTC|Bogota|TIME ZONE|DB_TIMEZONE' | head -40",
    )
    print(out)
    client.close()
    return 0 if code == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
