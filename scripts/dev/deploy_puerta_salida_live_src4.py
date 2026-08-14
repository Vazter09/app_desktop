#!/usr/bin/env python3
"""Copia deps de prepare.php, salida_service y .env al arbol src/ de .111."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
SRC_INC = "/var/www/html/smartcset/src/backend/includes"
SRC_SVC = "/var/www/html/smartcset/src/backend/services/porteria"
SRC_LIBP = "/var/www/html/smartcset/src/backend/_lib_porteria"

UPLOADS = [
    ("backend/core/config.php", f"{SRC_INC}/config.php"),
    ("backend/core/EnvLoader.php", f"{SRC_INC}/EnvLoader.php"),
    ("backend/core/SecurityMiddleware.php", f"{SRC_INC}/SecurityMiddleware.php"),
    ("backend/core/Db.php", f"{SRC_INC}/Db.php"),
    ("backend/core/AppConfig.php", f"{SRC_INC}/AppConfig.php"),
    ("backend/core/ConfigSistemaDefaults.php", f"{SRC_INC}/ConfigSistemaDefaults.php"),
    ("backend/core/PmtrosGralesDefaults.php", f"{SRC_INC}/PmtrosGralesDefaults.php"),
    ("backend/core/helpers.php", f"{SRC_INC}/helpers.php"),
    ("backend/core/lib/acceso_sesion.php", f"{SRC_INC}/lib/acceso_sesion.php"),
    (
        "backend/services/porteria/salida_service.php",
        f"{SRC_SVC}/salida_service.php",
    ),
    (
        "backend/services/porteria/foto_service.php",
        f"{SRC_SVC}/foto_service.php",
    ),
    (
        "backend/services/porteria/biometria_service.php",
        f"{SRC_SVC}/biometria_service.php",
    ),
    ("backend/routers/porteria/_lib/Sync.php", f"{SRC_LIBP}/Sync.php"),
    ("backend/routers/porteria/_lib/Auth.php", f"{SRC_LIBP}/Auth.php"),
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
    remote_tmp = f"/tmp/smartcset_core4_{int(time.time())}"
    sudo_bash(
        client,
        password,
        f"mkdir -p {remote_tmp} {SRC_INC}/lib {SRC_SVC} {SRC_LIBP} && chmod 777 {remote_tmp}",
    )
    copies = [
        "if [ ! -e /var/www/html/smartcset/src/.env ]; then ln -s /var/www/html/smartcset/.env /var/www/html/smartcset/src/.env; fi",
    ]
    for rel, dest in UPLOADS:
        local = ROOT / rel
        if not local.is_file():
            print("MISSING local", rel)
            client.close()
            return 1
        tmp = f"{remote_tmp}/{Path(rel).name}"
        sftp.put(str(local), tmp)
        copies.append(f"cp -f {tmp} {dest}")
        print("stage", rel)
    sftp.close()
    copies.append(f"php -l {SRC_INC}/prepare.php")
    copies.append(f"php -l {SRC_SVC}/salida_service.php")
    copies.append(f"ls {SRC_INC}/lib/acceso_sesion.php {SRC_SVC}/salida_service.php")
    copies.append("echo DEPLOY4_OK")
    code, out = sudo_bash(client, password, " && ".join(copies))
    print(out)
    client.close()
    if code != 0 or "DEPLOY4_OK" not in out:
        print("FAIL deploy4")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
