#!/usr/bin/env python3
"""Verifica (y corrige si hace falta) DB_TIMEZONE/APP_TIMEZONE en 103."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ENV = "/var/www/html/smartcset/.env"


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        values[k.strip()] = v.strip().strip('"').strip("'")
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
            if idle > 600:
                break
            time.sleep(0.05)
    code = channel.recv_exit_status() if channel.exit_status_ready() else 1
    text = "\n".join(
        ln
        for ln in out.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )
    return code, text


def main() -> int:
    env = load_env()
    host = env.get("SERVER_HOST") or env.get("DB_HOST") or "10.5.213.103"
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
    remote = f"/tmp/check_tz_{int(time.time())}.sh"
    script = f"""#!/bin/bash
set -e
ENV={REMOTE_ENV}
echo '=== ANTES ==='
grep -E '^(DB_TIMEZONE|APP_TIMEZONE)=' "$ENV" || true
need_fix=0
dbtz=$(grep -E '^DB_TIMEZONE=' "$ENV" | tail -1 | cut -d= -f2- | tr -d '\\r' || true)
apptz=$(grep -E '^APP_TIMEZONE=' "$ENV" | tail -1 | cut -d= -f2- | tr -d '\\r' || true)
[ "$dbtz" = "America/Bogota" ] || need_fix=1
[ "$apptz" = "America/Bogota" ] || need_fix=1
if [ "$need_fix" = "1" ]; then
  cp -a "$ENV" "$ENV.bak_tz_$(date +%Y%m%d%H%M%S)"
  if grep -q '^DB_TIMEZONE=' "$ENV"; then
    sed -i 's|^DB_TIMEZONE=.*|DB_TIMEZONE=America/Bogota|' "$ENV"
  else
    echo 'DB_TIMEZONE=America/Bogota' >> "$ENV"
  fi
  if grep -q '^APP_TIMEZONE=' "$ENV"; then
    sed -i 's|^APP_TIMEZONE=.*|APP_TIMEZONE=America/Bogota|' "$ENV"
  else
    echo 'APP_TIMEZONE=America/Bogota' >> "$ENV"
  fi
  chown www-data:www-data "$ENV"
  echo FIXED_TZ
else
  echo TZ_ALREADY_OK
fi
echo '=== DESPUES ==='
grep -E '^(DB_TIMEZONE|APP_TIMEZONE)=' "$ENV"
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SHOW timezone;"
echo OK_CHECK_TZ
"""
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(script.replace("\r\n", "\n"))
    sftp.close()
    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote}; rm -f {remote}")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_CHECK_TZ" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
