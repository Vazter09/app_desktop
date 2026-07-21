#!/usr/bin/env python3
"""Despliega fix salida (CHECK personas) + reglas captura 30s/5min."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE = "/var/www/html/smartcset"

SQL_FILES = [
    "database/functions/porteria/fun_update_persona_tras_salida.sql",
    "database/functions/porteria/fun_update_log_salida.sql",
    "database/migrations/convert_personas_fec_ultima_utc_to_bogota.sql",
]
PHP_FILES = [
    "backend/services/porteria/consulta_service.php",
    "backend/services/porteria/salida_service.php",
    "backend/routers/porteria/v1/ingreso/consultar.php",
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


def ensure_remote_dir(sftp: paramiko.SFTPClient, remote_dir: str) -> None:
    parts = remote_dir.strip("/").split("/")
    cur = ""
    for part in parts:
        cur += "/" + part
        try:
            sftp.stat(cur)
        except OSError:
            sftp.mkdir(cur)


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> tuple[int, str]:
    transport = client.get_transport()
    assert transport is not None
    channel = transport.open_session()
    channel.get_pty()
    channel.exec_command("sudo -S bash -lc " + repr(inner))
    time.sleep(0.5)
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
            if idle > 800:
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
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=30,
    )
    sftp = client.open_sftp()
    tmp = f"/tmp/fix_salida_{int(time.time())}"
    sudo_bash(client, env["SERVER_PASS"], f"mkdir -p {tmp} && chmod 777 {tmp}")

    for rel in SQL_FILES + PHP_FILES:
        local = ROOT / rel
        if rel.endswith(".sql"):
            remote = f"{tmp}/{Path(rel).name}"
        else:
            remote = f"{REMOTE}/{rel.replace(chr(92), '/')}"
            ensure_remote_dir(sftp, str(Path(remote).parent).replace("\\", "/"))
        sftp.put(str(local), remote)
        print(f"OK {remote}")
    sftp.close()

    for rel in SQL_FILES:
        remote = f"{tmp}/{Path(rel).name}"
        code, out = sudo_bash(
            client,
            env["SERVER_PASS"],
            "sudo -u postgres env PAGER=cat psql -P pager=off -v ON_ERROR_STOP=1 "
            f"-d db_smartcset2 -f {remote}",
        )
        print(out)
        if code != 0:
            client.close()
            return 1

    # Smoke: salida no debe violar CHECK en persona con fechas desfasadas.
    smoke = f"{tmp}/smoke.sql"
    sftp = client.open_sftp()
    with sftp.file(smoke, "w") as fh:
        fh.write(
            "BEGIN;\n"
            "SET LOCAL TIME ZONE 'America/Bogota';\n"
            "DO $$\n"
            "DECLARE wid NUMERIC; wts TIMESTAMP;\n"
            "BEGIN\n"
            "  SELECT id_persona INTO wid FROM tab_personas\n"
            "   WHERE id_persona = 1092342075;\n"
            "  IF wid IS NULL THEN RAISE NOTICE 'SKIP persona'; RETURN; END IF;\n"
            "  -- Simula entrada 'futura' residual y salida actual\n"
            "  UPDATE tab_personas SET\n"
            "    fec_ultima_entrada = CURRENT_TIMESTAMP + interval '3 hours',\n"
            "    fec_ultima_salida  = CURRENT_TIMESTAMP + interval '3 hours'\n"
            "   WHERE id_persona = wid;\n"
            "  PERFORM fun_update_persona_tras_salida(wid);\n"
            "  SELECT fec_ultima_salida INTO wts FROM tab_personas WHERE id_persona = wid;\n"
            "  RAISE NOTICE 'OK salida persona fec_ultima_salida=%', wts;\n"
            "END $$;\n"
            "ROLLBACK;\n"
        )
    sftp.close()
    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        "sudo -u postgres env PAGER=cat psql -P pager=off -v ON_ERROR_STOP=1 "
        f"-d db_smartcset2 -f {smoke}",
    )
    print(out)
    sudo_bash(client, env["SERVER_PASS"], f"rm -rf {tmp}")
    client.close()
    ok = code == 0 and "OK salida persona" in out
    print("SMOKE", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
