#!/usr/bin/env python3
"""Aplica add_ind_vehiculo_tab_instructores.sql en 103 vía peer auth."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
SQL = ROOT / "database/migrations/add_ind_vehiculo_tab_instructores.sql"


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
            if idle > 700:
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
    remote_tmp = f"/tmp/mig_veh_{int(time.time())}"
    sudo_bash(client, env["SERVER_PASS"], f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}")
    sftp = client.open_sftp()
    sftp.put(str(SQL), f"{remote_tmp}/mig.sql")
    run = f"""#!/bin/bash
set -e
TMP={remote_tmp}
sudo -u postgres psql -d db_smartcset2 -P pager=off -v ON_ERROR_STOP=1 -f "$TMP/mig.sql"
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name='tab_instructores' AND column_name='ind_vehiculo';"
rm -rf "$TMP"
echo OK_VEHICULO
"""
    with sftp.file(f"{remote_tmp}/run.sh", "w") as fh:
        fh.write(run.replace("\r\n", "\n"))
    sftp.close()
    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote_tmp}/run.sh")
    print(out)
    client.close()
    return 0 if "OK_VEHICULO" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
