#!/usr/bin/env python3
"""Smoke: columnas NOT NULL + registrar ingreso de prueba (rollback)."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
DB = "db_smartcset2"


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
        timeout=30,
        allow_agent=False,
        look_for_keys=False,
    )

    remote = f"/tmp/smoke_ficha_{int(time.time())}.sql"
    sql = r"""
\pset pager off
SELECT column_name, column_default
  FROM information_schema.columns
 WHERE table_name='tab_log_ingresos' AND is_nullable='NO'
 ORDER BY ordinal_position;

SELECT position('id_equipo' in prosrc) > 0 AS tiene_equipo,
       position('AAA000' in prosrc) > 0 AS tiene_vehiculo
  FROM pg_proc WHERE proname='fun_insert_log_ingreso';

SELECT id_aprendiz, id_ficha, ind_etdo_formacion
  FROM tab_aprendices
 WHERE id_aprendiz = 1007692289;

BEGIN;
SET LOCAL app.usuario = 'porteria';
SELECT fun_registrar_ingreso_manual(
    1007692289::NUMERIC, 'CC', 2, 'TEST', 'SMOKE',
    1, NULL, 3, FALSE, NULL, NULL
) AS id_ingreso;
ROLLBACK;
"""
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(sql)
    sftp.close()

    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        f"sudo -u postgres env PAGER=cat psql -P pager=off -d {DB} -f {remote}",
    )
    print(out)

    # Confirm PHP has id_ficha in buscar_persona
    code2, out2 = sudo_bash(
        client,
        env["SERVER_PASS"],
        "grep -n 'id_ficha\\|ind_etdo_formacion\\|tab_aprendices' "
        "/var/www/html/smartcset/backend/core/prepare.php | head -20; "
        "grep -n 'id_ficha\\|estado_formacion' "
        "/var/www/html/smartcset/backend/routers/porteria/_lib/Payload.php | head -20",
    )
    print("--- PHP ---")
    print(out2)

    sudo_bash(client, env["SERVER_PASS"], f"rm -f {remote}")
    client.close()
    return 0 if code == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
