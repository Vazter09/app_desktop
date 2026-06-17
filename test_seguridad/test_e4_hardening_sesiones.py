"""Tests del informe REPORTE_E1-E04_HARDENING_SESIONES_SMARTCSET.md.

Premisas principales del informe (cierra A07:2021 - Identification and
Authentication Failures / Session Fixation, y A04:2021 - Insecure
Design / Clickjacking):

1. ``SecurityMiddleware`` está activo en TODO el sistema (no solo en el
   login) y agrega, en cada respuesta:
       - X-Content-Type-Options: nosniff
       - X-Frame-Options: SAMEORIGIN
       - X-XSS-Protection: 1; mode=block
       - Referrer-Policy: strict-origin-when-cross-origin
       - Permissions-Policy: geolocation=(), microphone=(), camera=()
       - Content-Security-Policy (activado en la sesión 2 de E4)
2. La cookie de sesión (``PHPSESSID``) se emite con ``HttpOnly`` y
   ``SameSite=Strict``. En desarrollo (``APP_ENV != production``) NO
   debe llevar ``Secure`` (si la llevara, el navegador no enviaría la
   cookie por HTTP y el login se rompería).
3. El ``PHPSESSID`` cambia tras un login exitoso (mitigación de
   session fixation, vía ``session_regenerate_id(true)``).
4. El flujo login -> dashboard -> logout sigue funcionando con todo lo
   anterior activo.
5. Las páginas de portería (``ingreso``/``salida``) y
   ``cambiar_clave.php`` ya NO tienen JavaScript inline (requisito para
   que ``script-src 'self'`` de la CSP no las rompa).
"""

from __future__ import annotations

import re
import unittest

from common import (
    ADMIN_PASS,
    ADMIN_USER,
    BASE_URL,
    HTTP_TIMEOUT,
    close_stale_session,
    login,
    server_is_up,
)

import requests

# Páginas que deben quedar libres de <script> inline tras el refactor de
# E4 (sesión 1 + sesión 2), para que `script-src 'self'` no las rompa.
PAGINAS_SIN_SCRIPT_INLINE = [
    "/src/modulos/porteria/ingreso/index.php",
    "/src/modulos/porteria/salida/index.php",
    "/src/auth/cambiar_clave.php",
]

# Patrón de un <script> con cuerpo (inline). Un <script src="..."></script>
# externo NO matchea porque exigimos contenido no vacío entre las etiquetas.
SCRIPT_INLINE_RE = re.compile(r"<script(?![^>]*\bsrc=)[^>]*>\s*\S+.*?</script>", re.S)


