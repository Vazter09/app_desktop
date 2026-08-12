#!/usr/bin/env python3
"""Smoke post-deploy observaciones -> novedades diarias."""
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
            if idle > 1200:
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
    host = env.get("SERVER_HOST") or env.get("DB_HOST") or "10.5.213.103"
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=45,
        allow_agent=False,
        look_for_keys=False,
    )
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    remote = f"/tmp/smoke_novedad_{int(time.time())}.sql"
    sql = """
\\pset pager off
SELECT COUNT(*) AS sin_val_observaciones
  FROM information_schema.columns
 WHERE table_name='tab_log_ingresos' AND column_name='val_observaciones';
SELECT COUNT(*) AS tiene_novedades_diarias
  FROM information_schema.tables
 WHERE table_name='tab_novedades_diarias';
SELECT position('fun_insert_novedad_diaria' in prosrc) > 0 AS registrar_crea_novedad
  FROM pg_proc WHERE proname='fun_registrar_ingreso_manual';
SELECT position('id_metodo_ingreso' in prosrc) > 0 AS insert_usa_metodo_ingreso
  FROM pg_proc WHERE proname='fun_insert_log_ingreso';
"""
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(sql)
    sftp.close()
    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        f"sudo -u postgres env PAGER=cat psql -P pager=off -d db_smartcset2 -f {remote}"
        f" && grep -n id_entrada_ingreso /var/www/html/smartcset/backend/core/prepare.php | head -5"
        f" && echo PHP_OK",
    )
    print(out)
    client.close()
    return 0 if code == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
