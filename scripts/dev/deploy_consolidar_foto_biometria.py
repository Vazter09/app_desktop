#!/usr/bin/env python3
"""Consolida foto en consultar/enrolar/identificar y elimina endpoints duplicados."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
UPLOAD = [
    (
        "backend/routers/porteria/v1/ingreso/consultar.php",
        f"{REMOTE_ROOT}/backend/routers/porteria/v1/ingreso/consultar.php",
    ),
    (
        "backend/routers/porteria/v1/biometria/enrolar.php",
        f"{REMOTE_ROOT}/backend/routers/porteria/v1/biometria/enrolar.php",
    ),
    (
        "backend/routers/porteria/v1/biometria/identificar.php",
        f"{REMOTE_ROOT}/backend/routers/porteria/v1/biometria/identificar.php",
    ),
    (
        "backend/routers/porteria/v1/biometria/huella_identificar.php",
        f"{REMOTE_ROOT}/backend/routers/porteria/v1/biometria/huella_identificar.php",
    ),
    (
        "backend/services/porteria/biometria_photo_service.php",
        f"{REMOTE_ROOT}/backend/services/porteria/biometria_photo_service.php",
    ),
]
REMOVE = [
    f"{REMOTE_ROOT}/backend/routers/porteria/v1/biometria/foto.php",
    f"{REMOTE_ROOT}/backend/routers/porteria/v1/biometria/reparar_foto.php",
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
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    sftp = client.open_sftp()
    for local_rel, remote in UPLOAD:
        local = ROOT / local_rel
        tmp = f"/tmp/{Path(remote).name}.{int(time.time())}"
        sftp.put(str(local), tmp)
        print(
            sudo_bash(
                client,
                env["SERVER_PASS"],
                f"sudo cp {tmp} {remote} && sudo chown www-data:www-data {remote} && rm -f {tmp}",
            )
        )
        print("UP", remote)
    sftp.close()
    for remote in REMOVE:
        print(
            sudo_bash(
                client,
                env["SERVER_PASS"],
                f"sudo rm -f {remote} && echo REMOVED {remote}",
            )
        )
    print(
        sudo_bash(
            client,
            env["SERVER_PASS"],
            "php -l "
            + " ".join(r for _, r in UPLOAD)
            + "; ls -la "
            + f"{REMOTE_ROOT}/backend/routers/porteria/v1/biometria/",
        )
    )
    client.close()
    print("DONE")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
