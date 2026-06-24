"""Tests del informe REPORTE_E1-A01_BROKEN_ACCESS_CONTROL_SMARTCSET.md.

Premisa principal del informe (A01:2021 - Broken Access Control):

    8 endpoints de administración de menús/usuarios NO verificaban si el
    usuario autenticado era administrador, permitiendo que cualquier
    usuario autenticado (p. ej. el usuario "porteria") leyera o
    modificara el CRUD de menús, usuarios y permisos.

La corrección agregó la verificación de administrador en los 8 archivos,
pero con DOS patrones distintos según el tipo de archivo (ambos válidos,
ambos cierran A01):

1. **Páginas HTML** (``menus.php``, ``usuarios.php``, ``menu_usuarios.php``,
   ``copiar_menu_usuarios.php``): primero exigen sesión (302 a
   ``index.php`` si no hay sesión) y LUEGO, si hay sesión pero no es
   admin, responden::

       http_response_code(403);
       die('Acceso denegado. Esta sección es exclusiva para administradores.');

2. **Endpoints AJAX/procesadores** (``procesar_perfil.php``,
   ``procesar_permiso.php``, ``procesar_copiar_perfil.php``,
   ``obtener_menus_usuario.php``): exigen sesión Y admin en una sola
   condición::

       if (!isset($_SESSION['id_usuario']) || !usuarioEsAdministrador(...)) {
           http_response_code(403);
           echo json_encode(['...', 'Acceso denegado...', ...]);
           exit;
       }

   Por eso, para estos 4 endpoints, TANTO un visitante sin sesión COMO
   un usuario autenticado no-admin reciben 403 (no hay un 302
   intermedio).

Este archivo verifica, para cada grupo, el comportamiento esperado para
los 3 roles: anónimo, usuario no admin (``porteria``) y administrador
(``admin.smart``).
"""

from __future__ import annotations

import unittest

from common import (
    ADMIN_PASS,
    ADMIN_USER,
    BASE_URL,
    HTTP_TIMEOUT,
    NONADMIN_PASS,
    NONADMIN_USER,
    login,
    server_is_up,
)

import requests

# Patrón 1: páginas HTML, requieren sesión (302 si no hay) y luego
# verifican administrador (403 + texto si no lo es).
PAGINAS_ADMIN = [
    "/src/menu/menus.php",
    "/src/usuarios/usuarios.php",
    "/src/menu/menu_usuarios.php",
    "/src/menu/copiar_menu_usuarios.php",
]

# Patrón 2: endpoints AJAX/procesadores. Sesión y admin se verifican en
# una sola condición -> 403 + JSON tanto para anónimo como para no-admin.
AJAX_ADMIN = [
    "/src/menu/procesar_perfil.php",
    "/src/menu/procesar_permiso.php",
    "/src/menu/procesar_copiar_perfil.php",
    "/src/menu/obtener_menus_usuario.php",
]

MENSAJE_ACCESO_DENEGADO = "Acceso denegado"


class TestE1A01BrokenAccessControl(unittest.TestCase):
    """Verifica que el CRUD de menús/usuarios sea exclusivo de admins."""

    @classmethod
    def setUpClass(cls) -> None:
        if not server_is_up():
            raise unittest.SkipTest(
                f"El servidor de desarrollo no responde en {BASE_URL}. "
                "Levántalo con: php -S localhost:8080"
            )

        # Una sesión por rol, reutilizada en todos los métodos de test
        # (evita hacer login una vez por cada uno de los 8 endpoints).
        cls.admin_session = login(ADMIN_USER, ADMIN_PASS)
        cls.nonadmin_session = login(NONADMIN_USER, NONADMIN_PASS)

    # ------------------------------------------------------------------
    # Patrón 1: páginas HTML (menus.php, usuarios.php, menu_usuarios.php,
    # copiar_menu_usuarios.php)
    # ------------------------------------------------------------------

    def test_paginas_admin_anonimo_redirige_al_login(self) -> None:
        """Sin sesión, las 4 páginas redirigen (302) a index.php."""
        anon_session = requests.Session()
        for endpoint in PAGINAS_ADMIN:
            with self.subTest(endpoint=endpoint):
                response = anon_session.get(
                    f"{BASE_URL}{endpoint}",
                    timeout=HTTP_TIMEOUT,
                    allow_redirects=False,
                )
                self.assertEqual(response.status_code, 302)

    def test_paginas_admin_no_admin_recibe_403(self) -> None:
        """El usuario "porteria" (no admin) recibe 403 + mensaje."""
        for endpoint in PAGINAS_ADMIN:
            with self.subTest(endpoint=endpoint):
                response = self.nonadmin_session.get(
                    f"{BASE_URL}{endpoint}", timeout=HTTP_TIMEOUT
                )
                self.assertEqual(response.status_code, 403)
                self.assertIn(MENSAJE_ACCESO_DENEGADO, response.text)

    def test_paginas_admin_administrador_recibe_200(self) -> None:
        """El administrador puede entrar normalmente (200)."""
        for endpoint in PAGINAS_ADMIN:
            with self.subTest(endpoint=endpoint):
                response = self.admin_session.get(
                    f"{BASE_URL}{endpoint}", timeout=HTTP_TIMEOUT
                )
                self.assertEqual(response.status_code, 200)

    # ------------------------------------------------------------------
    # Patrón 2: endpoints AJAX/procesadores (procesar_perfil.php,
    # procesar_permiso.php, procesar_copiar_perfil.php,
    # obtener_menus_usuario.php)
    # ------------------------------------------------------------------

    def test_ajax_admin_anonimo_recibe_403_json(self) -> None:
        """Sin sesión, los 4 endpoints AJAX responden 403 + JSON."""
        anon_session = requests.Session()
        for endpoint in AJAX_ADMIN:
            with self.subTest(endpoint=endpoint):
                response = anon_session.get(
                    f"{BASE_URL}{endpoint}", timeout=HTTP_TIMEOUT
                )
                self.assertEqual(response.status_code, 403)
                self.assertIn(MENSAJE_ACCESO_DENEGADO, response.text)

    def test_ajax_admin_no_admin_recibe_403_json(self) -> None:
        """El usuario "porteria" (no admin) recibe 403 + JSON."""
        for endpoint in AJAX_ADMIN:
            with self.subTest(endpoint=endpoint):
                response = self.nonadmin_session.get(
                    f"{BASE_URL}{endpoint}", timeout=HTTP_TIMEOUT
                )
                self.assertEqual(response.status_code, 403)
                self.assertIn(MENSAJE_ACCESO_DENEGADO, response.text)

    def test_ajax_admin_administrador_no_recibe_403(self) -> None:
        """El administrador NO debe ser bloqueado por la verificación.

        No exigimos un código 200 exacto: estos endpoints esperan
        parámetros POST/GET adicionales (id_usuario, etc.) que esta
        prueba no envía, por lo que pueden responder con un JSON de
        error de VALIDACIÓN (p. ej. "falta id_usuario"). Lo que importa
        para A01 es que NO sea el 403 de "Acceso denegado" por falta de
        privilegios de administrador.
        """
        for endpoint in AJAX_ADMIN:
            with self.subTest(endpoint=endpoint):
                response = self.admin_session.get(
                    f"{BASE_URL}{endpoint}", timeout=HTTP_TIMEOUT
                )
                self.assertNotEqual(response.status_code, 403)


if __name__ == "__main__":
    unittest.main()
