#!/usr/bin/env python3
"""Busca tab_enrolamiento_facial en PHP remoto + smoke fun_identificar."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]

RUN = r"""#!/bin/bash
set -e
echo '=== grep PHP remoto enrolamiento ==='
grep -Rn 'tab_enrolamiento_facial' /var/www/html/smartcset/backend 2>/dev/null | head -40 || echo 'NONE_IN_BACKEND'
echo '=== prepare biometria stmts ==='
grep -n 'fun_identificar\|fun_guardar_enrolamiento\|enrolamiento\|val_patron' /var/www/html/smartcset/backend/core/prepare.php | head -40
echo '=== smoke identificar ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -v ON_ERROR_STOP=1 <<'SQL'
SET search_path TO public;
SELECT fun_identificar_persona_por_rostro(
  (SELECT ('[' || string_agg('0.01', ',') || ']')::vector FROM generate_series(1,128)),
  0.35::numeric
) AS id;
SELECT COUNT(*) AS enrolados FROM tab_personas WHERE val_patron_facial IS NOT NULL;
SQL
echo '=== ind_estado tipo ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT column_name, data_type, udt_name FROM information_schema.columns WHERE table_name='tab_personas' AND column_name='ind_estado';"
echo OK_SMOKE
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
    remote = f"/tmp/smoke_bio_{int(time.time())}.sh"
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(RUN)
    sftp.close()
    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {remote}; rm -f {remote}")
    out_path = ROOT / "scripts" / "dev" / "_last_smoke_bio.txt"
    out_path.write_text(out, encoding="utf-8", errors="replace")
    print(out_path.read_text(encoding="utf-8", errors="replace")[:4000])
    print("exit", code)
    client.close()
    return 0 if "OK_SMOKE" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
