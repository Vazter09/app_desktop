"""Tests del entregable E3 — Rate limiting + logging de autenticación.

Premisas principales de E3 (§5 del documento de Blindaje Técnico
Inmediato; cierra OWASP A07:2021 - Identification and Authentication
Failures, y aporta a A09:2021 - Security Logging and Monitoring):

1. Cada intento de login (exitoso o fallido) queda registrado en
   ``tab_intentos_login`` con IP, usuario, resultado y — tras el
   enriquecimiento E3 — ``motivo_fallo`` y ``user_agent``.
2. El motivo del fallo se discrimina en tres valores de dominio:
   ``usuario_no_existe``, ``contrasena_incorrecta`` y
   ``usuario_inactivo``. Un intento exitoso guarda ``motivo_fallo`` NULL.
3. Tras ``LOGIN_MAX_INTENTOS`` fallos desde una misma IP dentro de la
   ventana de ``LOGIN_VENTANA_MINUTOS`` minutos, el login se bloquea
   (la función ``fun_verificar_bloqueo_ip`` lanza P0001, que el endpoint
   traduce a un mensaje de bloqueo).
4. El ``user_agent`` del cliente se captura para auditoría forense.

Estos tests golpean el **endpoint real** de login
(``/routers/auth/v1/login.php``, JSON), no la ruta antigua
``/index.php`` que usa ``common.login`` (ver nota de deuda técnica
abajo), y verifican el efecto en la BD con ``run_psql`` (que apunta a la
BD configurada en ``.env`` — así el mismo test valida indistintamente la
BD local o la remota según a cuál apunte el ``.env``).

Nota de deuda técnica: ``common.login()`` postea a ``/index.php`` con
campos de formulario; el login real del sistema es AJAX JSON al endpoint
de arriba. Un futuro refactor de ``common.py`` debería alinear ese
helper; queda fuera del alcance de E3.
"""

from __future__ import annotations

import os
import unittest

import requests

from common import (
    ADMIN_PASS,
    ADMIN_USER,
    close_stale_session,
    load_env,
    run_psql,
)

# El app corre en Apache local (HTTPS, base /smartcset); la BD la decide
# el .env. Configurable por si se prueba contra otra URL base.
LOGIN_BASE = os.environ.get("SMARTCSET_BASE_URL", "https://localhost/smartcset")
LOGIN_URL = f"{LOGIN_BASE}/routers/auth/v1/login.php"

# IP con la que el servidor ve las peticiones locales (loopback). El
# rate limiting es por IP, así que todos los intentos de esta suite se
# contabilizan bajo esta IP.
CLIENT_IP = "127.0.0.1"

# User-Agent distintivo para poder identificar/limpiar las filas de esta
# suite sin tocar auditoría real.
TEST_UA = "E3-test-suite/1.0"

HTTP_TIMEOUT = 10

# Certificado autofirmado en dev: no verificar TLS y silenciar el aviso.
requests.packages.urllib3.disable_warnings()  # type: ignore[attr-defined]


def _env_int(key: str, default: int) -> int:
    try:
        return int(load_env().get(key, str(default)))
    except (ValueError, TypeError):
        return default


LOGIN_MAX_INTENTOS = _env_int("LOGIN_MAX_INTENTOS", 5)
LOGIN_VENTANA_MINUTOS = _env_int("LOGIN_VENTANA_MINUTOS", 15)


def _login_endpoint_up() -> bool:
    try:
        requests.get(LOGIN_BASE, timeout=HTTP_TIMEOUT, verify=False)
        return True
    except requests.exceptions.ConnectionError:
        return False


def _post_login(usuario: str, clave: str) -> requests.Response:
    """POST JSON al endpoint real de login con el User-Agent de prueba."""
    return requests.post(
        LOGIN_URL,
        json={"usuario": usuario, "clave": clave},
        headers={"User-Agent": TEST_UA},
        timeout=HTTP_TIMEOUT,
        verify=False,
        allow_redirects=False,
    )


def _limpiar_ip() -> None:
    """Borra los intentos de la IP de prueba dentro de la ventana.

    El bloqueo cuenta TODOS los intentos fallidos de la IP en la ventana;
    para que cada test parta de un contador limpio se eliminan las filas
    de ``CLIENT_IP``. Es limpieza de entorno de pruebas (misma filosofía
    que ``close_stale_session``), pensada para BD de laboratorio.
    """
    try:
        run_psql(
            "DELETE FROM tab_intentos_login "
            f"WHERE ip_cliente = '{CLIENT_IP}';"
        )
    except RuntimeError:
        pass


