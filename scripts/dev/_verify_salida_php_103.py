#!/usr/bin/env python3
"""Verifica PHP de salida sincronizado en 10.5.213.103."""
from __future__ import annotations

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


def main() -> int:
    env = load_env()
    host = env.get("SERVER_HOST") or env["DB_HOST"]
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=30,
        allow_agent=False,
        look_for_keys=False,
    )
    checks = [
        (
            "prepare.php",
            r"grep -nE 'id_metodo_salida|fun_registrar_salida_manual' "
            r"/var/www/html/smartcset/backend/core/prepare.php | sed -n '1,8p'",
        ),
        (
            "Payload.php",
            r"grep -nE 'id_metodo_salida|metodo_aut' "
            r"/var/www/html/smartcset/backend/routers/porteria/_lib/Payload.php "
            r"| sed -n '1,10p'",
        ),
        (
            "salida_service.php",
            r"grep -nE 'id_metodo_salida|fun_registrar_salida' "
            r"/var/www/html/smartcset/backend/services/porteria/salida_service.php "
            r"| sed -n '1,10p'",
        ),
    ]
    ok = True
    for label, cmd in checks:
        _stdin, stdout, stderr = client.exec_command(cmd, timeout=25)
        out = stdout.read().decode("utf-8", errors="replace").strip()
        err = stderr.read().decode("utf-8", errors="replace").strip()
        print(f"=== {label} ===")
        print(out or err or "(empty)")
        if not out:
            ok = False
    client.close()
    print("PHP_CHECK_OK" if ok else "PHP_CHECK_FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
