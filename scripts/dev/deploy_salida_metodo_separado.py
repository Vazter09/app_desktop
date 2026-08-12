#!/usr/bin/env python3
"""Despliega salida con id_metodo/id_entrada separados (sin pisar ingreso) a 103.

SQL + PHP. Preferencia: psql TCP con DB_*; fallback SSH + sudo -u postgres.

Uso: python scripts/dev/deploy_salida_metodo_separado.py
"""
from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

try:
    import paramiko
except ImportError:
    print("FAIL: falta paramiko. Ejecute: python -m pip install paramiko")
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
DEFAULT_HOST = "10.5.213.103"
DB_NAME = "db_smartcset2"

SQL_FILES = [
    "database/functions/porteria/fun_update_log_salida.sql",
    "database/functions/porteria/fun_registrar_salida_manual.sql",
]

PHP_SYNC = [
    "backend/core/prepare.php",
    "backend/services/porteria/salida_service.php",
    "backend/routers/porteria/_lib/Payload.php",
]

VERIFY_SQL = (
    "SELECT oid::regprocedure::text AS firma "
    "FROM pg_proc "
    "WHERE proname IN ("
    "'fun_update_log_salida','fun_registrar_salida_manual'"
    ") ORDER BY 1;"
)


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        values[key.strip()] = val.strip().strip('"').strip("'")
    return values


def find_psql() -> str | None:
    for ver in ("17", "16", "15", "14"):
        candidate = Path(
            rf"C:\Program Files\PostgreSQL\{ver}\bin\psql.exe"
        )
        if candidate.is_file():
            return str(candidate)
    return None


def try_psql_tcp(env: dict[str, str]) -> bool:
    psql = find_psql()
    if not psql:
        print("TCP: sin psql local — skip")
        return False
    host = env.get("DB_HOST", DEFAULT_HOST)
    port = env.get("DB_PORT", "5432")
    user = env.get("DB_USER", "postgres")
    db = env.get("DB_NAME", DB_NAME)
    password = env.get("DB_PASS", "")
    sslmode = env.get("DB_SSLMODE", "require")
    run_env = {
        **dict(**{k: v for k, v in __import__("os").environ.items()}),
        "PGPASSWORD": password,
        "PGSSLMODE": sslmode,
    }
    print(f"TCP: probando {user}@{host}:{port}/{db} ssl={sslmode} ...")
    probe = subprocess.run(
        [
            psql,
            "-h",
            host,
            "-p",
            port,
            "-U",
            user,
            "-d",
            db,
            "-t",
            "-A",
            "-c",
            "SELECT 1;",
        ],
        env=run_env,
        capture_output=True,
        text=True,
        timeout=20,
    )
    if probe.returncode != 0:
        err = (probe.stderr or probe.stdout or "").strip().splitlines()
        print("TCP FAIL:", err[-1] if err else "auth/connect error")
        return False
    print("TCP OK — aplicando SQL por psql remoto")
    for rel in SQL_FILES:
        path = ROOT / rel
        print(f"  APPLY {rel}")
        r = subprocess.run(
            [
                psql,
                "-h",
                host,
                "-p",
                port,
                "-U",
                user,
                "-d",
                db,
                "-v",
                "ON_ERROR_STOP=1",
                "-f",
                str(path),
            ],
            env=run_env,
            capture_output=True,
            text=True,
            timeout=60,
        )
        if r.returncode != 0:
            print("FAIL SQL:", (r.stderr or r.stdout).strip()[-500:])
            return False
    ver = subprocess.run(
        [
            psql,
            "-h",
            host,
            "-p",
            port,
            "-U",
            user,
            "-d",
            db,
            "-t",
            "-A",
            "-c",
            VERIFY_SQL,
        ],
        env=run_env,
        capture_output=True,
        text=True,
        timeout=20,
    )
    print("Firmas TCP:\n" + (ver.stdout or "").strip())
    return ver.returncode == 0


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


