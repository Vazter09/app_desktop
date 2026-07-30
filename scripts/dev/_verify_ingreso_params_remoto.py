#!/usr/bin/env python3
"""Verifica que prepare.php y ingreso_service.php del servidor estén alineados (11)."""
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


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> str:
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
            if idle > 400:
                break
            time.sleep(0.05)
    return "\n".join(
        ln
        for ln in out_buf.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )


def main() -> int:
    env = load_env()
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("DB_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=20,
        allow_agent=False,
        look_for_keys=False,
    )
    out = sudo_bash(
        client,
        env["SERVER_PASS"],
        "python3 - <<'PY'\n"
        "from pathlib import Path\n"
        "import re\n"
        "prep = Path('/var/www/html/smartcset/backend/core/prepare.php').read_text()\n"
        "m = re.search(r'fun_registrar_ingreso_manual\\(\\s*(.*?)\\s*\\)', prep, re.S)\n"
        "n = m.group(1).count('?') if m else -1\n"
        "svc = Path('/var/www/html/smartcset/backend/services/porteria/ingreso_service.php').read_text()\n"
        "block = re.search(r'\\$stmtFunRegistrar->execute\\(\\[(.*?)\\]\\)', svc, re.S)\n"
        "args = [ln.strip().rstrip(',') for ln in block.group(1).splitlines() if ln.strip()] if block else []\n"
        "print(f'placeholders={n}')\n"
        "print(f'execute_args={len(args)}')\n"
        "print('ALIGNED' if n == len(args) == 11 else 'MISMATCH')\n"
        "for a in args:\n"
        "    print(' ', a)\n"
        "PY",
    )
    print(out)
    client.close()
    return 0 if "ALIGNED" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
