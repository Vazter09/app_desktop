"""Diagnóstico: persona 1007692289 e ingresos recientes."""
from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
for line in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
    line = line.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    k, v = line.split("=", 1)
    os.environ.setdefault(k.strip(), v.strip())

try:
    import psycopg2
except ImportError:
    import subprocess

    subprocess.check_call(
        [sys.executable, "-m", "pip", "install", "psycopg2-binary", "-q"]
    )
    import psycopg2

DOC = 1007692289
conn = psycopg2.connect(
    host=os.environ["DB_HOST"],
    port=os.environ.get("DB_PORT", "5432"),
    dbname=os.environ["DB_NAME"],
    user=os.environ["DB_USER"],
    password=os.environ["DB_PASS"],
    sslmode=os.environ.get("DB_SSLMODE", "require"),
)
cur = conn.cursor()

cur.execute(
    """
    SELECT id_persona, nom_persona, ape_persona, id_tipo_persona, id_tipo_docum,
           fec_ultima_entrada, fec_ultima_salida
    FROM tab_personas WHERE id_persona = %s
    """,
    (DOC,),
)
print("PERSONA:", cur.fetchone())

cur.execute(
    """
    SELECT id_ingreso, id_visitante, fec_ingreso, fec_salida, id_metodo_aut,
           usr_insert, id_entrada_centro
    FROM tab_log_ingresos
    WHERE id_visitante = %s
    ORDER BY fec_ingreso DESC
    LIMIT 15
    """,
    (DOC,),
)
print("INGRESOS persona:")
for r in cur.fetchall():
    print(" ", r)

cur.execute(
    """
    SELECT id_ingreso, id_visitante, fec_ingreso, fec_salida, id_metodo_aut,
           usr_insert
    FROM tab_log_ingresos
    WHERE fec_ingreso >= (NOW() AT TIME ZONE 'America/Bogota')::date
    ORDER BY fec_ingreso DESC
    LIMIT 25
    """
)
print("INGRESOS hoy (TZ Bogota date):")
for r in cur.fetchall():
    print(" ", r)

# Novedades si existen
cur.execute(
    """
    SELECT table_name FROM information_schema.tables
    WHERE table_schema='public' AND table_name ILIKE '%novedad%ingreso%'
    """
)
print("TABLAS novedad ingreso:", cur.fetchall())

conn.close()
print("OK")
