#!/usr/bin/env python3
"""Aplica fun_registrar_ingreso_manual vía peer auth (run.sh en /tmp)."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
SQL = ROOT / "database/functions/porteria/fun_registrar_ingreso_manual.sql"


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
    time.sleep(0.5)
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
            if idle > 900:
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
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("DB_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    remote_tmp = f"/tmp/fun_peer_{int(time.time())}"
    sudo_bash(client, env["SERVER_PASS"], f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}")
    sftp = client.open_sftp()
    sftp.put(str(SQL), f"{remote_tmp}/fun.sql")
    run = f"""#!/bin/bash
set -e
TMP={remote_tmp}
DB=db_smartcset2
echo '=== BEFORE ==='
sudo -u postgres psql -d "$DB" -P pager=off -c "SELECT oid::regprocedure::text FROM pg_proc WHERE proname='fun_registrar_ingreso_manual' ORDER BY 1;"
echo '=== APPLY ==='
sudo -u postgres psql -d "$DB" -P pager=off -v ON_ERROR_STOP=1 -f "$TMP/fun.sql"
echo '=== AFTER ==='
sudo -u postgres psql -d "$DB" -P pager=off -c "SELECT oid::regprocedure::text FROM pg_proc WHERE proname='fun_registrar_ingreso_manual' ORDER BY 1;"
rm -rf "$TMP"
echo OK_PEER_SQL
"""
    with sftp.file(f"{remote_tmp}/run.sh", "w") as fh:
        fh.write(run)
    sftp.close()

    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote_tmp}/run.sh")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_PEER_SQL" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
