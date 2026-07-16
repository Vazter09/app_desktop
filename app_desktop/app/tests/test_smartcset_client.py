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

import base64
import io
import unittest
import uuid
from urllib.parse import urlparse

from PIL import Image

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

    def test_relogin_desktop_sin_logout_previo(self) -> None:
        """Simula cierre accidental: login → logout omitido → segundo login."""
        self.client.login(NONADMIN_USER, NONADMIN_PASS)
        self.client._cookie_jar.clear()
        data = self.client.login(NONADMIN_USER, NONADMIN_PASS)
        self.assertEqual(data["usuario"]["id"], NONADMIN_USER)


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
    """Backend de biometría (tab_personas.val_patron_facial + endpoints
    enrolar/identificar), sin cámara — vectores sintéticos de 128 dims
    (dimensión real del modelo SFace)."""

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

    @staticmethod
    def _foto_base64_sintetica(color: tuple[int, int, int] = (10, 20, 30)) -> str:
        """Imagen JPG mínima válida (1x1 px) — mismo propósito que
        `_vector()`: no depende de cámara real, pero sí pasa la
        validación real del servidor (finfo/MIME en
        BiometriaPhotoService::guardarFoto)."""
        buffer = io.BytesIO()
        Image.new("RGB", (1, 1), color=color).save(buffer, format="JPEG")
        return base64.b64encode(buffer.getvalue()).decode("utf-8")

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
                "embedding": vector,
            }
        )

        metodo_real = run_psql(
            "SELECT id_metodo_aut FROM tab_log_ingresos "
            f"WHERE id_visitante = '{self.documento}' ORDER BY fec_ingreso DESC LIMIT 1;"
        )
        self.assertEqual(metodo_real, "4")

        emb_en_log = run_psql(
            "SELECT CASE WHEN facial_embedding IS NULL THEN 'null' ELSE 'ok' END "
            "FROM tab_log_ingresos "
            f"WHERE id_visitante = '{self.documento}' ORDER BY fec_ingreso DESC LIMIT 1;"
        )
        self.assertEqual(emb_en_log, "ok")

    def test_enrolar_con_foto_guarda_ruta_y_se_recupera_al_identificar(self) -> None:
        """2026-07-09: Opción A (servidor guarda el archivo, la app cachea).
        Verifica: enrolar con foto -> ruta_foto_facial en tab_personas
        -> identificar devuelve foto_base64."""
        vector = self._vector(42)
        foto = self._foto_base64_sintetica()

        self.client.biometria_enrolar(self.documento, vector, calidad_facial=88.0, foto_base64=foto)

        ruta_en_bd = run_psql(
            "SELECT ruta_foto_facial FROM tab_personas "
            f"WHERE id_persona = '{self.documento}';"
        )
        self.assertTrue(ruta_en_bd, "ruta_foto_facial no debe quedar NULL tras enrolar con foto")
        self.assertIn(f"{self.documento}", ruta_en_bd)

        patron = run_psql(
            "SELECT CASE WHEN val_patron_facial IS NULL THEN 'null' ELSE 'ok' END "
            f"FROM tab_personas WHERE id_persona = '{self.documento}';"
        )
        self.assertEqual(patron, "ok")

        identificado = self.client.biometria_identificar(vector)
        self.assertTrue(identificado["match"])
        self.assertTrue(
            identificado.get("foto_base64"),
            "identificar.php debe devolver la foto guardada en el enrolamiento",
        )

    def test_enrolar_sin_foto_no_rompe_identificacion(self) -> None:
        """Congruencia: el flujo debe seguir funcionando si no hay foto
        (ej. cámara sin frame válido al enrolar) — foto_base64 debe venir
        None, no lanzar excepción."""
        vector = self._vector(43)
        self.client.biometria_enrolar(self.documento, vector, calidad_facial=70.0)

        identificado = self.client.biometria_identificar(vector)
        self.assertTrue(identificado["match"])
        self.assertIsNone(identificado.get("foto_base64"))

    def test_enrolar_foto_invalida_es_rechazada(self) -> None:
        """E6 (validación de uploads): base64 que no decodifica a una
        imagen real debe ser rechazado por BiometriaPhotoService, no
        guardado silenciosamente."""
        vector = self._vector(44)
        foto_invalida = base64.b64encode(b"esto no es una imagen").decode("utf-8")

        with self.assertRaises(SmartcsetApiError):
            self.client.biometria_enrolar(self.documento, vector, foto_base64=foto_invalida)

    def test_ingreso_persona_inexistente_con_embedding_crea_novedad(self) -> None:
        """Persona no en tab_personas + embedding → tab_novedades_ingreso
        (no crea persona ni fila en tab_log_ingresos)."""
        doc_fantasma = f"8{uuid.uuid4().int % 10**8:08d}"
        vector = self._vector(77)
        catalogos = self.client.catalogos()

        resultado = self.client.ingreso_registrar(
            {
                "tipo_doc": "CC",
                "documento": doc_fantasma,
                "nombres": "NovedadTest",
                "apellidos": "FacialAuto",
                "tipo_persona": catalogos["tipos_persona"][0]["id"],
                "id_entrada": catalogos["entradas"][0]["id"],
                "observaciones": "novedad facial test",
                "metodo_aut": 4,
                "embedding": vector,
            }
        )
        self.assertIn("id_ingreso", resultado)
        id_novedad = str(resultado["id_ingreso"])

        existe_persona = run_psql(
            f"SELECT COUNT(*) FROM tab_personas WHERE id_persona = '{doc_fantasma}';"
        )
        self.assertEqual(existe_persona, "0")

        existe_log = run_psql(
            f"SELECT COUNT(*) FROM tab_log_ingresos WHERE id_visitante = '{doc_fantasma}';"
        )
        self.assertEqual(existe_log, "0")

        novedad = run_psql(
            "SELECT CASE WHEN val_patron_facial IS NULL THEN 'null' ELSE 'ok' END "
            f"FROM tab_novedades_ingreso WHERE id_novedad = '{id_novedad}';"
        )
        self.assertEqual(novedad, "ok")

        run_psql(f"DELETE FROM tab_novedades_ingreso WHERE id_novedad = '{id_novedad}';")


