#!/usr/bin/env python3
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
        k, _, v = line.partition("=")
        values[k.strip()] = v.strip().strip('"').strip("'")
    return values


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> tuple[int, str]:
    transport = client.get_transport()
    assert transport is not None
    ch = transport.open_session()
    ch.get_pty()
    ch.exec_command("sudo -S bash -lc " + repr(inner))
    time.sleep(0.4)
    if ch.send_ready():
        ch.send(password + "\n")
    buf = b""
    while True:
        if ch.recv_ready():
            buf += ch.recv(8192)
        if ch.recv_stderr_ready():
            buf += ch.recv_stderr(8192)
        if ch.exit_status_ready():
            while ch.recv_ready():
                buf += ch.recv(8192)
            while ch.recv_stderr_ready():
                buf += ch.recv_stderr(8192)
            break
        time.sleep(0.05)
    text = buf.decode("utf-8", errors="replace")
    lines = [
        ln
        for ln in text.splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    ]
    return ch.recv_exit_status(), "\n".join(lines)


SQL = r"""
SELECT tgname, pg_get_triggerdef(t.oid, true)
  FROM pg_trigger t
 WHERE t.tgrelid = 'public.tab_log_ingresos'::regclass
   AND NOT t.tgisinternal;

SELECT proname, pg_get_function_identity_arguments(p.oid)
  FROM pg_proc p
 WHERE p.proname IN ('fun_act_tabla','fun_audit_trigger');

-- Probar current_setting
SHOW app.usuario;
SELECT current_setting('app.usuario', true) AS app_usuario;

-- cuerpo fun_act_tabla (primeros 40 lineas via prosrc)
SELECT left(prosrc, 1500) AS src
  FROM pg_proc
 WHERE proname = 'fun_act_tabla';
"""


def main() -> int:
    env = load_env()
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=20,
        allow_agent=False,
        look_for_keys=False,
    )
    sftp = c.open_sftp()
    with sftp.file("/tmp/_tmp_audit.sql", "w") as fh:
        fh.write(SQL)
    sftp.close()
    code, out = sudo_bash(
        c,
        env["SERVER_PASS"],
        "sudo -u postgres env PAGER=cat psql -d db_smartcset2 -P pager=off -f /tmp/_tmp_audit.sql",
    )
    print(out)
    print("exit", code)
    c.close()
    return code


if __name__ == "__main__":
    raise SystemExit(main())
