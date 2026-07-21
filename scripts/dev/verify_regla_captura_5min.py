#!/usr/bin/env python3
"""Verifica firmas de fun_update_log_salida y fun_actualizar_captura_ingreso_abierto."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]


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
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=30,
    )
    sftp = client.open_sftp()
    remote = "/tmp/verify_captura_5min.sql"
    with sftp.file(remote, "w") as fh:
        fh.write(
            "SELECT oid::regprocedure AS firma\n"
            "  FROM pg_proc\n"
            " WHERE proname IN (\n"
            "       'fun_update_log_salida',\n"
            "       'fun_actualizar_captura_ingreso_abierto'\n"
            " )\n"
            " ORDER BY 1;\n"
            "SELECT (position('300' in prosrc) > 0) AS tiene_regla_5min\n"
            "  FROM pg_proc\n"
            " WHERE proname = 'fun_update_log_salida';\n"
        )
    sftp.close()

    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        "sudo -u postgres env PAGER=cat psql -P pager=off -d db_smartcset2 -f "
        + remote,
    )
    print(out)
    client.close()
    return 0 if code == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
