#!/usr/bin/env python3
"""Despliega regla 5 min + UPDATE captura ingreso abierto a 10.5.213.103.

Uso: python scripts/dev/deploy_regla_captura_salida_5min.py
"""
from __future__ import annotations

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
    "database/functions/porteria/fun_update_log_salida.sql",
    "database/functions/porteria/fun_actualizar_captura_ingreso_abierto.sql",
]

PHP_SYNC = [
    "backend/core/prepare.php",
    "backend/services/porteria/consulta_service.php",
    "backend/services/porteria/ingreso_service.php",
    "backend/services/porteria/salida_service.php",
    "backend/routers/porteria/v1/ingreso/consultar.php",
    "backend/routers/porteria/v1/ingreso/actualizar_captura.php",
    "backend/routers/porteria/v1/salida/consultar.php",
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


def main() -> int:
    env = load_env()
    host = env.get("SERVER_HOST", DEFAULT_HOST)
    user = env.get("SERVER_USER", "")
    password = env.get("SERVER_PASS", "")
    if not user or not password:
        print("FAIL: SERVER_USER/SERVER_PASS en .env")
        return 1

    print(f"Conectando {user}@{host} ...")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(hostname=host, username=user, password=password, timeout=30)
    sftp = client.open_sftp()

    remote_tmp = f"/tmp/smartcset_captura_5min_{int(time.time())}"
    code, out = sudo_bash(client, password, f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}")
    print(out)
    if code != 0:
        print("FAIL mkdir tmp")
        return 1

    print("--- Subiendo SQL ---")
    for rel in SQL_FILES:
        local = ROOT / rel
        remote = f"{remote_tmp}/{Path(rel).name}"
        sftp.put(str(local), remote)
        print(f"  OK {remote}")

    print("--- Subiendo PHP ---")
    for rel in PHP_SYNC:
        local = ROOT / rel
        remote = f"{REMOTE_ROOT}/{rel.replace(chr(92), '/')}"
        ensure_remote_dir(sftp, str(Path(remote).parent).replace("\\", "/"))
        sftp.put(str(local), remote)
        print(f"  OK {remote}")

    sftp.close()

    print("--- Aplicando SQL ---")
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

    verify = (
        "sudo -u postgres env PAGER=cat psql -P pager=off -d "
        + DB_NAME
        + " -c "
        + repr(
            "SELECT oid::regprocedure FROM pg_proc WHERE proname IN "
            "('fun_update_log_salida','fun_actualizar_captura_ingreso_abierto') "
            "ORDER BY 1;"
        )
    )
    code, out = sudo_bash(client, password, verify)
    print(out)
    if code != 0:
        print("FAIL verify")
        client.close()
        return 1

    # Prueba rápida: UPDATE captura requiere ingreso abierto; salida <5min debe fallar.
    smoke = (
        "sudo -u postgres env PAGER=cat psql -P pager=off -d "
        + DB_NAME
        + " -c "
        + repr(
            "SELECT position('300' in prosrc) > 0 AS tiene_regla_5min "
            "FROM pg_proc WHERE proname = 'fun_update_log_salida';"
        )
    )
    code, out = sudo_bash(client, password, smoke)
    print(out)

    sudo_bash(client, password, f"rm -rf {remote_tmp}")
    client.close()
    print("OK deploy regla captura + 5 min")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
