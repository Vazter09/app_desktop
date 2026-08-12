#!/usr/bin/env python3
"""Despliega fix salida real (PHP consulta + SQL update/migración) a .111.

Uso: python scripts/dev/deploy_fix_salida_real.py
"""
from __future__ import annotations

import os
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
DEFAULT_HOST = "10.5.213.111"

PHP_FILES = [
    "backend/services/porteria/consulta_service.php",
    "backend/services/porteria/salida_service.php",
    "backend/routers/porteria/_lib/Payload.php",
    "backend/core/prepare.php",
]

SQL_FILES = [
    "database/functions/_helpers/smartcset_now_local.sql",
    "database/functions/porteria/fun_update_log_salida.sql",
    "database/functions/porteria/fun_registrar_salida_manual.sql",
    "database/migrations/fix_log_ingresos_utc_futuros.sql",
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


def ensure_remote_dir(sftp: paramiko.SFTPClient, remote_dir: str) -> None:
    parts = remote_dir.strip("/").split("/")
    cur = ""
    for part in parts:
        cur += "/" + part
        try:
            sftp.stat(cur)
        except OSError:
            sftp.mkdir(cur)


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> tuple[int, str]:
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
    code = channel.recv_exit_status() if channel.exit_status_ready() else 1
    text = out_buf.decode("utf-8", errors="replace")
    filtered = [
        ln
        for ln in text.splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    ]
    return code, "\n".join(filtered)


def deploy_sql(env: dict[str, str]) -> int:
    psql = os.environ.get(
        "PSQL",
        r"C:\Program Files\PostgreSQL\17\bin\psql.exe",
    )
    if not Path(psql).is_file():
        print(f"FAIL: no psql en {psql}")
        return 1
    os.environ["PGPASSWORD"] = env.get("DB_PASS", "")
    if env.get("DB_SSLMODE"):
        os.environ["PGSSLMODE"] = env["DB_SSLMODE"]
    host = env.get("DB_HOST", DEFAULT_HOST)
    port = env.get("DB_PORT", "5432")
    user = env.get("DB_USER", "postgres")
    db = env.get("DB_NAME", "db_smartcset2")
    for rel in SQL_FILES:
        path = ROOT / rel
        print(f"SQL {rel}")
        proc = subprocess.run(
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
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        if proc.returncode != 0:
            print(proc.stdout)
            print(proc.stderr)
            print(f"FAIL SQL {rel}")
            return proc.returncode
        if proc.stdout.strip():
            print(proc.stdout.strip()[-500:])
    # Verificación: helper + cuerpo de salida
    check = subprocess.run(
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
            "SELECT smartcset_now_local()::text; "
            "SELECT (prosrc LIKE '%smartcset_now_local%' AND prosrc LIKE '%AT TIME ZONE%UTC%') "
            "FROM pg_proc WHERE proname='fun_update_log_salida' LIMIT 1; "
            "SELECT id_ingreso::text || '|' || fec_ingreso::text || '|' || fec_salida::text "
            "FROM tab_log_ingresos WHERE id_visitante = 1092342075 "
            "ORDER BY id_ingreso DESC LIMIT 3;",
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    print("VERIFY_SQL:")
    print(check.stdout)
    if check.returncode != 0:
        print(check.stderr)
        return check.returncode
    return 0


def deploy_php(env: dict[str, str]) -> int:
    host = os.environ.get("SERVER_HOST") or env.get("SERVER_HOST") or DEFAULT_HOST
    user = os.environ.get("SERVER_USER") or env.get("SERVER_USER", "")
    password = os.environ.get("SERVER_PASS") or env.get("SERVER_PASS", "")
    if not user or not password:
        print("FAIL: SERVER_USER/SERVER_PASS")
        return 1
    for rel in PHP_FILES:
        if not (ROOT / rel).is_file():
            print(f"FAIL falta {rel}")
            return 1
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"SSH {user}@{host}")
    client.connect(
        hostname=host,
        username=user,
        password=password,
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    remote_tmp = f"/tmp/smartcset_salida_{int(time.time())}"
    code_m, out_m = sudo_bash(
        client, password, f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}"
    )
    if code_m != 0:
        print("FAIL mkdir", out_m)
        client.close()
        return 1
    sftp = client.open_sftp()
    for rel in PHP_FILES:
        remote_tmp_file = f"{remote_tmp}/{rel}"
        ensure_remote_dir(
            sftp, str(Path(remote_tmp_file).parent).replace("\\", "/")
        )
        sftp.put(str(ROOT / rel), remote_tmp_file)
        print(f"OK tmp {rel}")
    sftp.close()
    parts = []
    for rel in PHP_FILES:
        dest_dir = str(Path(f"{REMOTE_ROOT}/{rel}").parent).replace("\\", "/")
        parts.append(f"mkdir -p {dest_dir}")
        parts.append(f"cp -f {remote_tmp}/{rel} {REMOTE_ROOT}/{rel}")
    parts.append(
        f"grep -n 'porteriaSegundosDesdeTimestamp' "
        f"{REMOTE_ROOT}/backend/services/porteria/consulta_service.php | head -3"
    )
    parts.append(f"rm -rf {remote_tmp}")
    parts.append("echo DEPLOY_SALIDA_PHP_OK")
    code2, out2 = sudo_bash(client, password, " && ".join(parts))
    print(out2)
    client.close()
    if code2 != 0 or "DEPLOY_SALIDA_PHP_OK" not in out2:
        print("FAIL PHP deploy")
        return 1
    return 0


def main() -> int:
    env = load_env()
    rc = deploy_sql(env)
    if rc != 0:
        return rc
    rc = deploy_php(env)
    if rc != 0:
        return rc
    print("OK deploy fix salida real")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
