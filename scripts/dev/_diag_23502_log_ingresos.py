#!/usr/bin/env python3
"""Diag: columnas NOT NULL + reproducir 23502 en fun_registrar_ingreso_manual."""
from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
for raw in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    k, _, v = line.partition("=")
    os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

try:
    import psycopg2
except ImportError:
    import subprocess

    subprocess.check_call(
        [sys.executable, "-m", "pip", "install", "psycopg2-binary", "-q"]
    )
    import psycopg2

DOC = os.environ.get("DIAG_DOC", "1007692289")


def main() -> int:
    conn = psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"],
        sslmode=os.environ.get("DB_SSLMODE", "require"),
    )
    cur = conn.cursor()
    print("HOST", os.environ["DB_HOST"], "DB", os.environ["DB_NAME"])

    cur.execute(
        """
        SELECT column_name, is_nullable, column_default
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_log_ingresos'
           AND is_nullable = 'NO'
         ORDER BY ordinal_position
        """
    )
    print("=== NOT NULL ===")
    for row in cur.fetchall():
        print(row)

    cur.execute(
        """
        SELECT tgname
          FROM pg_trigger
         WHERE tgrelid = 'public.tab_log_ingresos'::regclass
           AND NOT tgisinternal
        """
    )
    print("=== TRIGGERS ===", [r[0] for r in cur.fetchall()])

    cur.execute(
        """
        SELECT oid::regprocedure::text
          FROM pg_proc
         WHERE proname = 'fun_insert_log_ingreso'
         ORDER BY 1
        """
    )
    print("=== FUN INSERT ===")
    for row in cur.fetchall():
        print(row[0])

    cur.execute("SET app.usuario = 'porteria'")
    conn.commit()
    try:
        cur.execute(
            """
            SELECT fun_registrar_ingreso_manual(
                %s::NUMERIC, 'CC'::VARCHAR, 2::NUMERIC,
                'TEST'::VARCHAR, 'SMOKE'::VARCHAR,
                1::NUMERIC, NULL::TEXT, 3::DECIMAL, FALSE::BOOLEAN,
                NULL::VECTOR, NULL::BYTEA
            )
            """,
            (DOC,),
        )
        print("REGISTER_OK", cur.fetchone())
        conn.rollback()
    except Exception as exc:  # noqa: BLE001 — diag
        print("REGISTER_FAIL", exc)
        conn.rollback()

    cur.execute(
        """
        SELECT id_aprendiz, id_ficha, ind_etdo_formacion
          FROM tab_aprendices
         WHERE id_aprendiz = %s::NUMERIC
        """,
        (DOC,),
    )
    print("=== APRENDIZ ===", cur.fetchone())
    conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
