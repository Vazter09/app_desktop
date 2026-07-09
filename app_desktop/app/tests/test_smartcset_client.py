"""
Tests del cliente HTTP de la app de escritorio (`smartcset_client.py`).

Golpean el backend real (no se mockea la BD ni el servidor — misma regla
que el resto del proyecto, ver `.claude/rules/testing_quality.md`), con
el usuario de desarrollo `porteria`. Cada test que crea datos los limpia
en `tearDown`.

Ejecutar:
    cd app_desktop/app/tests
    python3 -m unittest test_smartcset_client.py -v
"""
from __future__ import annotations

import unittest
import uuid
from urllib.parse import urlparse

from common import (
    BASE_URL,
    NONADMIN_PASS,
    NONADMIN_USER,
    close_stale_session,
    delete_test_persona,
    run_psql,
)

from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError

_LOCAL_HOSTS = {"localhost", "127.0.0.1", "::1"}


def _make_client() -> SmartcsetClient:
    verify_tls = urlparse(BASE_URL).hostname not in _LOCAL_HOSTS
    return SmartcsetClient(BASE_URL, verify_tls=verify_tls)


class TestLogin(unittest.TestCase):
    def setUp(self) -> None:
        close_stale_session(NONADMIN_USER)
        self.client = _make_client()

    def tearDown(self) -> None:
        self.client.logout()

    def test_login_exitoso(self) -> None:
        data = self.client.login(NONADMIN_USER, NONADMIN_PASS)
        self.assertEqual(data["usuario"]["id"], NONADMIN_USER)
        self.assertFalse(data["usuario"]["admin"])

    def test_login_clave_incorrecta(self) -> None:
        with self.assertRaises(SmartcsetApiError):
            self.client.login(NONADMIN_USER, "clave-incorrecta-a-proposito")

    def test_endpoint_protegido_sin_sesion(self) -> None:
        client_sin_login = _make_client()
        with self.assertRaises((SmartcsetApiError, SmartcsetConnectionError)):
            client_sin_login.ingresos_hoy()


class TestPorteriaFlujoReal(unittest.TestCase):
    """Ciclo completo consultar -> registrar ingreso -> listar -> salida,
    contra la BD real, con limpieza garantizada en tearDown."""

    def setUp(self) -> None:
        close_stale_session(NONADMIN_USER)
        self.client = _make_client()
        self.client.login(NONADMIN_USER, NONADMIN_PASS)
        # Documento sintético, no un CC real de nadie (evita colisión con
        # datos reales de personas del SENA en la BD compartida).
        self.documento = f"9{uuid.uuid4().int % 10**8:08d}"

    def tearDown(self) -> None:
        delete_test_persona(self.documento)
        self.client.logout()

    def test_catalogos_disponibles(self) -> None:
        data = self.client.catalogos()
        self.assertIn("tipos_doc", data)
        self.assertIn("tipos_persona", data)
        self.assertIn("entradas", data)
        self.assertTrue(len(data["entradas"]) > 0, "Se necesita al menos 1 entrada configurada")

    def test_ciclo_ingreso_y_salida(self) -> None:
        catalogos = self.client.catalogos()
        entrada_id = catalogos["entradas"][0]["id"]
        tipo_persona_id = catalogos["tipos_persona"][0]["id"]

        consulta = self.client.ingreso_consultar(self.documento, "CC")
        self.assertIsNone(consulta["persona"])
        self.assertTrue(consulta["puede_ingresar"])

        resultado = self.client.ingreso_registrar(
            {
                "tipo_doc": "CC",
                "documento": self.documento,
                "nombres": "Test",
                "apellidos": "AutomatizadoUnitTest",
                "tipo_persona": tipo_persona_id,
                "id_entrada": entrada_id,
                "observaciones": "Test automatizado app_desktop",
                "metodo_aut": 1,
            }
        )
        self.assertIn("id_ingreso", resultado)

        hoy = self.client.ingresos_hoy()
        documentos_hoy = [item["documento"] for item in hoy]
        self.assertIn(self.documento, documentos_hoy)

        consulta_salida = self.client.salida_consultar(self.documento, "CC")
        self.assertTrue(consulta_salida["puede_salir"])

        self.client.salida_registrar(
            {
                "tipo_doc": "CC",
                "documento": self.documento,
                "observaciones": "Cierre test automatizado",
                "metodo_aut": 1,
            }
        )

        consulta_final = self.client.salida_consultar(self.documento, "CC")
        self.assertFalse(consulta_final["puede_salir"])

    def test_entradas_crud_requiere_admin(self) -> None:
        """Congruencia: `porteria` (no-admin) debe recibir el mismo
        rechazo real que en la web — no una restricción inventada en el
        cliente (ver sección 3.1 'Congruencia' de REGLAS_APP_ESCRITORIO_SGI.md)."""
        with self.assertRaises(SmartcsetApiError) as ctx:
            self.client.entrada_guardar(
                {"nombre": "Entrada de test — no debería crearse", "sel_sede": "9309|1"}
            )
        self.assertIn("administrador", str(ctx.exception).lower())


