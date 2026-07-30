#!/usr/bin/env python3
"""Alinea registro de ingreso: ingreso_service.php (11 params) + función PL/pgSQL.

Causa: prepare.php en servidor tiene 11 placeholders; ingreso_service antiguo
enviaba 9 → 'bind message supplies 9 parameters, but prepared statement requires 11'.
"""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
FILES = [
    "backend/services/porteria/ingreso_service.php",
    "backend/core/prepare.php",
    "database/functions/porteria/fun_registrar_ingreso_manual.sql",
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
            if idle > 700:
                break
            time.sleep(0.05)
    code = channel.recv_exit_status() if channel.exit_status_ready() else 1
    text = "\n".join(
        ln
        for ln in out_buf.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )
    return code, text


def main() -> int:
    env = load_env()
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    host = env.get("SERVER_HOST", env.get("DB_HOST", "10.5.213.103"))
    client.connect(
        hostname=host,
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )

    remote_tmp = f"/tmp/fix_ingreso_params_{int(time.time())}"
    sudo_bash(client, env["SERVER_PASS"], f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}")

    sftp = client.open_sftp()
    for rel in FILES:
        name = Path(rel).name
        sftp.put(str(ROOT / rel), f"{remote_tmp}/{name}")
        print(f"OK tmp {rel}")
    sftp.close()

    # Copiar PHP al document root
    php_copy = (
        f"cp -f {remote_tmp}/ingreso_service.php {REMOTE_ROOT}/backend/services/porteria/ingreso_service.php && "
        f"cp -f {remote_tmp}/prepare.php {REMOTE_ROOT}/backend/core/prepare.php && "
        f"chown www-data:www-data {REMOTE_ROOT}/backend/services/porteria/ingreso_service.php "
        f"{REMOTE_ROOT}/backend/core/prepare.php && "
        f"echo PHP_DEPLOYED && "
        f"grep -n 'VECTOR.*BYTEA\\|huellaBytea\\|stmtFunRegistrar->execute' "
        f"{REMOTE_ROOT}/backend/services/porteria/ingreso_service.php | head -20 && "
        f"grep -n 'fun_registrar_ingreso_manual' {REMOTE_ROOT}/backend/core/prepare.php | head -5"
    )
    _, out_php = sudo_bash(client, env["SERVER_PASS"], php_copy)
    print(out_php)

    # Aplicar SQL en DB_HOST del .env LOCAL (103) y también en DB de Apache
    # (login/ingreso web usan Apache .env; pueden diferir).
    apply_sql = r"""
set -e
TMP=__TMP__
ENV_LOCAL_HOST=__DB_HOST__
ENV_LOCAL_NAME=__DB_NAME__
ENV_LOCAL_USER=__DB_USER__
ENV_LOCAL_PASS=__DB_PASS__
ENV_LOCAL_PORT=__DB_PORT__
ENV_LOCAL_SSL=__DB_SSL__

apply_one() {
  local label="$1" host="$2" port="$3" user="$4" pass="$5" name="$6" ssl="$7"
  echo "=== APPLY SQL on $label ($host/$name) ==="
  export PGPASSWORD="$pass" PGSSLMODE="${ssl:-require}"
  psql -h "$host" -p "${port:-5432}" -U "$user" -d "$name" -P pager=off -v ON_ERROR_STOP=1 \
    -f "$TMP/fun_registrar_ingreso_manual.sql"
  echo "=== FIRMAS $label ==="
  psql -h "$host" -p "${port:-5432}" -U "$user" -d "$name" -P pager=off -c \
    "SELECT oid::regprocedure::text FROM pg_proc WHERE proname='fun_registrar_ingreso_manual' ORDER BY 1;"
}

apply_one LOCAL_ENV "$ENV_LOCAL_HOST" "$ENV_LOCAL_PORT" "$ENV_LOCAL_USER" "$ENV_LOCAL_PASS" "$ENV_LOCAL_NAME" "$ENV_LOCAL_SSL"

ENVF=/var/www/html/smartcset/.env
strip_val() { printf '%s' "$1" | tr -d '\r' | tr -d '"' | tr -d "'"; }
AH=$(strip_val "$(grep -E '^DB_HOST=' "$ENVF" | head -1 | cut -d= -f2-)")
AN=$(strip_val "$(grep -E '^DB_NAME=' "$ENVF" | head -1 | cut -d= -f2-)")
AU=$(strip_val "$(grep -E '^DB_USER=' "$ENVF" | head -1 | cut -d= -f2-)")
AP=$(strip_val "$(grep -E '^DB_PASS=' "$ENVF" | head -1 | cut -d= -f2-)")
AO=$(strip_val "$(grep -E '^DB_PORT=' "$ENVF" | head -1 | cut -d= -f2-)")
AS=$(strip_val "$(grep -E '^DB_SSLMODE=' "$ENVF" | head -1 | cut -d= -f2-)")
if [ "$AH" != "$ENV_LOCAL_HOST" ] || [ "$AN" != "$ENV_LOCAL_NAME" ]; then
  apply_one APACHE_ENV "$AH" "$AO" "$AU" "$AP" "$AN" "$AS"
else
  echo "=== APACHE DB same as LOCAL .env — skip duplicate ==="
fi

# Contar placeholders en prepare remoto vs execute args (aprox)
echo "=== PLACEHOLDERS prepare.php ==="
php -r '$s=file_get_contents("/var/www/html/smartcset/backend/core/prepare.php"); if(preg_match("/fun_registrar_ingreso_manual\(\s*(.*?)\s*\)/s",$s,$m)){echo substr_count($m[1],"?")," placeholders\n";}'
echo "=== execute array lines in ingreso_service ==="
sed -n '119,131p' /var/www/html/smartcset/backend/services/porteria/ingreso_service.php
rm -rf "$TMP"
echo OK_INGRESO_PARAMS_FIXED
"""
    apply_sql = (
        apply_sql.replace("__TMP__", remote_tmp)
        .replace("__DB_HOST__", env["DB_HOST"])
        .replace("__DB_NAME__", env["DB_NAME"])
        .replace("__DB_USER__", env["DB_USER"])
        .replace("__DB_PASS__", env["DB_PASS"])
        .replace("__DB_PORT__", env.get("DB_PORT", "5432"))
        .replace("__DB_SSL__", env.get("DB_SSLMODE", "require"))
    )

    run_sh = f"{remote_tmp}/run.sh"
    sftp = client.open_sftp()
    with sftp.file(run_sh, "w") as fh:
        fh.write("#!/bin/bash\n" + apply_sql)
    sftp.close()

    code, out = sudo_bash(client, env["SERVER_PASS"], f"bash {run_sh}")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_INGRESO_PARAMS_FIXED" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
