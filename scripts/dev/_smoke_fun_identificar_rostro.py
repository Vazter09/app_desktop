#!/usr/bin/env python3
"""Smoke: firma + llamada fun_identificar en BD remota + grep prepare.php."""
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
    text = out_buf.decode("utf-8", errors="replace")
    filtered = [
        ln
        for ln in text.splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    ]
    return code, "\n".join(filtered)


def main() -> int:
    env = load_env()
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )

    remote_sh = "/tmp/smoke_fun_rostro.sh"
    script = r"""#!/bin/bash
set -euo pipefail
echo '=== .env remoto DB_* ==='
grep -E '^(DB_HOST|DB_NAME|DB_USER|DB_SSLMODE)=' /var/www/html/smartcset/.env || true
echo '=== firmas ==='
sudo -u postgres env PAGER=cat psql -d db_smartcset2 -P pager=off -c \
  "SELECT oid::regprocedure::text FROM pg_proc WHERE proname='fun_identificar_persona_por_rostro' ORDER BY 1;"
echo '=== smoke 128-d ==='
VEC=$(python3 -c 'print("[" + ",".join(["0.01"]*128) + "]")')
sudo -u postgres env PAGER=cat psql -d db_smartcset2 -P pager=off -v ON_ERROR_STOP=1 -c \
  "SET search_path TO public; SELECT fun_identificar_persona_por_rostro('${VEC}'::vector, 0.35::numeric) AS id;"
echo '=== prepare.php ==='
grep -n 'fun_identificar_persona_por_rostro' /var/www/html/smartcset/backend/core/prepare.php | head -n 5
echo OK_SMOKE
"""
    sftp = client.open_sftp()
    with sftp.file(remote_sh, "w") as fh:
        fh.write(script)
    sftp.close()

    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote_sh}; rm -f {remote_sh}")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_SMOKE" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