def deploy_ssh(env: dict[str, str], sql_already_done: bool) -> int:
    host = env.get("SERVER_HOST") or env.get("DB_HOST") or DEFAULT_HOST
    user = env.get("SERVER_USER", "")
    password = env.get("SERVER_PASS", "")
    if not user or not password:
        print("FAIL: SERVER_USER/SERVER_PASS en .env")
        return 1

    print(f"SSH: {user}@{host} ...")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=user,
        password=password,
        timeout=30,
        allow_agent=False,
        look_for_keys=False,
    )
    sftp = client.open_sftp()
    remote_tmp = f"/tmp/smartcset_salida_metodo_{int(time.time())}"
    code, out = sudo_bash(
        client, password, f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}"
    )
    print(out)
    if code != 0:
        print("FAIL mkdir")
        client.close()
        return 1

    for rel in SQL_FILES + PHP_SYNC:
        local = ROOT / rel
        if not local.is_file():
            print(f"FAIL missing {rel}")
            client.close()
            return 1
        sftp.put(str(local), f"{remote_tmp}/{Path(rel).name}")
        print(f"  UP {Path(rel).name}")

    for rel in PHP_SYNC:
        tmp_php = f"{remote_tmp}/{Path(rel).name}"
        remote = f"{REMOTE_ROOT}/{rel.replace(chr(92), '/')}"
        parent = str(Path(remote).parent).replace("\\", "/")
        code, out = sudo_bash(
            client,
            password,
            f"mkdir -p '{parent}' && cp '{tmp_php}' '{remote}' "
            f"&& chown www-data:www-data '{remote}' && echo UP {remote}",
        )
        print(out)
        if code != 0:
            print(f"FAIL php {rel}")
            client.close()
            return 1

    sftp.close()

    if not sql_already_done:
        for rel in SQL_FILES:
            remote_sql = f"{remote_tmp}/{Path(rel).name}"
            cmd = (
                f"sudo -u postgres env PAGER=cat psql -P pager=off "
                f"-v ON_ERROR_STOP=1 -d {DB_NAME} -f {remote_sql}"
            )
            code, out = sudo_bash(client, password, cmd)
            print(out)
            if code != 0:
                print(f"FAIL apply {rel}")
                client.close()
                return 1

    code, out = sudo_bash(
        client,
        password,
        "sudo -u postgres env PAGER=cat psql -P pager=off -d "
        + DB_NAME
        + " -c "
        + repr(VERIFY_SQL),
    )
    print("Firmas SSH:\n" + out)
    if code != 0:
        client.close()
        return 1

    # Probar que el UPDATE solo toca columnas de salida (prosrc check).
    code, out = sudo_bash(
        client,
        password,
        "sudo -u postgres env PAGER=cat psql -P pager=off -d "
        + DB_NAME
        + " -t -A -c "
        + repr(
            "SELECT CASE WHEN prosrc LIKE '%id_metodo_salida%' "
            "AND prosrc LIKE '%id_entrada_salida%' "
            "AND prosrc NOT LIKE '%id_metodo_ingreso =%' "
            "THEN 'OK_UPDATE_SALIDA_ONLY' ELSE 'FAIL_SRC' END "
            "FROM pg_proc WHERE proname='fun_update_log_salida' LIMIT 1;"
        ),
    )
    print("Check cuerpo:\n" + out)
    sudo_bash(client, password, f"rm -rf {remote_tmp}")
    client.close()
    return 0 if "OK_UPDATE_SALIDA_ONLY" in out else 1


def main() -> int:
    env = load_env()
    sql_ok = try_psql_tcp(env)
    if not sql_ok:
        print("Fallback: SQL + PHP por SSH")
    else:
        print("SQL vía TCP OK — sincronizando PHP por SSH")
    return deploy_ssh(env, sql_already_done=sql_ok)


if __name__ == "__main__":
    raise SystemExit(main())
