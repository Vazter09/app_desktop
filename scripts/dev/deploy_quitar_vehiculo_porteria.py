#!/usr/bin/env python3
"""Quita ind_vehiculo del flujo portería (prepare + Payload) en 103."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
FILES = [
    "backend/core/prepare.php",
    "backend/routers/porteria/_lib/Payload.php",
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
            if idle > 500:
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
    host = env.get("SERVER_HOST") or env.get("DB_HOST") or "10.5.213.103"
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )

    remote_tmp = f"/tmp/deploy_no_vehiculo_{int(time.time())}"
    sudo_bash(client, env["SERVER_PASS"], f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}")

    sftp = client.open_sftp()
    for rel in FILES:
        local = ROOT / rel
        sftp.put(str(local), f"{remote_tmp}/{Path(rel).name}")
        print(f"OK tmp {rel}")
    sftp.close()

    parts = []
    for rel in FILES:
        dest = f"{REMOTE_ROOT}/{rel}"
        dest_dir = str(Path(dest).parent).replace("\\", "/")
        parts.append(f"mkdir -p {dest_dir}")
        parts.append(f"cp -f {remote_tmp}/{Path(rel).name} {dest}")
        parts.append(f"chown www-data:www-data {dest}")
        parts.append(f"chmod a+r {dest}")
    parts.append(f"rm -rf {remote_tmp}")
    parts.append(
        "grep -n ind_vehiculo "
        f"{REMOTE_ROOT}/backend/core/prepare.php "
        f"{REMOTE_ROOT}/backend/routers/porteria/_lib/Payload.php "
        "|| echo NO_VEHICULO_OK"
    )
    parts.append("echo OK_DEPLOY_NO_VEHICULO")

    code, out = sudo_bash(client, env["SERVER_PASS"], " && ".join(parts))
    print(out)
    print("exit", code)
    client.close()
    return 0 if "OK_DEPLOY_NO_VEHICULO" in out and "NO_VEHICULO_OK" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
