#!/usr/bin/env python3
"""Smoke con ingreso abierto sintético (ROLLBACK): UPDATE captura + bloqueo 5 min."""
from __future__ import annotations

import time
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
    sql = r"""
BEGIN;
SET LOCAL app.usuario = 'smoke_test';
DO $$
DECLARE
  wid NUMERIC;
  wid_ing INTEGER;
  wentrada NUMERIC;
  dummy INTEGER;
  vvec VECTOR(128);
BEGIN
  SELECT id_persona, val_patron_facial
    INTO wid, vvec
    FROM tab_personas
   WHERE val_patron_facial IS NOT NULL
   LIMIT 1;

  IF wid IS NULL THEN
    RAISE EXCEPTION 'SKIP: no hay persona con facial';
  END IF;

  SELECT id_entrada_centro INTO wentrada
    FROM tab_entradas_centro
   ORDER BY id_entrada_centro
   LIMIT 1;

  -- Cerrar cualquier abierto previo de esta persona en la tx (solo prueba)
  UPDATE tab_log_ingresos
     SET fec_salida = fec_ingreso + interval '1 second'
   WHERE id_visitante = wid
     AND fec_salida = fec_ingreso;

  INSERT INTO tab_log_ingresos (
      id_visitante, fec_ingreso, fec_salida, id_entrada_centro,
      id_metodo_aut, facial_embedding, val_observaciones
  ) VALUES (
      wid, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, wentrada,
      4, vvec, 'smoke ingreso abierto'
  ) RETURNING id_ingreso INTO wid_ing;

  dummy := fun_actualizar_captura_ingreso_abierto(
      wid, vvec, NULL, 4, 'smoke re-captura'
  );
  IF dummy <> wid_ing THEN
    RAISE EXCEPTION 'UPDATE devolvió % esperado %', dummy, wid_ing;
  END IF;
  RAISE NOTICE 'OK actualizar captura id_ingreso=%', dummy;

  BEGIN
    PERFORM fun_update_log_salida(wid_ing, 'smoke salida temprana');
    RAISE EXCEPTION 'FAIL: salida temprana no bloqueó';
  EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
      RAISE NOTICE 'OK bloqueo 5min: %', SQLERRM;
  END;
END $$;
ROLLBACK;
"""
    remote = "/tmp/smoke_captura_5min_tx.sql"
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(sql)
    sftp.close()

    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        "sudo -u postgres env PAGER=cat psql -P pager=off -v ON_ERROR_STOP=1 "
        "-d db_smartcset2 -f " + remote,
    )
    print(out)
    client.close()
    ok = code == 0 and "OK actualizar captura" in out and "OK bloqueo 5min" in out
    print("SMOKE", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