class TestBiometriaHuella(unittest.TestCase):
    """Huella: plantilla en tab_personas + auditoría en log / novedad."""

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
                "apellidos": "Huella",
                "tipo_persona": catalogos["tipos_persona"][0]["id"],
                "id_entrada": catalogos["entradas"][0]["id"],
                "observaciones": "setup huella test",
                "metodo_aut": 1,
            }
        )
        self.client.salida_registrar(
            {
                "tipo_doc": "CC",
                "documento": self.documento,
                "observaciones": "cierre setup",
                "metodo_aut": 1,
            }
        )

    def tearDown(self) -> None:
        delete_test_persona(self.documento)
        self.client.logout()

    def _huella_b64(self, documento: str) -> str:
        from motor.huella import capturar_template_prueba, template_a_base64

        return template_a_base64(capturar_template_prueba(documento))

    def test_ciclo_enrolar_identificar_huella(self) -> None:
        plantilla = self._huella_b64(self.documento)
        self.client.biometria_huella_enrolar(self.documento, plantilla)
        en_bd = run_psql(
            "SELECT CASE WHEN val_huella_digital IS NULL THEN 'null' ELSE 'ok' END "
            f"FROM tab_personas WHERE id_persona = '{self.documento}';"
        )
        self.assertEqual(en_bd, "ok")

        id_match = self.client.biometria_huella_identificar(plantilla)
        self.assertTrue(id_match["match"])
        self.assertEqual(str(id_match["persona"]["documento"]), self.documento)

    def test_ingreso_por_huella_escribe_template_en_log(self) -> None:
        plantilla = self._huella_b64(self.documento)
        self.client.biometria_huella_enrolar(self.documento, plantilla)
        persona = self.client.biometria_huella_identificar(plantilla)["persona"]
        catalogos = self.client.catalogos()
        self.client.ingreso_registrar(
            {
                "tipo_doc": "CC",
                "documento": self.documento,
                "nombres": persona["nombres"],
                "apellidos": persona["apellidos"],
                "tipo_persona": persona["tipo_persona"],
                "id_entrada": catalogos["entradas"][0]["id"],
                "observaciones": "Identificado por huella.",
                "metodo_aut": 5,
                "huella_template_b64": plantilla,
            }
        )
        metodo = run_psql(
            "SELECT id_metodo_aut FROM tab_log_ingresos "
            f"WHERE id_visitante = '{self.documento}' ORDER BY fec_ingreso DESC LIMIT 1;"
        )
        self.assertEqual(metodo, "5")
        tpl = run_psql(
            "SELECT CASE WHEN huella_template IS NULL THEN 'null' ELSE 'ok' END "
            "FROM tab_log_ingresos "
            f"WHERE id_visitante = '{self.documento}' ORDER BY fec_ingreso DESC LIMIT 1;"
        )
        self.assertEqual(tpl, "ok")

    def test_ingreso_huella_persona_inexistente_crea_novedad(self) -> None:
        doc_fantasma = f"8{uuid.uuid4().int % 10**8:08d}"
        plantilla = self._huella_b64(doc_fantasma)
        catalogos = self.client.catalogos()
        resultado = self.client.ingreso_registrar(
            {
                "tipo_doc": "CC",
                "documento": doc_fantasma,
                "nombres": "NovedadTest",
                "apellidos": "HuellaAuto",
                "tipo_persona": catalogos["tipos_persona"][0]["id"],
                "id_entrada": catalogos["entradas"][0]["id"],
                "observaciones": "novedad huella test",
                "metodo_aut": 5,
                "huella_template_b64": plantilla,
            }
        )
        id_novedad = str(resultado["id_ingreso"])
        self.assertEqual(
            run_psql(
                f"SELECT COUNT(*) FROM tab_personas WHERE id_persona = '{doc_fantasma}';"
            ),
            "0",
        )
        novedad = run_psql(
            "SELECT CASE WHEN val_huella_digital IS NULL THEN 'null' ELSE 'ok' END "
            f"FROM tab_novedades_ingreso WHERE id_novedad = '{id_novedad}';"
        )
        self.assertEqual(novedad, "ok")
        run_psql(f"DELETE FROM tab_novedades_ingreso WHERE id_novedad = '{id_novedad}';")


if __name__ == "__main__":
    unittest.main()
