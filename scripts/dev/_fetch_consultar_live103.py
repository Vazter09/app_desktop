#!/usr/bin/env python3
"""Trae consultar ingreso/salida live de .103 (solo lectura)."""
from __future__ import annotations

import os
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "scripts" / "dev" / "_tmp_live103"
REMOTE = "/var/www/html/smartcset/src/api"
FILES = [
    "porteria_ingreso_consultar.php",
    "porteria_salida_consultar.php",
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


def main() -> int:
    env = load_env()
    host = os.environ.get("SERVER_HOST") or "10.5.213.103"
    user = os.environ.get("SERVER_USER") or "adsocset"
    password = os.environ.get("SERVER_PASS") or env.get("SERVER_PASS", "")
    if not password:
        print("FAIL: SERVER_PASS vacio")
        return 1

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
    sftp = client.open_sftp()
    OUT.mkdir(parents=True, exist_ok=True)
    for name in FILES:
        remote = f"{REMOTE}/{name}"
        local = OUT / name
        sftp.get(remote, str(local))
        text = local.read_text(encoding="utf-8", errors="replace")
        print(f"OK {name} bytes={len(text)} foto={('foto_base64' in text)}")
        for i, line in enumerate(text.splitlines()[:40], 1):
            if "require" in line or "foto" in line.lower():
                print(f"  {i}:{line}")
    sftp.close()
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
