#!/usr/bin/env python3
"""Lista core live vs deps y copia lo minimo para login+salida."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
SRC_INC = "/var/www/html/smartcset/src/backend/includes"
SRC_SVC = "/var/www/html/smartcset/src/backend/services/porteria"
NEW_CORE = "/var/www/html/smartcset/backend/core"


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


CORE_FILES = [
    "config.php",
    "EnvLoader.php",
    "SecurityMiddleware.php",
    "Db.php",
    "AppConfig.php",
    "ConfigSistemaDefaults.php",
    "PmtrosGralesDefaults.php",
    "helpers.php",
]


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
    print("LIST NEW CORE")
    print(sudo_bash(client, password, f"ls -l {NEW_CORE}")[1])
    print("LIST SRC INC")
    print(sudo_bash(client, password, f"ls -l {SRC_INC}")[1])
    print("PORTERIA PREPARE REQUIRES")
    print(
        sudo_bash(
            client,
            password,
            "grep -n require /var/www/html/smartcset/src/backend/api/porteria_prepare.php | head -20",
        )[1]
    )
    print("ENV")
    print(
        sudo_bash(
            client,
            password,
            "ls -l /var/www/html/smartcset/.env /var/www/html/smartcset/src/.env 2>&1 | cat",
        )[1]
    )

    sftp = client.open_sftp()
    remote_tmp = f"/tmp/smartcset_core_{int(time.time())}"
    sudo_bash(client, password, f"mkdir -p {remote_tmp}/lib && chmod -R 777 {remote_tmp}")
    copies = [
        f"mkdir -p {SRC_INC}/lib {SRC_SVC}",
        "test -e /var/www/html/smartcset/src/.env || ln -s /var/www/html/smartcset/.env /var/www/html/smartcset/src/.env",
    ]
    for name in CORE_FILES:
        local = ROOT / "backend" / "core" / name
        tmp = f"{remote_tmp}/{name}"
        sftp.put(str(local), tmp)
        copies.append(f"cp -f {tmp} {SRC_INC}/{name}")
        print("stage", name)
    sftp.put(str(ROOT / "backend/core/lib/acceso_sesion.php"), f"{remote_tmp}/lib/acceso_sesion.php")
    copies.append(f"cp -f {remote_tmp}/lib/acceso_sesion.php {SRC_INC}/lib/acceso_sesion.php")
    sftp.put(
        str(ROOT / "backend/services/porteria/salida_service.php"),
        f"{remote_tmp}/salida_service.php",
    )
    copies.append(f"cp -f {remote_tmp}/salida_service.php {SRC_SVC}/salida_service.php")
    sftp.close()
    copies.append(
        "grep -q salida_service.php /var/www/html/smartcset/src/backend/api/porteria_prepare.php "
        "|| sed -i \"s#require_once .*ingreso_service.php.*#&\\nrequire_once dirname(__DIR__) . '/services/porteria/salida_service.php';#\" "
        "/var/www/html/smartcset/src/backend/api/porteria_prepare.php"
    )
    copies.append(f"php -l {SRC_INC}/prepare.php")
    copies.append(f"php -l {SRC_INC}/config.php")
    copies.append(f"php -l {SRC_SVC}/salida_service.php")
    copies.append("echo DEPLOY3_OK")
    code, out = sudo_bash(client, password, " && ".join(copies))
    print(out)
    client.close()
    if code != 0 or "DEPLOY3_OK" not in out:
        print("FAIL deploy3")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
