#!/usr/bin/env python3
"""Despliega validación documento 8–10 + parseo PDF417 a 10.5.213.103."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
FILES = [
    (
        "backend/services/porteria/documento_service.php",
        f"{REMOTE_ROOT}/backend/services/porteria/documento_service.php",
    ),
    (
        "backend/services/porteria/parse_captura_service.php",
        f"{REMOTE_ROOT}/backend/services/porteria/parse_captura_service.php",
    ),
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


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> str:
    transport = client.get_transport()
    assert transport is not None
    channel = transport.open_session()
    channel.get_pty()
    channel.exec_command("sudo -S bash -lc " + repr(inner))
    time.sleep(0.4)
    if channel.send_ready():
        channel.send(password + "\n")
    out = b""
    idle = 0
    while True:
        got = False
        if channel.recv_ready():
            out += channel.recv(8192)
            got = True
            idle = 0
        if channel.recv_stderr_ready():
            out += channel.recv_stderr(8192)
            got = True
            idle = 0
        if channel.exit_status_ready():
            while channel.recv_ready():
                out += channel.recv(8192)
            while channel.recv_stderr_ready():
                out += channel.recv_stderr(8192)
            break
        if not got:
            idle += 1
            if idle > 800:
                break
            time.sleep(0.05)
    return "\n".join(
        ln
        for ln in out.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )


def main() -> int:
    env = load_env()
    host = env.get("SERVER_HOST") or env.get("DB_HOST") or "10.5.213.103"
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
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    sudo_bash(client, password, "chmod 777 /tmp")
    sftp = client.open_sftp()
    for local_rel, remote in FILES:
        local = ROOT / local_rel
        if not local.is_file():
            print(f"FAIL missing local: {local_rel}")
            return 1
        tmp = f"/tmp/{Path(remote).name}.{int(time.time())}"
        sftp.put(str(local), tmp)
        out = sudo_bash(
            client,
            password,
            f"cp {tmp} {remote} && chown www-data:www-data {remote} && rm -f {tmp}",
        )
        if out.strip():
            print(out)
        print("OK", remote)
    sftp.close()

    verify = sudo_bash(
        client,
        password,
        "php -l "
        + " ".join(r for _, r in FILES)
        + " && echo '---' && grep -n 'entre 8 y 10' "
        + FILES[0][1]
        + " && grep -nE 'strlen\\(\\$digits\\) >= 8|RH\\\\s\\*' "
        + FILES[1][1],
    )
    print(verify)
    client.close()
    print("DEPLOY_DONE")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