class TestBiometriaFacial(unittest.TestCase):
    """Backend de biometría (tab_enrolamiento_facial + endpoints
    enrolar/identificar), sin cámara — vectores sintéticos de 128 dims
    (dimensión real del modelo SFace, ver ui/motor/embeddings.py)."""

    VECTOR_DIM = 128

    def setUp(self) -> None:
        close_stale_session(NONADMIN_USER)
        self.client = _make_client()
        self.client.login(NONADMIN_USER, NONADMIN_PASS)
        self.documento = f"9{uuid.uuid4().int % 10**8:08d}"

        catalogos = self.client.catalogos()
        self.client.ingreso_registrar(
            {
                "tipo_doc": "CC",
                "documento": self.documento,
                "nombres": "Test",
                "apellidos": "Biometria",
                "tipo_persona": catalogos["tipos_persona"][0]["id"],
                "id_entrada": catalogos["entradas"][0]["id"],
                "observaciones": "setup biometria test",
                "metodo_aut": 1,
            }
        )
        self.client.salida_registrar(
            {"tipo_doc": "CC", "documento": self.documento, "observaciones": "cierre setup", "metodo_aut": 1}
        )

    def tearDown(self) -> None:
        delete_test_persona(self.documento)
        self.client.logout()

    @staticmethod
    def _vector(seed: int) -> list:
        import random

        rng = random.Random(seed)
        return [round(rng.uniform(-1, 1), 4) for _ in range(TestBiometriaFacial.VECTOR_DIM)]

    def test_enrolar_e_identificar_mismo_vector(self) -> None:
        vector = self._vector(1)

        resultado = self.client.biometria_enrolar(self.documento, vector, calidad_facial=90.0)
        self.assertIn("id_enrolamiento", resultado)

        identificado = self.client.biometria_identificar(vector)
        self.assertTrue(identificado["match"])
        self.assertEqual(identificado["persona"]["documento"], self.documento)

    def test_identificar_vector_distinto_no_matchea(self) -> None:
        self.client.biometria_enrolar(self.documento, self._vector(1))

        identificado = self.client.biometria_identificar(self._vector(999))
        self.assertFalse(identificado["match"])
        self.assertIsNone(identificado["persona"])

    def test_enrolar_rechaza_dimension_incorrecta(self) -> None:
        with self.assertRaises(SmartcsetApiError):
            self.client.biometria_enrolar(self.documento, [0.1, 0.2, 0.3])

    def test_ingreso_por_identificacion_usa_metodo_aut_biometrico(self) -> None:
        """Congruencia con Bug histórico (CLAUDE.md): el whitelist de
        método de autenticación debe aceptar el valor biométrico (4), no
        degradarlo silenciosamente a manual (1)."""
        vector = self._vector(7)
        self.client.biometria_enrolar(self.documento, vector)
        identificado = self.client.biometria_identificar(vector)
        self.assertTrue(identificado["match"])

        catalogos = self.client.catalogos()
        self.client.ingreso_registrar(
            {
                "tipo_doc": "CC",
                "documento": self.documento,
                "nombres": identificado["persona"]["nombres"],
                "apellidos": identificado["persona"]["apellidos"],
                "tipo_persona": identificado["persona"]["tipo_persona"],
                "id_entrada": catalogos["entradas"][0]["id"],
                "observaciones": "Identificado por reconocimiento facial.",
                "metodo_aut": 4,
            }
        )

        metodo_real = run_psql(
            "SELECT id_metodo_aut FROM tab_log_ingresos "
            f"WHERE id_visitante = '{self.documento}' ORDER BY fec_ingreso DESC LIMIT 1;"
        )
        self.assertEqual(metodo_real, "4")


if __name__ == "__main__":
    unittest.main()
