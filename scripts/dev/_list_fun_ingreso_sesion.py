#!/usr/bin/env python3
"""Lista firmas fun_ingreso_sesion en DB del .env local (103) y en BD de Apache."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]

SQL_LIST = r"""
SELECT p.oid::regprocedure::text AS firma, pg_get_function_identity_arguments(p.oid) AS args
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
 WHERE n.nspname = 'public' AND p.proname = 'fun_ingreso_sesion'
 ORDER BY 1;
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


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> str:
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
    return "\n".join(
        ln
        for ln in out_buf.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )


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

    remote = f"/tmp/list_ingreso_sesion_{int(time.time())}.sql"
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(SQL_LIST)
    sftp.close()

    # 1) Local .env DB (103)
    db_host = env["DB_HOST"]
    db_name = env["DB_NAME"]
    db_user = env["DB_USER"]
    db_pass = env["DB_PASS"]
    db_port = env.get("DB_PORT", "5432")
    ssl = env.get("DB_SSLMODE", "require")
    print(f"=== LOCAL .env DB {db_host}/{db_name} ===")
    out1 = sudo_bash(
        client,
        env["SERVER_PASS"],
        f"export PGPASSWORD={db_pass!r}; export PGSSLMODE={ssl}; "
        f"psql -h {db_host} -p {db_port} -U {db_user} -d {db_name} -P pager=off -f {remote} 2>&1",
    )
    print(out1)

    # 2) Apache DB
    print("=== APACHE .env DB ===")
    out2 = sudo_bash(
        client,
        env["SERVER_PASS"],
        "ENVF=/var/www/html/smartcset/.env; "
        "strip(){ printf '%s' \"$1\" | tr -d '\\r' | tr -d '\"' | tr -d \"'\"; }; "
        "H=$(strip \"$(grep -E '^DB_HOST=' \"$ENVF\"|head -1|cut -d= -f2-)\"); "
        "N=$(strip \"$(grep -E '^DB_NAME=' \"$ENVF\"|head -1|cut -d= -f2-)\"); "
        "U=$(strip \"$(grep -E '^DB_USER=' \"$ENVF\"|head -1|cut -d= -f2-)\"); "
        "P=$(strip \"$(grep -E '^DB_PASS=' \"$ENVF\"|head -1|cut -d= -f2-)\"); "
        "PO=$(strip \"$(grep -E '^DB_PORT=' \"$ENVF\"|head -1|cut -d= -f2-)\"); "
        "S=$(strip \"$(grep -E '^DB_SSLMODE=' \"$ENVF\"|head -1|cut -d= -f2-)\"); "
        "PO=${PO:-5432}; S=${S:-require}; "
        "echo HOST=$H NAME=$N; "
        "export PGPASSWORD=\"$P\" PGSSLMODE=\"$S\"; "
        f"psql -h \"$H\" -p \"$PO\" -U \"$U\" -d \"$N\" -P pager=off -f {remote} 2>&1; "
        f"rm -f {remote}",
    )
    print(out2)
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
