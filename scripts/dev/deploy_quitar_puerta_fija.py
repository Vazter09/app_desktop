#!/usr/bin/env python3
"""Quita puerta fija de ingreso_service live (debe usarse la marcada 1/2)."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
SVC = "/var/www/html/smartcset/src/backend/services/porteria/ingreso_service.php"
PREP = "/var/www/html/smartcset/src/backend/api/porteria_prepare.php"


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


BLOCK = """    $puertaFija = smartcsetPuertaFijaSesion();
    if ($puertaFija > 0) {
        $puerta = $puertaFija;
    }
"""


def main() -> int:
    env = load_env()
    password = env.get("SERVER_PASS", "")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.111"),
        username=env.get("SERVER_USER", ""),
        password=password,
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    sftp = client.open_sftp()
    tmp = f"/tmp/ingreso_nopuerta_{int(time.time())}.php"
    with sftp.open(SVC, "r") as fh:
        text = fh.read().decode("utf-8")
    if BLOCK not in text:
        print("FAIL bloque puerta fija no encontrado")
        print(text[text.find("$puerta"):text.find("$puerta")+400])
        client.close()
        return 1
    with sftp.open(tmp, "w") as fh:
        fh.write(text.replace(BLOCK, "", 1).encode("utf-8"))
    with sftp.open(PREP, "r") as fh:
        prep = fh.read().decode("utf-8")
    prep2 = prep.replace("smartcsetPuertaFijaSesion()", "0")
    tmp2 = f"/tmp/prep_nopuerta_{int(time.time())}.php"
    with sftp.open(tmp2, "w") as fh:
        fh.write(prep2.encode("utf-8"))
    sftp.close()
    code, out = sudo_bash(
        client,
        password,
        f"cp -f {tmp} {SVC} && cp -f {tmp2} {PREP} && grep -n PuertaFija {SVC} {PREP} || echo NO_FIJA && echo DEPLOY9_OK",
    )
    print(out)
    client.close()
    return 0 if "DEPLOY9_OK" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
