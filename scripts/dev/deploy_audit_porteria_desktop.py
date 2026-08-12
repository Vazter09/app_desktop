#!/usr/bin/env python3
"""Despliega auditoría PORTERIA (desktop) a 10.5.213.103.

SQL: fun_audit_trigger (app.usuario + etiqueta PORTERIA)
PHP: login, prepare, acceso_sesion, require_session_or_device

Uso: python scripts/dev/deploy_audit_porteria_desktop.py
"""
from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

try:
    import paramiko
except ImportError:
    print("FAIL: falta paramiko")
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
DEFAULT_HOST = "10.5.213.103"
DB_NAME = "db_smartcset2"

SQL_FILES = [
    "database/migrations/fix_fun_audit_trigger_app_usuario_porteria.sql",
]

PHP_SYNC = [
    "backend/core/lib/acceso_sesion.php",
    "backend/core/prepare.php",
    "backend/routers/auth/v1/login.php",
    "backend/middleware/require_session_or_device.php",
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


def find_psql() -> str | None:
    for ver in ("17", "16", "15", "14"):
        candidate = Path(rf"C:\Program Files\PostgreSQL\{ver}\bin\psql.exe")
        if candidate.is_file():
            return str(candidate)
    return None


def apply_sql_tcp(env: dict[str, str]) -> bool:
    psql = find_psql()
    if not psql:
        return False
    host = env.get("DB_HOST", DEFAULT_HOST)
    port = env.get("DB_PORT", "5432")
    user = env.get("DB_USER", "postgres")
    db = env.get("DB_NAME", DB_NAME)
    run_env = {
        **{k: v for k, v in __import__("os").environ.items()},
        "PGPASSWORD": env.get("DB_PASS", ""),
        "PGSSLMODE": env.get("DB_SSLMODE", "require"),
    }
    for rel in SQL_FILES:
        path = ROOT / rel
        print(f"TCP APPLY {rel}")
        r = subprocess.run(
            [
                psql, "-h", host, "-p", port, "-U", user, "-d", db,
                "-v", "ON_ERROR_STOP=1", "-f", str(path),
            ],
            env=run_env,
            capture_output=True,
            text=True,
            timeout=60,
        )
        if r.returncode != 0:
            print("FAIL:", (r.stderr or r.stdout)[-800:])
            return False
    check = subprocess.run(
        [
            psql, "-h", host, "-p", port, "-U", user, "-d", db,
            "-t", "-A", "-c",
            "SELECT CASE WHEN prosrc LIKE '%app.usuario%' "
            "AND prosrc NOT LIKE '%PORTERIA%' "
            "THEN 'OK_AUDIT_APP_USUARIO' ELSE 'FAIL' END "
            "FROM pg_proc WHERE proname='fun_audit_trigger' LIMIT 1;",
        ],
        env=run_env,
        capture_output=True,
        text=True,
        timeout=20,
    )
    print("SQL check:", (check.stdout or "").strip())
    return check.returncode == 0 and "OK_AUDIT_APP_USUARIO" in (check.stdout or "")


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
        ln for ln in text.splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    ]
    return code, "\n".join(filtered)


def sync_php_ssh(env: dict[str, str]) -> int:
    host = env.get("SERVER_HOST") or env.get("DB_HOST") or DEFAULT_HOST
    user = env.get("SERVER_USER", "")
    password = env.get("SERVER_PASS", "")
    if not user or not password:
        print("FAIL: SERVER_USER/SERVER_PASS")
        return 1
    print(f"SSH {user}@{host}")
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
    remote_tmp = f"/tmp/smartcset_audit_porteria_{int(time.time())}"
    code, out = sudo_bash(
        client, password, f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}"
    )
    print(out)
    if code != 0:
        client.close()
        return 1
    for rel in PHP_SYNC:
        local = ROOT / rel
        if not local.is_file():
            print(f"FAIL missing {rel}")
            client.close()
            return 1
        sftp.put(str(local), f"{remote_tmp}/{Path(rel).name}")
        remote = f"{REMOTE_ROOT}/{rel.replace(chr(92), '/')}"
        parent = str(Path(remote).parent).replace("\\", "/")
        tmp_php = f"{remote_tmp}/{Path(rel).name}"
        code, out = sudo_bash(
            client,
            password,
            f"mkdir -p '{parent}' && cp '{tmp_php}' '{remote}' "
            f"&& chown www-data:www-data '{remote}' && echo UP {remote}",
        )
        print(out)
        if code != 0:
            client.close()
            return 1
    sftp.close()
    # Smoke: app.usuario acepta id real de sesión
    code, out = sudo_bash(
        client,
        password,
        "sudo -u postgres env PAGER=cat psql -P pager=off -d "
        + DB_NAME
        + " -t -A -c "
        + repr(
            "SELECT set_config('app.usuario','porteria',false); "
            "SELECT current_setting('app.usuario', true);"
        ),
    )
    print("app.usuario smoke:\n" + out)
    sudo_bash(client, password, f"rm -rf {remote_tmp}")
    client.close()
    return 0 if "porteria" in out else 1


def main() -> int:
    env = load_env()
    if not apply_sql_tcp(env):
        print("FAIL SQL TCP")
        return 1
    return sync_php_ssh(env)


if __name__ == "__main__":
    raise SystemExit(main())
