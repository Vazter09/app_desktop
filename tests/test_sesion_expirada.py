"""Tests: sesión caducada en el servidor (sin red, opener simulado).

Regresión del 2026-10-27: el mismo usuario inició sesión en otro equipo,
el servidor respondió 302 → login.php?sesion=invalida y la app mostró al
operario «El servidor redirigió (302)… Location=…». Ahora el operario ve
un mensaje simple y la app vuelve al login (detalle solo en el log).
"""
from __future__ import annotations

import email.message
import io
import unittest
import urllib.error

from tests.common import APP_DIR  # noqa: F401 — inserta src/ en sys.path

# isort: split
from smartcset_client import (
    MSG_SERVIDOR_NO_RESPONDE,
    MSG_SESION_EXPIRADA,
    MSG_SIN_CONEXION,
    SmartcsetApiError,
    SmartcsetClient,
    SmartcsetConnectionError,
    SmartcsetSessionExpired,
)

URL = "https://servidor.test/smartcset"


class _FakeOpener:
    def __init__(self, exc: Exception) -> None:
        self._exc = exc

    def open(self, req, timeout=None):
        raise self._exc


def _http_error(code: int, location: str = "", body: bytes = b"") -> Exception:
    headers = email.message.Message()
    if location:
        headers["Location"] = location
    return urllib.error.HTTPError(
        URL + "/x.php", code, "x", headers, io.BytesIO(body)
    )


class TestSesionExpirada(unittest.TestCase):
    def _client(self, exc: Exception) -> tuple[SmartcsetClient, list]:
        client = SmartcsetClient(URL, verify_tls=False)
        client._opener = _FakeOpener(exc)
        avisos: list = []
        client.on_session_expired = lambda: avisos.append(True)
        return client, avisos

    def test_redirect_a_login_es_sesion_expirada(self) -> None:
        client, avisos = self._client(
            _http_error(302, "/smartcset/login.php?sesion=invalida")
        )
        with self.assertRaises(SmartcsetSessionExpired) as ctx:
            client.catalogos()
        self.assertEqual(str(ctx.exception), MSG_SESION_EXPIRADA)
        self.assertNotIn("302", str(ctx.exception))
        self.assertEqual(avisos, [True])

    def test_401_es_sesion_expirada(self) -> None:
        client, avisos = self._client(
            _http_error(401, body=b'{"ok":false,"error":"Sesion no valida."}')
        )
        with self.assertRaises(SmartcsetSessionExpired):
            client.salidas_hoy()
        self.assertEqual(avisos, [True])

    def test_sesion_expirada_sigue_siendo_api_error(self) -> None:
        """Los ``except SmartcsetApiError`` existentes la siguen atrapando."""
        self.assertTrue(issubclass(SmartcsetSessionExpired, SmartcsetApiError))

    def test_redirect_que_no_es_login_no_muestra_detalle(self) -> None:
        client, avisos = self._client(_http_error(302, "/otra/ruta.php"))
        with self.assertRaises(SmartcsetApiError) as ctx:
            client.catalogos()
        self.assertNotIsInstance(ctx.exception, SmartcsetSessionExpired)
        self.assertEqual(str(ctx.exception), MSG_SERVIDOR_NO_RESPONDE)
        self.assertEqual(avisos, [])

    def test_error_de_negocio_se_muestra_tal_cual(self) -> None:
        client, _ = self._client(
            _http_error(400, body=b'{"ok":false,"error":"Documento invalido."}')
        )
        with self.assertRaises(SmartcsetApiError) as ctx:
            client.catalogos()
        self.assertEqual(str(ctx.exception), "Documento invalido.")

    def test_sin_conexion_mensaje_simple(self) -> None:
        client, _ = self._client(urllib.error.URLError("timed out"))
        with self.assertRaises(SmartcsetConnectionError) as ctx:
            client.catalogos()
        self.assertEqual(str(ctx.exception), MSG_SIN_CONEXION)
        self.assertNotIn("servidor.test", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
