#!/usr/bin/env python3
"""Fix sesión activa desktop en 10.5.213.103:

1) Redeploy fun_ingreso_sesion (reclaim total si ult_ruta=app_desktop)
2) Sube login.php + acceso_sesion.php + PrepareAuthSql.php (origen=desktop)
3) Libera sesiones abiertas de porteria
4) Smoke: dos ingresos desktop seguidos no deben fallar
"""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE = "/var/www/html/smartcset"

SQL_FILE = ROOT / "database/functions/acceso/sesiones/fun_ingreso_sesion.sql"
PHP_FILES = [
    "backend/routers/auth/v1/login.php",
    "backend/core/lib/acceso_sesion.php",
    "backend/core/PrepareAuthSql.php",
    "backend/core/prepare_login.php",
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
    tmp = f"/tmp/fix_sesion_{int(time.time())}"
    sudo_bash(client, env["SERVER_PASS"], f"mkdir -p {tmp} && chmod 777 {tmp}")

    # --- Upload SQL ---
    remote_sql = f"{tmp}/fun_ingreso_sesion.sql"
    sftp.put(str(SQL_FILE), remote_sql)
    print(f"OK SQL {remote_sql}")

    # --- Upload PHP a /tmp y copiar con sudo (www no es escribible por SFTP) ---
    for rel in PHP_FILES:
        name = Path(rel).name
        staging = f"{tmp}/{name}"
        sftp.put(str(ROOT / rel), staging)
        remote = f"{REMOTE}/{rel.replace(chr(92), '/')}"
        code_cp, out_cp = sudo_bash(
            client,
            env["SERVER_PASS"],
            f"cp -f {staging} {remote} && chown www-data:www-data {remote} "
            f"&& chmod 644 {remote} && echo COPIED_{name}",
        )
        print(out_cp)
        if code_cp != 0 or f"COPIED_{name}" not in out_cp:
            sftp.close()
            client.close()
            print(f"FAIL copy {rel}")
            return 1
        print(f"OK PHP {remote}")

    # --- Verify + liberar + smoke SQL ---
    verify = f"{tmp}/verify_fix.sql"
    with sftp.file(verify, "w") as fh:
        fh.write(
            "-- Diagnostico previo\n"
            "SELECT id_sesion, ult_ruta, ip_cliente, fec_inicio\n"
            "FROM tab_sesiones\n"
            "WHERE id_usuario = 'porteria' AND fec_fin IS NULL;\n"
            "\n"
            "SELECT CASE WHEN prosrc LIKE '%app_desktop%'\n"
            "  THEN 'RECLAIM_OK' ELSE 'RECLAIM_MISSING' END AS estado_reclaim\n"
            "FROM pg_proc WHERE proname = 'fun_ingreso_sesion';\n"
            "\n"
            "-- Liberar porteria\n"
            "UPDATE tab_sesiones\n"
            "SET fec_fin = CURRENT_TIMESTAMP,\n"
            "    cod_cierre = 'LOGOUT',\n"
            "    usr_cierre = 'porteria'\n"
            "WHERE id_usuario = 'porteria' AND fec_fin IS NULL;\n"
            "\n"
            "-- Smoke reclaim: dos logins desktop seguidos\n"
            "SELECT fun_ingreso_sesion(\n"
            "  'porteria'::TEXT, '10.0.0.1'::TEXT, 1800, 'app_desktop'::TEXT\n"
            ") AS sesion_1;\n"
            "SELECT fun_ingreso_sesion(\n"
            "  'porteria'::TEXT, '10.0.0.2'::TEXT, 1800, 'app_desktop'::TEXT\n"
            ") AS sesion_2;\n"
            "\n"
            "SELECT COUNT(*) AS abiertas_despues_smoke\n"
            "FROM tab_sesiones\n"
            "WHERE id_usuario = 'porteria' AND fec_fin IS NULL;\n"
            "\n"
            "-- Limpiar smoke\n"
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
    print("--- DEPLOY FUNCTION ---")
    print(out)
    if code != 0:
        client.close()
        print("FAIL deploy function")
        return 1

    # Grep remote login for origen desktop
    code_g, out_g = sudo_bash(
        client,
        env["SERVER_PASS"],
        f"grep -n \"origen\\|app_desktop\\|ACCESO_SESION_RUTA_DESKTOP\" "
        f"{REMOTE}/backend/routers/auth/v1/login.php "
        f"{REMOTE}/backend/core/lib/acceso_sesion.php | head -40",
    )
    print("--- PHP GREP ---")
    print(out_g)

    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        "sudo -u postgres env PAGER=cat psql -P pager=off -v ON_ERROR_STOP=1 "
        f"-d db_smartcset2 -f {verify}",
    )
    print("--- VERIFY / SMOKE ---")
    print(out)

    sudo_bash(client, env["SERVER_PASS"], f"rm -rf {tmp}")
    client.close()

    ok = (
        code == 0
        and "RECLAIM_OK" in out
        and "sesion_2" in out
        and "abiertas_final" in out
        and "origen" in out_g
        and "app_desktop" in out_g
    )
    # sesion_2 must have succeeded (no P0001) — ON_ERROR_STOP would fail code
    print("FIX", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
