#!/usr/bin/env python3
"""Restaura reloj America/Bogota en .111 (SQL + .env + prepare live).

No toca foto, modal, puertas ni APIs de porteria.
"""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
SRC = "/var/www/html/smartcset/src"
PREPARE = f"{SRC}/backend/includes/prepare.php"
SQL_LOCAL = ROOT / "database/functions/_helpers/smartcset_now_local.sql"
ENV_PATHS = (
    "/var/www/html/smartcset/.env",
    f"{SRC}/.env",
)
TZ_SNIPPET = """
    $dbTz = defined('DB_TIMEZONE') ? DB_TIMEZONE : 'America/Bogota';
    if (!preg_match('/^[A-Za-z0-9_\\/+-]+$/', (string) $dbTz)) {
        $dbTz = 'America/Bogota';
    }
    $pdo->exec('SET TIME ZONE ' . $pdo->quote($dbTz));
"""


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


def patch_env_text(text: str) -> str:
    lines = []
    seen_db = seen_app = False
    for line in text.splitlines():
        if line.startswith("DB_TIMEZONE="):
            lines.append("DB_TIMEZONE=America/Bogota")
            seen_db = True
        elif line.startswith("APP_TIMEZONE="):
            lines.append("APP_TIMEZONE=America/Bogota")
            seen_app = True
        else:
            lines.append(line)
    if not seen_db:
        lines.append("DB_TIMEZONE=America/Bogota")
    if not seen_app:
        lines.append("APP_TIMEZONE=America/Bogota")
    return "\n".join(lines) + "\n"


def patch_prepare(text: str) -> str:
    if "SET TIME ZONE" in text:
        return text
    marker = "$pdo = Db::connect();"
    if marker in text:
        return text.replace(
            marker,
            marker + "\n" + TZ_SNIPPET,
            1,
        )
    alt = "new PDO("
    idx = text.find(alt)
    if idx < 0:
        return text
    semi = text.find(");", idx)
    if semi < 0:
        return text
    insert_at = semi + 2
    return text[:insert_at] + "\n" + TZ_SNIPPET + text[insert_at:]


def main() -> int:
    env = load_env()
    host = env.get("SERVER_HOST") or "10.5.213.111"
    password = env["SERVER_PASS"]
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=env["SERVER_USER"],
        password=password,
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    sudo_bash(client, password, "chmod 777 /tmp")
    sftp = client.open_sftp()
    remote_sql = "/tmp/smartcset_now_local.sql"
    sftp.put(str(SQL_LOCAL), remote_sql)

    bash = "/tmp/restore_tz_bogota.sh"
    with sftp.file(bash, "w") as fh:
        fh.write(
            "#!/bin/bash\n"
            "set -e\n"
            "echo '=== SQL now_local ==='\n"
            "sudo -u postgres env PAGER=cat psql -P pager=off -v ON_ERROR_STOP=1 "
            "-d db_smartcset2 -f /tmp/smartcset_now_local.sql\n"
            "echo '=== ALTER DATABASE TZ ==='\n"
            "sudo -u postgres env PAGER=cat psql -P pager=off -v ON_ERROR_STOP=1 "
            "-d db_smartcset2 -c "
            "\"ALTER DATABASE db_smartcset2 SET timezone TO 'America/Bogota';\"\n"
            "echo '=== VERIFY ==='\n"
            "sudo -u postgres env PAGER=cat psql -P pager=off -d db_smartcset2 -c "
            "\"SHOW timezone;\"\n"
            "sudo -u postgres env PAGER=cat psql -P pager=off -d db_smartcset2 -c "
            "\"SELECT smartcset_now_local() AS now_local, "
            "CURRENT_TIMESTAMP::timestamp AS cts_sesion, "
            "(CURRENT_TIMESTAMP AT TIME ZONE 'America/Bogota') AS bogota;\"\n"
            "sudo -u postgres env PAGER=cat psql -P pager=off -d db_smartcset2 -c "
            "\"SELECT proname, CASE WHEN prosrc LIKE '%smartcset_now_local%' "
            "THEN 'now_local' WHEN prosrc LIKE '%CURRENT_TIMESTAMP%' "
            "THEN 'CURRENT_TIMESTAMP' ELSE 'other' END AS clock "
            "FROM pg_proc WHERE proname IN ("
            "'fun_insert_log_ingreso','fun_update_log_salida',"
            "'fun_registrar_ingreso_manual','fun_registrar_salida_manual',"
            "'fun_update_persona_tras_ingreso','fun_update_persona_tras_salida'"
            ");\"\n"
            "sudo -u postgres env PAGER=cat psql -P pager=off -d db_smartcset2 -c "
            "\"SELECT id_ingreso, fec_ingreso, fec_salida "
            "FROM tab_log_ingresos ORDER BY id_ingreso DESC LIMIT 3;\"\n"
            "echo '=== PHP grep ==='\n"
            "grep -n 'TIME ZONE\\|new PDO\\|Db::connect' "
            f"{PREPARE} 2>/dev/null | head -20 || true\n"
            "echo DONE\n"
        )
    sftp.close()
    code, out = sudo_bash(client, password, f"bash {bash}")
    print(out)
    if code != 0:
        client.close()
        return 1

    sftp = client.open_sftp()
    for env_path in ENV_PATHS:
        try:
            sftp.stat(env_path)
        except OSError:
            print(f"SKIP env {env_path}")
            continue
        with sftp.file(env_path, "r") as fh:
            original = fh.read().decode("utf-8")
        patched = patch_env_text(original)
        if patched != original:
            tmp = f"/tmp/env_tz_{Path(env_path).name}_{int(time.time())}"
            with sftp.file(tmp, "w") as fh:
                fh.write(patched)
            c2, o2 = sudo_bash(client, password, f"cp -f {tmp} {env_path}")
            print(o2)
            print(f"OK env {env_path}" if c2 == 0 else f"FAIL env {env_path}")
        else:
            print(f"OK env ya Bogota {env_path}")

    with sftp.file(PREPARE, "r") as fh:
        prepare = fh.read().decode("utf-8")
    new_prepare = patch_prepare(prepare)
    if new_prepare == prepare:
        if "SET TIME ZONE" in prepare:
            print("OK prepare ya tiene SET TIME ZONE")
        else:
            print("FAIL prepare: no PDO marker y sin SET TIME ZONE")
            print(prepare[:800])
            sftp.close()
            client.close()
            return 1
    else:
        tmp_php = f"/tmp/prepare_tz_{int(time.time())}.php"
        with sftp.file(tmp_php, "w") as fh:
            fh.write(new_prepare)
        bak = f"{PREPARE}.bak_tz_{int(time.time())}"
        c3, o3 = sudo_bash(
            client,
            password,
            f"cp -f {PREPARE} {bak} && cp -f {tmp_php} {PREPARE} && echo OK_PREPARE",
        )
        print(o3)
        if c3 != 0:
            sftp.close()
            client.close()
            return 1
    sftp.close()
    client.close()
    print("OK timezone America/Bogota restaurado")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
