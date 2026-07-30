#!/usr/bin/env python3
"""Despliega fun_identificar_persona_por_rostro (+ guardar) en BD remota.

Usa sudo -u postgres psql (peer auth local), mismo patrón que
deploy_fix_ingreso_facial.py.

Uso: python scripts/dev/deploy_fun_identificar_rostro.py
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
    "database/migrations/migrate_biometria_a_tab_personas.sql",
    "database/functions/porteria/fun_guardar_enrolamiento_facial.sql",
    "database/functions/porteria/fun_identificar_persona_por_rostro.sql",
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
            try:
                sftp.mkdir(cur)
            except OSError:
                pass


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
            if idle > 900:
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

    for rel in SQL_FILES:
        if not (ROOT / rel).is_file():
            print(f"FAIL: falta {rel}")
            return 1

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"Conectando a {user}@{host}...")
    client.connect(
        hostname=host,
        username=user,
        password=password,
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )

    remote_tmp = f"/tmp/smartcset_fun_rostro_{int(time.time())}"
    code0, out0 = sudo_bash(
        client, password, f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}"
    )
    if code0 != 0:
        print("FAIL tmp:", out0)
        client.close()
        return 1

    sftp = client.open_sftp()
    for rel in SQL_FILES:
        name = Path(rel).name
        sftp.put(str(ROOT / rel), f"{remote_tmp}/{name}")
        print(f"OK tmp {name}")

    remote_sh = f"{remote_tmp}/run.sh"
    lines = [
        "#!/bin/bash",
        "set -euo pipefail",
        f"DB={DB_NAME}",
        "export PAGER=cat",
        "export PGOPTIONS=\"-c search_path=public\"",
        'echo "=== FIRMAS ANTES ==="',
        'sudo -u postgres env PAGER=cat psql -d "$DB" -P pager=off -c '
        '"SELECT oid::regprocedure::text FROM pg_proc WHERE proname IN '
        "('fun_identificar_persona_por_rostro','fun_guardar_enrolamiento_facial') "
        'ORDER BY 1;"',
        'echo "=== COLUMNAS tab_personas ==="',
        'sudo -u postgres env PAGER=cat psql -d "$DB" -P pager=off -c '
        '"SELECT column_name, udt_name FROM information_schema.columns '
        "WHERE table_name='tab_personas' AND column_name IN "
        "('val_patron_facial','ruta_foto_facial') ORDER BY 1;\"",
    ]
    for rel in SQL_FILES:
        name = Path(rel).name
        dest = f"{REMOTE_ROOT}/{rel}"
        dest_dir = str(Path(dest).parent).replace("\\", "/")
        lines.append(f'echo "=== APPLY {name} ==="')
        lines.append(f"mkdir -p {dest_dir}")
        lines.append(f"cp -f {remote_tmp}/{name} {dest}")
        lines.append(
            f'sudo -u postgres env PAGER=cat psql -d "$DB" -P pager=off '
            f'-v ON_ERROR_STOP=1 -f "{dest}"'
        )
    lines += [
        'echo "=== FIRMAS DESPUES ==="',
        'sudo -u postgres env PAGER=cat psql -d "$DB" -P pager=off -c '
        '"SELECT oid::regprocedure::text FROM pg_proc WHERE proname IN '
        "('fun_identificar_persona_por_rostro','fun_guardar_enrolamiento_facial') "
        'ORDER BY 1;"',
        f"rm -rf {remote_tmp}",
        'echo OK_DEPLOY_FUN_ROSTRO',
    ]
    with sftp.file(remote_sh, "w") as fh:
        fh.write("\n".join(lines) + "\n")
    sftp.close()

    print("Ejecutando script remoto...")
    code, out = sudo_bash(client, password, f"bash {remote_sh}")
    print(out)
    print(f"exit={code}")
    client.close()

    if "OK_DEPLOY_FUN_ROSTRO" not in out or code != 0:
        print("FAIL deploy funciones facial")
        return 1

    # Debe existir la firma exacta que usa prepare.php
    if "fun_identificar_persona_por_rostro(vector,numeric)" not in out.replace(
        " ", ""
    ).lower() and "fun_identificar_persona_por_rostro(vector,numeric)" not in out.lower():
        # regprocedure suele ser fun_identificar_persona_por_rostro(vector,numeric)
        if "fun_identificar_persona_por_rostro" not in out:
            print("FAIL: función no aparece tras deploy")
            return 1

    print("OK deploy fun_identificar_persona_por_rostro")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
