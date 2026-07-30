#!/usr/bin/env python3
"""Despliega fun_ingreso_sesion (reclaim desktop total) a 10.5.213.103
y libera sesiones abiertas de porteria.
"""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
SQL_FILE = (
    ROOT / "database/functions/acceso/sesiones/fun_ingreso_sesion.sql"
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
            if idle > 800:
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
    host = env.get("SERVER_HOST", "10.5.213.103")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=30,
    )
    sftp = client.open_sftp()
    tmp = f"/tmp/sesion_reclaim_{int(time.time())}"
    sudo_bash(client, env["SERVER_PASS"], f"mkdir -p {tmp} && chmod 777 {tmp}")

    remote_sql = f"{tmp}/fun_ingreso_sesion.sql"
    sftp.put(str(SQL_FILE), remote_sql)
    print(f"OK upload {remote_sql}")

    verify = f"{tmp}/verify.sql"
    with sftp.file(verify, "w") as fh:
        fh.write(
            "-- Liberar porteria (desbloqueo inmediato)\n"
            "UPDATE tab_sesiones\n"
            "SET fec_fin = CURRENT_TIMESTAMP,\n"
            "    cod_cierre = 'LOGOUT',\n"
            "    usr_cierre = 'porteria'\n"
            "WHERE id_usuario = 'porteria' AND fec_fin IS NULL;\n"
            "\n"
            "SELECT COUNT(*) AS abiertas_porteria\n"
            "FROM tab_sesiones\n"
            "WHERE id_usuario = 'porteria' AND fec_fin IS NULL;\n"
            "\n"
            "SELECT oid::regprocedure::text AS firma\n"
            "FROM pg_proc\n"
            "WHERE proname = 'fun_ingreso_sesion'\n"
            "ORDER BY 1;\n"
            "\n"
            "-- Smoke: reclaim desktop no debe fallar con sesion previa\n"
            "SELECT fun_ingreso_sesion(\n"
            "  'porteria'::TEXT,\n"
            "  '127.0.0.1'::TEXT,\n"
            "  1800,\n"
            "  'app_desktop'::TEXT\n"
            ") AS id_sesion_desktop;\n"
            "\n"
            "UPDATE tab_sesiones\n"
            "SET fec_fin = CURRENT_TIMESTAMP,\n"
            "    cod_cierre = 'LOGOUT',\n"
            "    usr_cierre = 'porteria'\n"
            "WHERE id_usuario = 'porteria' AND fec_fin IS NULL;\n"
            "\n"
            "SELECT COUNT(*) AS abiertas_final\n"
            "FROM tab_sesiones\n"
            "WHERE id_usuario = 'porteria' AND fec_fin IS NULL;\n"
        )
    sftp.close()

    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        "sudo -u postgres env PAGER=cat psql -P pager=off -v ON_ERROR_STOP=1 "
        f"-d db_smartcset2 -f {remote_sql}",
    )
    print(out)
    if code != 0:
        client.close()
        print("FAIL deploy function")
        return 1

    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        "sudo -u postgres env PAGER=cat psql -P pager=off -v ON_ERROR_STOP=1 "
        f"-d db_smartcset2 -f {verify}",
    )
    print(out)
    sudo_bash(client, env["SERVER_PASS"], f"rm -rf {tmp}")
    client.close()

    ok = (
        code == 0
        and "fun_ingreso_sesion" in out
        and "abiertas_final" in out
    )
    print("DEPLOY", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
