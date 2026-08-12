#!/usr/bin/env python3
"""Verifica auditoría por id_usuario (sin literal PORTERIA) en 103."""
from __future__ import annotations

import os
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
    os.environ["PYTHONIOENCODING"] = "utf-8"
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
            "acceso_sesion",
            "grep -n accesoUsuarioAuditoriaSesion "
            "/var/www/html/smartcset/backend/core/lib/acceso_sesion.php; "
            "grep -c PORTERIA "
            "/var/www/html/smartcset/backend/core/lib/acceso_sesion.php || true",
        ),
        (
            "prepare",
            "grep -n accesoUsuarioAuditoriaSesion "
            "/var/www/html/smartcset/backend/core/prepare.php",
        ),
        (
            "middleware",
            "grep -n usr_audit "
            "/var/www/html/smartcset/backend/middleware/require_session_or_device.php",
        ),
    ]
    ok = True
    for label, cmd in checks:
        _i, stdout, _e = client.exec_command(cmd, timeout=20)
        out = stdout.read().decode("utf-8", errors="replace").strip()
        print(f"=== {label} ===")
        print(out or "(empty)")
        if not out:
            ok = False
    client.close()
    print("OK" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
