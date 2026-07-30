#!/usr/bin/env python3
"""Reproduce registro ingreso 1007692289 + revisar logs Apache."""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "app_desktop" / "app"
sys.path.insert(0, str(APP))

DOC = "1007692289"


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        values[k.strip()] = v.strip().strip('"').strip("'")
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
    from smartcset_client import SmartcsetApiError, SmartcsetClient

    c = SmartcsetClient("https://10.5.213.103/smartcset", verify_tls=False)
    c.login("porteria", "Porteria2026!")
    before = c.ingreso_consultar(DOC, "CC")
    print("BEFORE", json.dumps(before, ensure_ascii=False)[:600])

    persona = before.get("persona") or {}
    payload = {
        "tipo_doc": "CC",
        "documento": DOC,
        "nombres": persona.get("nombres") or "DIEGO",
        "apellidos": persona.get("apellidos") or "TEST",
        "tipo_persona": int(persona.get("tipo_persona") or 2),
        "id_entrada": 1,
        "observaciones": "smoke_diag_ingreso_fail",
        "metodo_aut": 1,
    }
    try:
        res = c.ingreso_registrar(payload)
        print("REGISTER_OK", res)
    except SmartcsetApiError as exc:
        print("REGISTER_FAIL", str(exc))

    after = c.ingreso_consultar(DOC, "CC")
    print("AFTER", json.dumps(after, ensure_ascii=False)[:600])

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
    print(
        sudo_bash(
            client,
            env["SERVER_PASS"],
            "sudo -u postgres psql -d db_smartcset2 -P pager=off -c "
            "\"SELECT id_ingreso, id_visitante, fec_ingreso, fec_salida, "
            "id_metodo_aut, val_observaciones FROM tab_log_ingresos "
            "WHERE id_visitante = 1007692289 ORDER BY fec_ingreso DESC LIMIT 5;\"",
        )
    )
    print(
        sudo_bash(
            client,
            env["SERVER_PASS"],
            "tail -n 80 /var/log/apache2/error.log",
        )
    )
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
