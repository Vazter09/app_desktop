"""
Utilidades compartidas para los tests de la app de escritorio SGI.

Mismo patrón que `scripts/test_seguridad/common.py` del proyecto
principal: lee credenciales del `.env` real (sin agregar `python-dotenv`,
parseo manual), y expone `run_psql()` para verificar/limpiar el efecto en
la BD real después de cada test — no se mockea la base de datos (regla
del proyecto, ver `.claude/rules/testing_quality.md`).

Estos tests golpean el backend real (`https://localhost/smartcset` por
defecto, código PHP local + BD del servidor de laboratorio, ver acuerdo
de la sesión de este chat) usando el mismo `SmartcsetClient` que usa la
app — no `requests` ni ningún otro cliente HTTP aparte, para que el test
ejercite exactamente el código de producción.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional

# app_desktop/app/ (donde vive smartcset_client.py) al sys.path.
APP_DIR = Path(__file__).resolve().parent.parent
if str(APP_DIR) not in sys.path:
    sys.path.insert(0, str(APP_DIR))


def _find_project_root(start: Path) -> Path:
    for candidate in (start, *start.parents):
        if (candidate / ".env").exists() or (candidate / "CLAUDE.md").exists():
            return candidate
    return start.parents[2]


PROJECT_ROOT = _find_project_root(APP_DIR)

BASE_URL = os.environ.get("SMARTCSET_BASE_URL", "https://localhost/smartcset")

# Credenciales de desarrollo documentadas en CLAUDE.md — mismas que usa
# el resto de la suite de tests del proyecto (scripts/test_seguridad/).
NONADMIN_USER = "porteria"
NONADMIN_PASS = "Porteria2026!"

HTTP_TIMEOUT = 15


def load_env(env_path: Optional[Path] = None) -> dict:
    env_path = env_path or (PROJECT_ROOT / ".env")
    values: dict = {}
    if not env_path.exists():
        return values
    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        values[key.strip()] = value.strip()
    return values


def run_psql(sql: str) -> str:
    """Ejecuta `sql` contra la BD real del `.env` y devuelve stdout."""
    env_vars = load_env()
    pg_env = os.environ.copy()
    pg_env["PGPASSWORD"] = env_vars.get("DB_PASS", "")
    pg_env.setdefault("PGSSLMODE", env_vars.get("DB_SSLMODE", "") or "prefer")

    cmd = [
        "psql",
        "-h", env_vars.get("DB_HOST", "localhost"),
        "-p", env_vars.get("DB_PORT", "5432"),
        "-U", env_vars.get("DB_USER", "postgres"),
        "-d", env_vars.get("DB_NAME", "db_smartcset"),
        "-t", "-A",
        "-c", sql,
    ]
    try:
        result = subprocess.run(
            cmd, env=pg_env, capture_output=True, text=True, timeout=HTTP_TIMEOUT
        )
    except FileNotFoundError as exc:
        raise RuntimeError("psql no está disponible en PATH.") from exc

    if result.returncode != 0:
        raise RuntimeError(f"psql falló: {result.stderr.strip()}")

    return result.stdout.strip()


def close_stale_session(username: str) -> None:
    """Cierra en BD cualquier sesión previa colgada de `username`.

    Mismo problema y misma solución que en
    `scripts/test_seguridad/common.py`: sin esto, una corrida de tests
    interrumpida deja la suite intermitente (el siguiente login falla
    con "Ya tiene una sesión activa").
    """
    try:
        run_psql(
            f"UPDATE tab_sesiones SET fec_fin = CURRENT_TIMESTAMP, "
            f"cod_cierre = 'TEST', usr_cierre = 'test' "
            f"WHERE id_usuario = '{username}' AND fec_fin IS NULL;"
        )
    except RuntimeError:
        pass


def delete_test_persona(documento: str) -> None:
    """Limpia el registro de ingreso + enrolamiento facial + persona de
    prueba creados por un test (orden importa: FK de enrolamiento/ingreso
    hacia persona), más la carpeta de fotos de enrolamiento en filesystem
    (2026-07-09 — Opción A: servidor guarda uploads/biometria/{id}/)."""
    try:
        run_psql(f"DELETE FROM tab_enrolamiento_facial WHERE id_persona = '{documento}';")
        run_psql(f"DELETE FROM tab_log_ingresos WHERE id_visitante = '{documento}';")
        run_psql(f"DELETE FROM tab_personas WHERE id_persona = '{documento}';")
    except RuntimeError:
        pass

    carpeta_fotos = PROJECT_ROOT / "frontend" / "web" / "public" / "uploads" / "biometria" / documento
    shutil.rmtree(carpeta_fotos, ignore_errors=True)