class TestE3RateLimiting(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if not _login_endpoint_up():
            raise unittest.SkipTest(
                f"El servidor no responde en {LOGIN_BASE}. "
                "Levanta Apache (sudo systemctl start apache2) o define "
                "SMARTCSET_BASE_URL."
            )

    def setUp(self) -> None:
        # Contador de rate limiting limpio antes de cada test.
        _limpiar_ip()

    @classmethod
    def tearDownClass(cls) -> None:
        # No dejar ruido de la suite en la tabla de auditoría.
        _limpiar_ip()

    def test_registro_motivo_usuario_no_existe(self) -> None:
        """Un intento con usuario inexistente registra el motivo correcto."""
        _post_login("noexiste_e3", "cualquier")
        fila = run_psql(
            "SELECT motivo_fallo, user_agent FROM tab_intentos_login "
            "WHERE id_usuario = 'noexiste_e3' "
            "ORDER BY fec_intento DESC LIMIT 1;"
        )
        self.assertIn("usuario_no_existe", fila)
        self.assertIn(TEST_UA, fila, "El user_agent debe quedar registrado.")

    def test_registro_motivo_contrasena_incorrecta(self) -> None:
        """Usuario válido con clave errónea registra 'contrasena_incorrecta'."""
        _post_login(ADMIN_USER, "clave_totalmente_erronea")
        motivo = run_psql(
            "SELECT motivo_fallo FROM tab_intentos_login "
            f"WHERE id_usuario = '{ADMIN_USER}' AND ind_exitoso = FALSE "
            "ORDER BY fec_intento DESC LIMIT 1;"
        )
        self.assertEqual(motivo, "contrasena_incorrecta")

    def test_login_exitoso_registra_sin_motivo(self) -> None:
        """Login válido registra ind_exitoso=TRUE y motivo NULL."""
        close_stale_session(ADMIN_USER)
        resp = _post_login(ADMIN_USER, ADMIN_PASS)
        self.assertEqual(resp.status_code, 200)
        self.assertTrue(
            resp.json().get("ok"),
            f"El login de {ADMIN_USER} debería ser exitoso: {resp.text}",
        )
        fila = run_psql(
            "SELECT ind_exitoso, COALESCE(motivo_fallo, 'NULL') "
            "FROM tab_intentos_login "
            f"WHERE id_usuario = '{ADMIN_USER}' AND ind_exitoso = TRUE "
            "ORDER BY fec_intento DESC LIMIT 1;"
        )
        self.assertIn("t", fila)
        self.assertIn("NULL", fila, "Un login exitoso no debe tener motivo.")
        # Cerrar la sesión creada para no dejar estado.
        close_stale_session(ADMIN_USER)

    def test_bloqueo_tras_n_intentos_fallidos(self) -> None:
        """Tras LOGIN_MAX_INTENTOS fallos, el siguiente intento se bloquea."""
        # Agotar el umbral con intentos fallidos.
        for _ in range(LOGIN_MAX_INTENTOS):
            resp = _post_login(ADMIN_USER, "clave_erronea_para_bloqueo")
            self.assertFalse(resp.json().get("ok"))

        # El intento siguiente debe ser rechazado por bloqueo de IP, incluso
        # con credenciales correctas.
        close_stale_session(ADMIN_USER)
        bloqueado = _post_login(ADMIN_USER, ADMIN_PASS)
        cuerpo = bloqueado.json()
        self.assertFalse(
            cuerpo.get("ok"),
            "Tras superar el umbral, el login debe quedar bloqueado.",
        )
        mensaje = (cuerpo.get("error") or "").lower()
        self.assertTrue(
            any(t in mensaje for t in ("intento", "bloque", "espere", "minuto")),
            f"El mensaje de bloqueo no es claro: {cuerpo.get('error')!r}",
        )

    def test_ventana_configurada_es_positiva(self) -> None:
        """Sanidad: los umbrales de .env son valores positivos."""
        self.assertGreaterEqual(LOGIN_MAX_INTENTOS, 1)
        self.assertGreaterEqual(LOGIN_VENTANA_MINUTOS, 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
