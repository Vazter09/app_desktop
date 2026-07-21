#!/usr/bin/env python3
"""Actualiza DB_TIMEZONE en .env remoto, despliega PHP y migra log_ingresos."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
REMOTE_ENV = f"{REMOTE_ROOT}/.env"


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
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=30,
    )
    sftp = client.open_sftp()

    # 1) Script patch .env
    patch_py = "/tmp/patch_tz_bogota.py"
    with sftp.file(patch_py, "w") as fh:
        fh.write(
            "from pathlib import Path\n"
            f"p = Path({REMOTE_ENV!r})\n"
            "text = p.read_text(encoding='utf-8')\n"
            "lines = []\n"
            "seen_db = seen_app = False\n"
            "for line in text.splitlines():\n"
            "    if line.startswith('DB_TIMEZONE='):\n"
            "        lines.append('DB_TIMEZONE=America/Bogota')\n"
            "        seen_db = True\n"
            "    elif line.startswith('APP_TIMEZONE='):\n"
            "        lines.append('APP_TIMEZONE=America/Bogota')\n"
            "        seen_app = True\n"
            "    else:\n"
            "        lines.append(line)\n"
            "if not seen_db:\n"
            "    lines.append('DB_TIMEZONE=America/Bogota')\n"
            "if not seen_app:\n"
            "    lines.append('APP_TIMEZONE=America/Bogota')\n"
            "p.write_text('\\n'.join(lines) + '\\n', encoding='utf-8')\n"
            "print('OK .env timezone')\n"
        )

    # 2) PHP + migración
    uploads = [
        "backend/core/config.php",
        "backend/core/EnvLoader.php",
        "database/migrations/convert_log_ingresos_utc_to_bogota.sql",
    ]
    for rel in uploads:
        local = ROOT / rel
        remote = f"{REMOTE_ROOT}/{rel.replace(chr(92), '/')}"
        ensure_remote_dir(sftp, str(Path(remote).parent).replace("\\", "/"))
        sftp.put(str(local), remote)
        print(f"OK upload {remote}")

    remote_sql = f"{REMOTE_ROOT}/database/migrations/convert_log_ingresos_utc_to_bogota.sql"
    verify_sql = "/tmp/verify_tz_bogota.sql"
    with sftp.file(verify_sql, "w") as fh:
        fh.write(
            "SHOW timezone;\n"
            "SET TIME ZONE 'America/Bogota';\n"
            "SELECT CURRENT_TIMESTAMP::timestamp AS hora_bogota;\n"
            "SELECT id_ingreso, fec_ingreso, fec_salida\n"
            "  FROM tab_log_ingresos\n"
            " ORDER BY id_ingreso DESC\n"
            " LIMIT 3;\n"
        )
    sftp.close()

    code, out = sudo_bash(client, env["SERVER_PASS"], f"python3 {patch_py}")
    print(out)
    if code != 0:
        client.close()
        return 1

    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        "grep -E '^(DB_TIMEZONE|APP_TIMEZONE)=' " + REMOTE_ENV,
    )
    print(out)

    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        "sudo -u postgres env PAGER=cat psql -P pager=off -v ON_ERROR_STOP=1 "
        f"-d db_smartcset2 -f {remote_sql}",
    )
    print(out)
    if code != 0:
        client.close()
        return 1

    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        "sudo -u postgres env PAGER=cat psql -P pager=off -d db_smartcset2 -f "
        + verify_sql,
    )
    print(out)
    client.close()
    print("OK timezone Bogota")
    return 0 if code == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
