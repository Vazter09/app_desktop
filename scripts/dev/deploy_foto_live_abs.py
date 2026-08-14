#!/usr/bin/env python3
"""Sube solo biometria_photo_service.php al arbol live de .111."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
LIVE = "/var/www/html/smartcset/src/backend"
LOCAL = ROOT / "backend/services/porteria/biometria_photo_service.php"
DEST = f"{LIVE}/services/porteria/biometria_photo_service.php"
FOTOS = "/var/www/html/desktop-smartcset/src/frontend/img/biometria"


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
            if idle > 600:
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
    host = env.get("SERVER_HOST") or "10.5.213.111"
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
    stamp = int(time.time())
    remote_tmp = f"/tmp/biometria_photo_service_{stamp}.php"
    sftp = client.open_sftp()
    sftp.put(str(LOCAL), remote_tmp)
    sftp.close()
    inner = (
        f"ls -ld {FOTOS} ; echo '---SAMPLE---' ; "
        f"ls {FOTOS} | head -8 ; echo '---DEPLOY---' ; "
        f"cp -f {DEST} {DEST}.bak_{stamp} ; "
        f"cp -f {remote_tmp} {DEST} ; "
        f"chown www-data:www-data {DEST} ; chmod a+r {DEST} ; "
        f"grep -n 'LIVE_ABS_IMG_BASE' {DEST} ; "
        f"rm -f {remote_tmp} ; echo OK_FOTO_ABS"
    )
    code, out = sudo_bash(client, env["SERVER_PASS"], inner)
    print(out)
    print("exit", code)
    client.close()
    return 0 if code == 0 and "OK_FOTO_ABS" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
