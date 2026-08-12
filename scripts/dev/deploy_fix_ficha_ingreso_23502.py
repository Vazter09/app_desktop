#!/usr/bin/env python3
"""Deploy fix: ficha/estado en consultar + INSERT log (defaults equipo/vehículo).

Uso: python scripts/dev/deploy_fix_ficha_ingreso_23502.py
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
    "database/functions/porteria/fun_insert_log_ingreso.sql",
]

PHP_SYNC = [
    "backend/core/prepare.php",
    "backend/routers/porteria/_lib/Payload.php",
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
    host = env.get("SERVER_HOST") or env.get("DB_HOST") or DEFAULT_HOST
    user = env.get("SERVER_USER", "")
    password = env.get("SERVER_PASS", "")
    if not user or not password:
        print("FAIL: SERVER_USER/SERVER_PASS en .env")
        return 1

    print(f"Conectando {user}@{host} ...")
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
    remote_tmp = f"/tmp/smartcset_fix_ficha_{int(time.time())}"
    code, out = sudo_bash(
        client, password, f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}"
    )
    print(out)
    if code != 0:
        print("FAIL mkdir")
        return 1

    for rel in SQL_FILES + PHP_SYNC:
        local = ROOT / rel
        if not local.is_file():
            print(f"FAIL missing {rel}")
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
            "SELECT column_name, column_default "
            "FROM information_schema.columns "
            "WHERE table_name='tab_log_ingresos' AND is_nullable='NO' "
            "ORDER BY ordinal_position;"
        )
        + " -c "
        + repr(
            "SELECT position('id_equipo' in prosrc) > 0 AS insert_tiene_equipo, "
            "position('AAA000' in prosrc) > 0 AS insert_tiene_vehiculo "
            "FROM pg_proc WHERE proname='fun_insert_log_ingreso';"
        )
        + " -c "
        + repr(
            "SET app.usuario = 'porteria'; "
            "SELECT fun_registrar_ingreso_manual("
            "1007692289::NUMERIC, 'CC', 2, 'TEST', 'SMOKE', "
            "1, NULL, 3, FALSE, NULL, NULL"
            ");"
        )
    )
    code, out = sudo_bash(client, password, verify)
    print("--- VERIFY / SMOKE ---")
    print(out)

    # Rollback smoke row if created
    cleanup = (
        "sudo -u postgres env PAGER=cat psql -P pager=off -d "
        + DB_NAME
        + " -c "
        + repr(
            "DELETE FROM tab_novedades_diarias WHERE id_ingreso IN ("
            "SELECT id_ingreso FROM tab_log_ingresos "
            "WHERE id_visitante = 1007692289 AND usr_insert = 'porteria' "
            "AND fec_ingreso > NOW() - INTERVAL '2 minutes'"
            "); "
            "DELETE FROM tab_log_ingresos "
            "WHERE id_visitante = 1007692289 AND usr_insert = 'porteria' "
            "AND fec_ingreso > NOW() - INTERVAL '2 minutes';"
        )
    )
    _, cout = sudo_bash(client, password, cleanup)
    print("--- CLEANUP ---")
    print(cout)

    sudo_bash(client, password, f"rm -rf {remote_tmp}")
    client.close()
    if code != 0:
        print("FAIL verify/smoke")
        return 1
    print("OK deploy ficha + insert log")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