class TestE4HardeningSesiones(unittest.TestCase):
    """Verifica headers de seguridad, cookies y manejo de sesión."""

    @classmethod
    def setUpClass(cls) -> None:
        if not server_is_up():
            raise unittest.SkipTest(
                f"El servidor de desarrollo no responde en {BASE_URL}. "
                "Levántalo con: php -S localhost:8080"
            )

    def test_headers_de_seguridad_presentes_en_login(self) -> None:
        """La página de login debe traer los headers de SecurityMiddleware."""
        response = requests.get(f"{BASE_URL}/index.php", timeout=HTTP_TIMEOUT)

        headers_esperados = {
            "X-Content-Type-Options": "nosniff",
            "X-Frame-Options": "SAMEORIGIN",
            "X-XSS-Protection": "1; mode=block",
            "Referrer-Policy": "strict-origin-when-cross-origin",
        }
        for header, valor_esperado in headers_esperados.items():
            with self.subTest(header=header):
                self.assertEqual(response.headers.get(header), valor_esperado)

        # Permissions-Policy: no exigimos el valor exacto completo, basta
        # con que exista y restrinja geolocation/microphone/camera.
        permissions_policy = response.headers.get("Permissions-Policy", "")
        self.assertIn("geolocation=()", permissions_policy)
        self.assertIn("microphone=()", permissions_policy)
        self.assertIn("camera=()", permissions_policy)

    def test_csp_activo_y_restringe_script_src_a_self(self) -> None:
        """CSP debe estar presente y exigir script-src 'self' (sesión 2)."""
        response = requests.get(f"{BASE_URL}/index.php", timeout=HTTP_TIMEOUT)
        csp = response.headers.get("Content-Security-Policy")

        self.assertIsNotNone(
            csp, "Falta el header Content-Security-Policy (E4 sesión 2)"
        )
        self.assertIn("default-src 'self'", csp)
        self.assertIn("script-src 'self'", csp)
        # img-src debe permitir data: por las fotos de porteria_foto.php.
        self.assertIn("img-src 'self' data:", csp)

    def test_cookie_session_httponly_y_samesite_strict(self) -> None:
        """PHPSESSID debe llevar HttpOnly y SameSite=Strict.

        En este entorno de desarrollo (APP_ENV != production) NO debe
        llevar `Secure`, porque el servidor de desarrollo es HTTP
        plano: si llevara `Secure`, el navegador descartaría la cookie
        y el login quedaría roto (este fue exactamente el bug que E4
        corrigió).
        """
        response = requests.get(
            f"{BASE_URL}/index.php", timeout=HTTP_TIMEOUT, allow_redirects=False
        )
        set_cookie = response.headers.get("Set-Cookie", "")

        self.assertIn("PHPSESSID", set_cookie)
        self.assertIn("HttpOnly", set_cookie)
        self.assertIn("SameSite=Strict", set_cookie)
        self.assertNotIn(
            "Secure",
            set_cookie,
            "La cookie de sesión lleva 'Secure' en un entorno sin HTTPS; "
            "esto rompería el login (APP_ENV debería ser != production)",
        )

    def test_session_id_cambia_tras_login_exitoso(self) -> None:
        """El PHPSESSID antes y después del login deben ser distintos.

        Esta es la mitigación central de session fixation
        (`session_regenerate_id(true)` tras `password_verify`).
        """
        # Cierra cualquier sesión activa residual de ADMIN_USER dejada por
        # otra suite (p. ej. test_e1_a01_broken_access_control.py), que de
        # lo contrario haría que el login devuelva 200 ("ya tiene una
        # sesión activa") en vez del 302 esperado.
        close_stale_session(ADMIN_USER)

        session = requests.Session()

        # 1. Visitar el login sin autenticarse -> obtiene un SID "anónimo".
        session.get(f"{BASE_URL}/index.php", timeout=HTTP_TIMEOUT)
        sid_antes = session.cookies.get("PHPSESSID")
        self.assertIsNotNone(sid_antes, "No se recibió PHPSESSID inicial")

        # 2. Login exitoso.
        response = session.post(
            f"{BASE_URL}/index.php",
            data={"txt_usuario": ADMIN_USER, "txt_clave": ADMIN_PASS},
            timeout=HTTP_TIMEOUT,
            allow_redirects=False,
        )
        self.assertEqual(
            response.status_code,
            302,
            "Login con credenciales válidas debería redirigir (302) al "
            "dashboard; revisar si hay una sesión activa residual en "
            "tab_sesiones que esté bloqueando el login.",
        )

        sid_despues = session.cookies.get("PHPSESSID")
        self.assertIsNotNone(sid_despues, "No se recibió PHPSESSID tras login")
        self.assertNotEqual(
            sid_antes,
            sid_despues,
            "El PHPSESSID no cambió tras el login (session fixation, A07)",
        )

    def test_flujo_login_dashboard_logout(self) -> None:
        """Flujo completo: login -> dashboard (200) -> logout -> 302."""
        session = login(ADMIN_USER, ADMIN_PASS)

        dashboard = session.get(
            f"{BASE_URL}/src/menu/menu_principal.php", timeout=HTTP_TIMEOUT
        )
        self.assertEqual(dashboard.status_code, 200)

        logout = session.get(
            f"{BASE_URL}/src/auth/logout.php",
            timeout=HTTP_TIMEOUT,
            allow_redirects=False,
        )
        self.assertEqual(logout.status_code, 302)

        # Tras logout, el dashboard debe volver a redirigir al login.
        dashboard_tras_logout = session.get(
            f"{BASE_URL}/src/menu/menu_principal.php",
            timeout=HTTP_TIMEOUT,
            allow_redirects=False,
        )
        self.assertEqual(dashboard_tras_logout.status_code, 302)

    def test_paginas_sin_script_inline(self) -> None:
        """Portería (ingreso/salida) y cambiar_clave no deben tener JS inline.

        Si alguno de estos archivos volviera a tener un <script> con
        código embebido, la CSP `script-src 'self'` lo bloquearía en el
        navegador (rompiendo el wizard de portería en producción) sin
        que el servidor PHP reporte ningún error.
        """
        session = login(ADMIN_USER, ADMIN_PASS)

        for pagina in PAGINAS_SIN_SCRIPT_INLINE:
            with self.subTest(pagina=pagina):
                response = session.get(f"{BASE_URL}{pagina}", timeout=HTTP_TIMEOUT)
                self.assertEqual(response.status_code, 200)
                self.assertIsNone(
                    SCRIPT_INLINE_RE.search(response.text),
                    f"{pagina} contiene un <script> inline; debería estar "
                    "externalizado a js/ para no violar la CSP",
                )


if __name__ == "__main__":
    unittest.main()
