#!/usr/bin/env python3
"""Quita la llamada a smartcsetAplicarSesionParqueadero (no existe en helpers)."""
from __future__ import annotations

import re
import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
AUTH = "/var/www/html/smartcset/src/backend/api/auth_login.php"


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
    text = out_buf.decode("utf-8", errors="replace")
    filtered = [
        ln
        for ln in text.splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    ]
    return code, "\n".join(filtered)


def main() -> int:
    env = load_env()
    password = env.get("SERVER_PASS", "")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.111"),
        username=env.get("SERVER_USER", ""),
        password=password,
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    sftp = client.open_sftp()
    with sftp.open(AUTH, "r") as fh:
        text = fh.read().decode("utf-8")
    print("BEFORE")
    for i, line in enumerate(text.splitlines(), 1):
        if 84 <= i <= 95:
            print(f"{i}:{line}")
    new, n = re.subn(
        r"[ \t]*smartcsetAplicarSesionParqueadero\s*\([^;]*\)\s*;\s*",
        "",
        text,
        count=1,
    )
    if n != 1:
        print("FAIL no se quito la llamada", n)
        client.close()
        return 1
    tmp = f"/tmp/auth_nopark_{int(time.time())}.php"
    with sftp.open(tmp, "w") as fh:
        fh.write(new.encode("utf-8"))
    sftp.close()
    code, out = sudo_bash(
        client, password, f"cp -f {tmp} {AUTH} && grep -n Parqueadero {AUTH} || echo NO_PARK && echo DEPLOY6_OK"
    )
    print(out)
    client.close()
    return 0 if "DEPLOY6_OK" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
