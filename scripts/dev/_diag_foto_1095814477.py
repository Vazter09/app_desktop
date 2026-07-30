#!/usr/bin/env python3
"""Diag foto facial 1095814477 + sample recientes."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
RUN = r"""#!/bin/bash
set +e
DOC=1095814477
echo '=== PERSONA ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT id_persona, nom_persona, ape_persona, ruta_foto_facial, (val_patron_facial IS NOT NULL) AS tiene_vector, length(ruta_foto_facial::text) AS len_ruta FROM tab_personas WHERE id_persona = $DOC;"
echo '=== ARCHIVO ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -tAc "SELECT ruta_foto_facial FROM tab_personas WHERE id_persona = $DOC;" | while read -r R; do
  R=$(echo "$R" | tr -d '[:space:]')
  echo "ruta=[$R]"
  if [ -n "$R" ]; then
    ls -la "/var/www/html/smartcset/frontend/web/public/$R" 2>&1
    ls -la "/var/www/html/smartcset/$R" 2>&1
  fi
done
echo '=== ULTIMOS LOG ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT id_ingreso, fec_ingreso, fec_salida, id_metodo_aut, (facial_embedding IS NOT NULL) AS emb FROM tab_log_ingresos WHERE id_visitante = $DOC ORDER BY fec_ingreso DESC LIMIT 5;"
echo '=== SIN FOTO CON VECTOR (count) ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT COUNT(*) AS con_vector_sin_ruta FROM tab_personas WHERE val_patron_facial IS NOT NULL AND (ruta_foto_facial IS NULL OR btrim(ruta_foto_facial)='');"
echo '=== sample rutas ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT id_persona, ruta_foto_facial FROM tab_personas WHERE ruta_foto_facial IS NOT NULL ORDER BY fec_update DESC NULLS LAST LIMIT 8;"
echo DONE
"""


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
    remote = f"/tmp/diag_foto_{int(time.time())}.sh"
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(RUN)
    sftp.chmod(remote, 0o755)
    sftp.close()
    print(sudo_bash(client, env["SERVER_PASS"], f"bash {remote}"))
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
