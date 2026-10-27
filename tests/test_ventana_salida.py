"""Tests: ventana de 1 min ingreso→salida calculada en la app.

Regresión del incidente 2026-10-21: un deploy devolvió la constante PHP
``SALIDA_VENTANA_MINIMA_SEGUNDOS`` a 300 s con la BD ya en 60 s, y la app
anunció «salida en ~4 min». Ver ``ui.facial_modal.segundos_restantes_salida``.
"""
from __future__ import annotations

import unittest

from tests.common import APP_DIR  # noqa: F401 — inserta src/ en sys.path
from ui.facial_modal import VENTANA_1_MIN_S, segundos_restantes_salida


def _consulta(desde: int | None, rest_php: int = 0) -> dict:
    abierto: dict = {"id_ingreso": 1}
    if desde is not None:
        abierto["segundos_desde_ingreso"] = desde
    return {
        "ingreso_abierto": abierto,
        "puede_salir": rest_php <= 0,
        "segundos_restantes_salida": rest_php,
    }


class TestSegundosRestantesSalida(unittest.TestCase):
    def test_ventana_es_1_minuto(self) -> None:
        self.assertEqual(VENTANA_1_MIN_S, 60)

    def test_usa_reloj_de_bd_no_constante_php(self) -> None:
        """PHP en 300 s dice 240 s; la regla real (60 s) deja 40 s."""
        self.assertEqual(segundos_restantes_salida(_consulta(20, 280)), 40)

    def test_ventana_cumplida_aunque_php_diga_que_no(self) -> None:
        self.assertEqual(segundos_restantes_salida(_consulta(70, 230)), 0)

    def test_ingreso_de_dias_previos_sale(self) -> None:
        self.assertEqual(segundos_restantes_salida(_consulta(200_000)), 0)

    def test_sin_campo_usa_resto_php_acotado_a_1_min(self) -> None:
        self.assertEqual(segundos_restantes_salida(_consulta(None, 240)), 60)
        self.assertEqual(segundos_restantes_salida(_consulta(None, 25)), 25)
        self.assertEqual(segundos_restantes_salida(_consulta(None, 0)), 0)

    def test_sin_ingreso_abierto_es_cero(self) -> None:
        self.assertEqual(segundos_restantes_salida({"puede_ingresar": True}), 0)
        self.assertEqual(segundos_restantes_salida(None), 0)

    def test_valor_invalido_no_rompe(self) -> None:
        consulta = _consulta(None, 0)
        consulta["ingreso_abierto"]["segundos_desde_ingreso"] = "x"
        consulta["segundos_restantes_salida"] = "y"
        self.assertEqual(segundos_restantes_salida(consulta), 0)


if __name__ == "__main__":
    unittest.main()
