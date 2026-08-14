#!/usr/bin/env python3
"""Restaura prepare_login.php en src/includes y el require de auth_login."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
AUTH = "/var/www/html/smartcset/src/backend/api/auth_login.php"
INC = "/var/www/html/smartcset/src/backend/includes"


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
    tmp = f"/tmp/prepare_login_{int(time.time())}.php"
    sftp.put(str(ROOT / "backend/core/prepare_login.php"), tmp)
    with sftp.open(AUTH, "r") as fh:
        auth = fh.read().decode("utf-8")
    auth2 = auth.replace(
        "require_once dirname(__DIR__) . '/includes/prepare.php';",
        "require_once dirname(__DIR__) . '/includes/prepare_login.php';",
        1,
    )
    if auth2 == auth and "prepare_login.php" not in auth:
        print("FAIL auth_login require no coincide")
        print(auth[:500])
        client.close()
        return 1
    tmp_auth = f"/tmp/auth_login_{int(time.time())}.php"
    with sftp.open(tmp_auth, "w") as fh:
        fh.write(auth2.encode("utf-8"))
    sftp.close()
    cmd = (
        f"cp -f {tmp} {INC}/prepare_login.php && "
        f"cp -f {tmp_auth} {AUTH} && "
        f"php -l {INC}/prepare_login.php && "
        f"grep -n prepare {AUTH} && "
        "echo DEPLOY5_OK"
    )
    code, out = sudo_bash(client, password, cmd)
    print(out)
    client.close()
    if code != 0 or "DEPLOY5_OK" not in out:
        print("FAIL deploy5")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
