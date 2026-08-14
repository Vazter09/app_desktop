#!/usr/bin/env python3
"""Solo lectura: reloj America/Bogota en .111 (PHP live + SQL)."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
SRC = "/var/www/html/smartcset/src"


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        values[key.strip()] = val.strip().strip('"').strip("'")
    return values


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> str:
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
            if idle > 800:
                break
            time.sleep(0.05)
    return "\n".join(
        ln
        for ln in out.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )


def main() -> int:
    env = load_env()
    host = env.get("SERVER_HOST") or "10.5.213.111"
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
    inner = r"""
set +e
echo '=== PG TZ ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SHOW timezone;"
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT now() AS now_sesion, CURRENT_TIMESTAMP::timestamp AS ts_naive, (CURRENT_TIMESTAMP AT TIME ZONE 'America/Bogota') AS now_bogota;"
echo '=== smartcset_now_local ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname='smartcset_now_local';"
echo '=== fun clock ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -tAc "SELECT proname || ': ' || CASE WHEN prosrc LIKE '%smartcset_now_local%' THEN 'now_local' WHEN prosrc LIKE '%CURRENT_TIMESTAMP%' THEN 'CURRENT_TIMESTAMP' ELSE 'other' END FROM pg_proc WHERE proname IN ('fun_insert_log_ingreso','fun_update_log_salida','fun_registrar_ingreso_manual','fun_registrar_salida_manual','fun_update_persona_tras_ingreso','fun_update_persona_tras_salida');"
echo '=== last logs ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT id_ingreso, fec_ingreso, fec_salida FROM tab_log_ingresos ORDER BY id_ingreso DESC LIMIT 5;"
echo '=== PHP TZ ==='
grep -n 'TIME ZONE\|DB_TIMEZONE\|America/Bogota' {SRC}/backend/core/Db.php {SRC}/backend/core/config.php {SRC}/backend/includes/*.php {SRC}/.env /var/www/html/smartcset/.env 2>/dev/null | head -40
echo '=== find SET TIME ZONE php ==='
grep -Rnl 'SET TIME ZONE' {SRC}/backend --include='*.php' 2>/dev/null | head
echo DONE
""".replace("{SRC}", SRC)
    print(sudo_bash(client, env["SERVER_PASS"], inner))
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
