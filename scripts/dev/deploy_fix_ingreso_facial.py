#!/usr/bin/env python3
"""Despliega fix ingreso facial vía un script bash remoto + psql.

Uso: python scripts/dev/deploy_fix_ingreso_facial.py
"""
from __future__ import annotations

import sys
import time
from pathlib import Path

try:
    import paramiko
except ImportError:
    print("FAIL: falta paramiko")
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[2]
REMOTE_ROOT = "/var/www/html/smartcset"
DEFAULT_HOST = "10.5.213.103"
DB_NAME = "db_smartcset2"

SQL_FILES = [
    "database/migrations/ensure_seq_log_ingresos.sql",
    "database/migrations/add_val_datos_origen_tab_log_ingresos.sql",
    "database/migrations/ensure_tri_act_tabla_log_ingresos.sql",
    "database/migrations/migrate_biometria_a_tab_personas.sql",
    "database/functions/porteria/fun_insert_log_ingreso.sql",
    "database/functions/porteria/fun_update_persona_tras_ingreso.sql",
    "database/functions/porteria/fun_registrar_ingreso_manual.sql",
    "database/functions/porteria/retrasos_comite/fun_verify_retardo_aprendiz.sql",
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
            if idle > 600:  # ~30s
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
    host = env.get("SERVER_HOST", DEFAULT_HOST)
    user = env.get("SERVER_USER", "")
    password = env.get("SERVER_PASS", "")
    if not user or not password:
        print("FAIL: SERVER_USER/SERVER_PASS en .env")
        return 1

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"Conectando a {user}@{host}...")
    client.connect(
        hostname=host,
        username=user,
        password=password,
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    sftp = client.open_sftp()

    for rel in SQL_FILES:
        local = ROOT / rel
        remote = f"{REMOTE_ROOT}/{rel}"
        ensure_remote_dir(sftp, str(Path(remote).parent).replace("\\", "/"))
        print(f"Upload {rel}")
        sftp.put(str(local), remote)

    remote_repro = f"{REMOTE_ROOT}/scripts/dev/_repro_ingreso.sql"
    ensure_remote_dir(sftp, f"{REMOTE_ROOT}/scripts/dev")
    repro = """
SET search_path TO public;
SET app.usuario = 'porteria';
DO $$
DECLARE
  t RECORD;
  vec text := '';
  i int;
  new_id int;
BEGIN
  SELECT id_persona, id_tipo_docum, id_tipo_persona, nom_persona, ape_persona
    INTO t
    FROM tab_personas
   WHERE id_persona = 1092342075;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'persona 1092342075 no encontrada';
  END IF;

  UPDATE tab_log_ingresos
     SET fec_salida = CURRENT_TIMESTAMP + interval '1 second'
   WHERE id_visitante = t.id_persona
     AND fec_salida = fec_ingreso;

  vec := '[';
  FOR i IN 1..128 LOOP
    IF i > 1 THEN vec := vec || ','; END IF;
    vec := vec || '0.01';
  END LOOP;
  vec := vec || ']';

  new_id := fun_registrar_ingreso_manual(
    t.id_persona, t.id_tipo_docum, t.id_tipo_persona,
    t.nom_persona, t.ape_persona,
    1::numeric, 'diag_fix_ingreso', 4::numeric, FALSE,
    vec::vector, NULL::bytea
  );
  RAISE NOTICE 'OK id_ingreso=%', new_id;
  RAISE EXCEPTION 'ROLLBACK_DIAG';
END $$;
"""
    with sftp.file(remote_repro, "w") as fh:
        fh.write(repro)

    remote_sh = f"{REMOTE_ROOT}/scripts/dev/_run_fix_ingreso.sh"
    lines = [
        "#!/bin/bash",
        "set -euo pipefail",
        f"DB={DB_NAME}",
        "export PAGER=cat",
        "export PGOPTIONS=\"-c search_path=public\"",
        'echo "=== ANTES ==="',
        'sudo -u postgres env PAGER=cat psql -d "$DB" -P pager=off -c "SELECT to_regclass(\'public.tab_log_ingresos\');"',
        'sudo -u postgres env PAGER=cat psql -d "$DB" -P pager=off -c "SELECT column_name FROM information_schema.columns WHERE table_schema=\'public\' AND table_name=\'tab_log_ingresos\' AND column_name=\'val_datos_origen\';"',
        'sudo -u postgres env PAGER=cat psql -d "$DB" -P pager=off -c "SELECT oid::regprocedure::text FROM pg_proc WHERE proname IN (\'fun_insert_log_ingreso\',\'fun_registrar_ingreso_manual\',\'fun_verify_retardo_aprendiz\') ORDER BY 1;"',
    ]
    for rel in SQL_FILES:
        path = f"{REMOTE_ROOT}/{rel}"
        lines.append(f'echo "=== APPLY {rel} ==="')
        lines.append(
            f'sudo -u postgres env PAGER=cat psql -d "$DB" -P pager=off -v ON_ERROR_STOP=1 -f "{path}"'
        )
    lines += [
        'echo "=== REPRO ==="',
        "set +e",
        f'sudo -u postgres env PAGER=cat psql -d "$DB" -P pager=off -v ON_ERROR_STOP=1 -f "{remote_repro}"',
        "REPRO_RC=$?",
        "set -e",
        'echo "=== DESPUES ==="',
        'sudo -u postgres env PAGER=cat psql -d "$DB" -P pager=off -c "SELECT column_name FROM information_schema.columns WHERE table_schema=\'public\' AND table_name=\'tab_log_ingresos\' AND column_name=\'val_datos_origen\';"',
        'sudo -u postgres env PAGER=cat psql -d "$DB" -P pager=off -c "SELECT oid::regprocedure::text FROM pg_proc WHERE proname IN (\'fun_insert_log_ingreso\',\'fun_registrar_ingreso_manual\',\'fun_verify_retardo_aprendiz\') ORDER BY 1;"',
        'echo "REPRO_RC=$REPRO_RC"',
        "exit 0",
    ]
    with sftp.file(remote_sh, "w") as fh:
        fh.write("\n".join(lines) + "\n")
    sftp.close()

    print("Ejecutando script remoto...")
    code, out = sudo_bash(client, password, f"bash {remote_sh}")
    print(out)
    print(f"exit={code}")
    client.close()

    if "OK id_ingreso=" in out or "ROLLBACK_DIAG" in out:
        print("SUCCESS: ingreso se registró (rollback de prueba)")
        return 0
    print("FAIL: no se confirmó ingreso")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
