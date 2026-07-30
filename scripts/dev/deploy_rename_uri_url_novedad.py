#!/usr/bin/env python3
"""Despliega rename uri→url + fun_insert_novedad_ingreso en 10.5.213.103."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
SQL_FILES = [
    "database/migrations/rename_uri_to_url_foto_huella.sql",
    "database/functions/porteria/fun_insert_novedad_ingreso.sql",
]


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
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    sftp = client.open_sftp()
    remote_paths: list[str] = []
    for rel in SQL_FILES:
        local = ROOT / rel
        tmp = f"/tmp/{Path(rel).name}.{int(time.time())}"
        sftp.put(str(local), tmp)
        remote = f"{REMOTE_ROOT}/{rel.replace(chr(92), '/')}"
        parent = str(Path(remote).parent).replace("\\", "/")
        print(
            sudo_bash(
                client,
                env["SERVER_PASS"],
                f"mkdir -p '{parent}' && cp '{tmp}' '{remote}' "
                f"&& chown www-data:www-data '{remote}' && rm -f '{tmp}' "
                f"&& echo UP {remote}",
            )
        )
        remote_paths.append(remote)

    # Migración primero, luego función (usa %TYPE de url_*).
    for p in remote_paths:
        print(f"APPLY {p}")
        print(
            sudo_bash(
                client,
                env["SERVER_PASS"],
                f"sudo -u postgres psql -d db_smartcset2 -v ON_ERROR_STOP=1 -f '{p}'",
            )
        )

    verify = (
        "echo '=== COLUMNAS ==='; "
        "sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
        "\"SELECT table_name, column_name FROM information_schema.columns "
        "WHERE table_schema='public' "
        "AND table_name IN ('tab_log_ingresos','tab_novedades_ingreso') "
        "AND (column_name LIKE '%foto_facial%' OR column_name LIKE '%imagen_huella%') "
        "ORDER BY 1,2;\"; "
        "echo '=== FUNCION ==='; "
        "sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
        "\"SELECT oid::regprocedure::text FROM pg_proc "
        "WHERE proname='fun_insert_novedad_ingreso' ORDER BY 1;\""
    )
    print(sudo_bash(client, env["SERVER_PASS"], verify))
    sftp.close()
    client.close()
    print("DONE")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
