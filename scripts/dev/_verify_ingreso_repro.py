#!/usr/bin/env python3
"""Solo reproduce ingreso con SET app.usuario (verificación post-fix)."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE = "/var/www/html/smartcset/scripts/dev/_repro_ingreso.sql"
DB = "db_smartcset2"


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        values[k.strip()] = v.strip().strip('"').strip("'")
    return values


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> tuple[int, str]:
    transport = client.get_transport()
    assert transport is not None
    ch = transport.open_session()
    ch.get_pty()
    ch.exec_command("sudo -S bash -lc " + repr(inner))
    time.sleep(0.4)
    if ch.send_ready():
        ch.send(password + "\n")
    buf = b""
    while True:
        if ch.recv_ready():
            buf += ch.recv(8192)
        if ch.recv_stderr_ready():
            buf += ch.recv_stderr(8192)
        if ch.exit_status_ready():
            while ch.recv_ready():
                buf += ch.recv(8192)
            while ch.recv_stderr_ready():
                buf += ch.recv_stderr(8192)
            break
        time.sleep(0.05)
    text = buf.decode("utf-8", errors="replace")
    lines = [
        ln
        for ln in text.splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    ]
    return ch.recv_exit_status(), "\n".join(lines)


REPRO = """
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
    INTO t FROM tab_personas WHERE id_persona = 1092342075;
  IF NOT FOUND THEN RAISE EXCEPTION 'persona no encontrada'; END IF;

  UPDATE tab_log_ingresos
     SET fec_salida = CURRENT_TIMESTAMP + interval '1 second'
   WHERE id_visitante = t.id_persona AND fec_salida = fec_ingreso;

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


def main() -> int:
    env = load_env()
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    sftp = c.open_sftp()
    with sftp.file(REMOTE, "w") as fh:
        fh.write(REPRO)
    sftp.close()
    code, out = sudo_bash(
        c,
        env["SERVER_PASS"],
        f"sudo -u postgres env PAGER=cat psql -d {DB} -P pager=off -v ON_ERROR_STOP=1 -f {REMOTE}",
    )
    print(out)
    print("exit", code)
    c.close()
    if "OK id_ingreso=" in out or "ROLLBACK_DIAG" in out:
        print("SUCCESS")
        return 0
    print("FAIL")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
