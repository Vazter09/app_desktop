"""Utilidades compartidas para los tests de seguridad de SmartCSET.

Este módulo NO contiene tests por sí mismo. Centraliza:

- La lectura de credenciales/configuración desde el archivo ``.env`` del
  proyecto (para no duplicar usuario/clave de BD en cada archivo de test).
- Un helper para autenticarse en la aplicación vía HTTP (login real,
  igual a lo que hace un navegador).
- Un helper para ejecutar consultas SQL de solo lectura contra la base
  de datos usando ``psql`` (evita depender de psycopg2, que no está
  instalado en este entorno).
- Una comprobación de que el servidor de desarrollo
  (``php -S localhost:8080``) está arriba, para poder saltar (``skip``)
  los tests con un mensaje claro si no lo está, en vez de fallar con un
  error de conexión confuso.

Convención de credenciales de desarrollo (ver CLAUDE.md):
    - ``admin.smart`` / ``AdminSmart2026!``  -> usuario administrador
    - ``porteria``    / ``Porteria2026!``    -> usuario NO administrador
"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path
from typing import Optional

import requests

# Raíz del proyecto: este archivo vive en <raiz>/test_seguridad/common.py
PROJECT_ROOT = Path(__file__).resolve().parent.parent

# URL base del servidor de desarrollo PHP (tools/start_dev.ps1 / php -S).
BASE_URL = os.environ.get("SMARTCSET_BASE_URL", "http://localhost:8080")

# Credenciales de desarrollo documentadas en CLAUDE.md.
ADMIN_USER = "admin.smart"
ADMIN_PASS = "AdminSmart2026!"
NONADMIN_USER = "porteria"
NONADMIN_PASS = "Porteria2026!"

# Tiempo máximo de espera por respuesta HTTP (segundos).
HTTP_TIMEOUT = 10


def load_env(env_path: Optional[Path] = None) -> dict:
    """Lee el archivo ``.env`` del proyecto y lo devuelve como dict.

    No usamos ``python-dotenv`` para no agregar una dependencia nueva:
    el formato del ``.env`` de SmartCSET es simple (``CLAVE=valor``,
    líneas vacías y comentarios con ``#``), así que un parseo manual
    es suficiente y evita instalar paquetes.
    """
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


def server_is_up(base_url: str = BASE_URL) -> bool:
    """Indica si el servidor de desarrollo responde en ``base_url``.

    Se usa en ``setUpClass`` de cada suite para poder hacer
    ``unittest.SkipTest`` con un mensaje claro ("levanta
    ``php -S localhost:8080``") en vez de un traceback de conexión
    rechazada.
    """
    try:
        requests.get(base_url, timeout=HTTP_TIMEOUT)
        return True
    except requests.exceptions.ConnectionError:
        return False


def close_stale_session(username: str) -> None:
    """Cierra en BD cualquier sesión activa previa de ``username``.

    SmartCSET impide un segundo login mientras exista una fila en
    ``tab_sesiones`` con ``fec_fin IS NULL`` para ese usuario (mensaje:
    "Ya tiene una sesión activa en el sistema"). Eso es correcto para un
    usuario real, pero hace que esta suite de tests sea intermitente: si
    una corrida anterior dejó una sesión "abierta" (porque no hizo
    logout explícito), el siguiente ``login()`` recibiría 200 en lugar
    de 302.

    Por eso, antes de cada login de prueba cerramos cualquier sesión
    residual del usuario de prueba. Es una operación de "limpieza de
    entorno de pruebas", no algo que se haga contra producción. Si
    ``psql`` no está disponible, simplemente no hacemos nada (el login
    podría fallar, y el test que lo use fallará con un mensaje claro).
    """
    # username siempre es una de las constantes ADMIN_USER/NONADMIN_USER
    # de este módulo (usuarios fijos de desarrollo), nunca un valor
    # externo: la interpolación aquí no expone una inyección SQL real.
    try:
        run_psql(
            "UPDATE tab_sesiones SET fec_fin = CURRENT_TIMESTAMP, "
            "cod_cierre = 'TEST_SUITE', usr_cierre = 'test_seguridad' "
            f"WHERE id_usuario = '{username}' AND fec_fin IS NULL;"
        )
    except RuntimeError:
        pass


def login(username: str, password: str) -> requests.Session:
    """Inicia sesión real contra ``index.php`` y devuelve la sesión.

    Hace un POST con las credenciales (igual que el formulario de
    login) y devuelve la ``requests.Session`` ya autenticada (con la
    cookie ``PHPSESSID`` correspondiente), lista para reutilizarse en
    peticiones posteriores.

    Antes de autenticarse, cierra cualquier sesión activa residual del
    usuario (ver :func:`close_stale_session`) para que el login no falle
    con "Ya tiene una sesión activa en el sistema" por estado dejado por
    una corrida anterior de esta misma suite.

    No verifica aquí si el login fue exitoso: cada test decide qué
    significa "éxito" para su caso (p. ej. un 302 a
    ``menu_principal.php``).
    """
    close_stale_session(username)

    session = requests.Session()
    session.post(
        f"{BASE_URL}/index.php",
        data={"txt_usuario": username, "txt_clave": password},
        timeout=HTTP_TIMEOUT,
        allow_redirects=False,
    )
    return session


def run_psql(sql: str) -> str:
    """Ejecuta ``sql`` (modo ``-t -A``, salida sin encabezados) y devuelve stdout.

    Usa las credenciales del ``.env`` del proyecto vía la variable de
    entorno ``PGPASSWORD`` (evita escribir la contraseña en la línea de
    comandos, donde quedaría visible en ``ps``).

    Lanza ``RuntimeError`` si ``psql`` no está disponible o si la
    consulta falla, con el ``stderr`` original para facilitar el
    diagnóstico.
    """
    env_vars = load_env()
    pg_env = os.environ.copy()
    pg_env["PGPASSWORD"] = env_vars.get("DB_PASS", "")

    cmd = [
        "psql",
        "-h", env_vars.get("DB_HOST", "localhost"),
        "-p", env_vars.get("DB_PORT", "5432"),
        "-U", env_vars.get("DB_USER", "postgres"),
        "-d", env_vars.get("DB_NAME", "db_smartcset"),
        "-t",  # sin encabezados de columna
        "-A",  # salida sin alinear (más fácil de parsear)
        "-c", sql,
    ]

    try:
        result = subprocess.run(
            cmd, env=pg_env, capture_output=True, text=True, timeout=HTTP_TIMEOUT
        )
    except FileNotFoundError as exc:
        raise RuntimeError(
            "psql no está disponible en PATH; no se puede verificar la BD."
        ) from exc

    if result.returncode != 0:
        raise RuntimeError(f"psql falló: {result.stderr.strip()}")

    return result.stdout.strip()
