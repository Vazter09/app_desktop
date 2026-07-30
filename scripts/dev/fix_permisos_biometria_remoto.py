#!/usr/bin/env python3
"""Corrige permisos uploads/biometria (www-data) en 10.5.213.103."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
BASE = "/var/www/html/smartcset/frontend/web/public/uploads/biometria"
UPLOADS = "/var/www/html/smartcset/frontend/web/public/uploads"

RUN_SH = f"""#!/bin/bash
set -e
echo '=== ANTES ==='
ls -lad {UPLOADS} 2>&1 || true
ls -lad {BASE} 2>&1 || true
namei -l {BASE} 2>&1 || true
id www-data
echo '=== FIX ==='
mkdir -p {BASE}
chown -R www-data:www-data {UPLOADS}
chmod 775 {UPLOADS}
find {BASE} -type d -exec chmod 775 {{}} +
find {BASE} -type f -exec chmod 664 {{}} + 2>/dev/null || true
sudo -u www-data mkdir -p {BASE}/1092342075
sudo -u www-data touch {BASE}/1092342075/.write_test
sudo -u www-data rm -f {BASE}/1092342075/.write_test
echo '=== DESPUES ==='
ls -lad {UPLOADS}
ls -lad {BASE}
ls -lad {BASE}/1092342075
sudo -u www-data test -w {BASE} && echo OK_BASE_WRITABLE
sudo -u www-data test -w {BASE}/1092342075 && echo OK_PERSONA_WRITABLE
echo OK_BIOMETRIA_PERMS
"""


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
    time.sleep(0.4)
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
    host = env.get("SERVER_HOST") or env.get("DB_HOST", "10.5.213.103")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    remote = f"/tmp/fix_bio_perms_{int(time.time())}.sh"
    sudo_bash(client, env["SERVER_PASS"], f"mkdir -p /tmp && chmod 777 /tmp")
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(RUN_SH.replace("\r\n", "\n"))
    sftp.close()
    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote}; rm -f {remote}")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_BIOMETRIA_PERMS" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
