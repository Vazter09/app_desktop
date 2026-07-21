#!/usr/bin/env python3
"""Verifica bloqueo 5 min post-salida (sin ingreso abierto)."""
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
    remote = "/tmp/smoke_post_salida.sql"
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(
            r"""
BEGIN;
SET LOCAL TIME ZONE 'America/Bogota';
SET LOCAL app.usuario = 'porteria';
DO $$
DECLARE
  wid NUMERIC := 1092342075;
  wentrada NUMERIC;
BEGIN
  SELECT id_entrada_centro INTO wentrada FROM tab_entradas_centro ORDER BY 1 LIMIT 1;

  -- Cerrar cualquier abierto de la persona en esta tx
  UPDATE tab_log_ingresos
     SET fec_salida = fec_ingreso + interval '6 minutes'
   WHERE id_visitante = wid
     AND fec_salida = fec_ingreso;

  -- Insertar salida cerrada reciente (hace 10 s)
  INSERT INTO tab_log_ingresos (
      id_visitante, fec_ingreso, fec_salida, id_entrada_centro, id_metodo_aut,
      val_observaciones
  ) VALUES (
      wid,
      CURRENT_TIMESTAMP - interval '6 minutes',
      CURRENT_TIMESTAMP - interval '10 seconds',
      wentrada,
      1,
      'smoke salida reciente'
  );

  BEGIN
    PERFORM fun_insert_log_ingreso(
      wid, 1, wentrada, '{"origen":"smoke"}'::jsonb, 'smoke reingreso'
    );
    RAISE EXCEPTION 'FAIL: debio bloquear por 5 min post-salida';
  EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
      IF position('5 minutos desde la última salida' in SQLERRM) > 0 THEN
        RAISE NOTICE 'OK bloqueo post-salida: %', SQLERRM;
      ELSE
        RAISE EXCEPTION 'FAIL mensaje inesperado: %', SQLERRM;
      END IF;
  END;
END $$;
ROLLBACK;
"""
        )
    sftp.close()
    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        "sudo -u postgres env PAGER=cat psql -P pager=off -v ON_ERROR_STOP=1 "
        f"-d db_smartcset2 -f {remote}",
    )
    print(out)
    client.close()
    ok = code == 0 and "OK bloqueo post-salida" in out
    print("SMOKE", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
