"""Tests unitarios: parseo pistola + validación de campos ingreso."""
from __future__ import annotations

import unittest

from tests.common import APP_DIR  # noqa: F401 — inserta app/ en sys.path
from ui.field_validators import (
    es_documento_valido,
    es_nombre_valido,
    es_token_basura_pdf417,
    filtrar_chars_nombre,
    sanear_documento,
    sanear_nombre,
)
from ui.scan_capture import (
    documento_desde_entrada_campo,
    parse_captura_escaneo,
    trama_pubdsk_incompleta,
    trama_pubdsk_lista,
)


class TestFieldValidators(unittest.TestCase):
    def test_documento_solo_digitos_y_longitud(self) -> None:
        self.assertEqual(sanear_documento("O+12AB34567890XY"), "1234567890")
        self.assertEqual(sanear_documento("12345678901"), "1234567890")
        self.assertFalse(es_documento_valido("O+"))
        self.assertFalse(es_documento_valido("1234567"))
        self.assertTrue(es_documento_valido("12345678"))
        self.assertTrue(es_documento_valido("1234567890"))

    def test_rh_y_sexo_son_basura(self) -> None:
        self.assertTrue(es_token_basura_pdf417("O+"))
        self.assertTrue(es_token_basura_pdf417("o-"))
        self.assertTrue(es_token_basura_pdf417("RH O+"))
        self.assertTrue(es_token_basura_pdf417("A +"))
        self.assertTrue(es_token_basura_pdf417("M"))
        self.assertFalse(es_token_basura_pdf417("OSCAR"))

    def test_sanear_nombre_omite_rh(self) -> None:
        self.assertEqual(sanear_nombre("OSCAR O+"), "OSCAR")
        self.assertEqual(sanear_nombre("O+"), "")
        self.assertEqual(sanear_nombre("MARÍA 123"), "MARÍA")

    def test_filtro_vivo_permite_espacio(self) -> None:
        self.assertEqual(filtrar_chars_nombre("JOSE "), "JOSE ")
        self.assertEqual(filtrar_chars_nombre("JOSE+"), "JOSE")
        self.assertFalse(es_nombre_valido("JOSE2"))


class TestScanCapturePdf417(unittest.TestCase):
    def test_pdf417_no_mete_rh_en_nombres_ni_doc(self) -> None:
        raw = (
            "1098765432@PEREZ@GOMEZ@JUAN@CARLOS@M@O+@01011990"
        )
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.documento, "1098765432")
        self.assertEqual(cap.apellidos, "PEREZ GOMEZ")
        self.assertEqual(cap.nombres, "JUAN CARLOS")
        self.assertNotIn("+", cap.nombres)
        self.assertNotIn("O", cap.documento)

    def test_pdf417_ambos_apellidos_y_nombres(self) -> None:
        """Convención CO: ape1+ape2 → apellidos; nom1+nom2 → nombres."""
        raw = (
            "1097125827@CHAPARRO@RINCON@JUAN@CARLOS@M@O+@14082014"
        )
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.documento, "1097125827")
        self.assertEqual(cap.apellidos, "CHAPARRO RINCON")
        self.assertEqual(cap.nombres, "JUAN CARLOS")
        self.assertNotIn("14082014", cap.nombres)
        self.assertNotIn("14082014", cap.apellidos)

    def test_pdf417_pubdsk_solo_cedula_sin_nombres(self) -> None:
        """PubDSK_ sin separadores: solo la cédula, sin nombres."""
        raw = (
            "0349601241PubDSK_14518891010107829"
            "ORDUZPEREZBRAYHANJAHIR0M19980406270010B+2c"
        )
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.origen, "pdf417")
        self.assertEqual(cap.metodo_aut, 3)
        self.assertEqual(cap.documento, "1010107829")
        self.assertEqual(cap.nombres, "")
        self.assertEqual(cap.apellidos, "")

    def test_pdf417_pubdsk_ignora_punto_y_coma_binario(self) -> None:
        """Basura con ';' no debe tomar el prefijo como cédula."""
        raw = (
            "FV?;0353406300PubDSK_14681021092342075"
            "ALVAREZDULCEYJOSEGREGORIO0M198902152700100+"
        )
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.origen, "pdf417")
        self.assertEqual(cap.metodo_aut, 3)
        self.assertEqual(cap.documento, "1092342075")
        self.assertNotEqual(cap.documento, "0353406300")
        self.assertEqual(cap.nombres, "")
        self.assertEqual(cap.apellidos, "")

    def test_documento_campo_pubdsk_no_usa_prefijo(self) -> None:
        """Coerce Entry: no primeros 10 del prefijo si hay PubDSK_."""
        raw = (
            "0353405630PubDSK_14681021092342075"
            "ALVAREZDULCEYJOSEGREGORIO0M19890215"
        )
        self.assertEqual(
            documento_desde_entrada_campo(raw), "1092342075"
        )
        self.assertEqual(sanear_documento(raw), "0353405630")
        self.assertEqual(documento_desde_entrada_campo("1092342075"), "1092342075")

    def test_pubdsk_incompleta_hasta_letras(self) -> None:
        """Sin letras aún: incompleta; con 1ª letra: lista y NUIP final."""
        parcial = "0353405630PubDSK_1468102109"
        self.assertTrue(trama_pubdsk_incompleta(parcial))
        self.assertFalse(trama_pubdsk_lista(parcial))
        lista = parcial + "2342075A"
        self.assertFalse(trama_pubdsk_incompleta(lista))
        self.assertTrue(trama_pubdsk_lista(lista))
        self.assertEqual(
            parse_captura_escaneo(lista).documento, "1092342075"
        )
        self.assertNotEqual(
            parse_captura_escaneo(lista).documento, "1468102109"
        )

    def test_pdf417_tab_como_separador(self) -> None:
        raw = "1098765432\tLOPEZ\tDIAZ\tANA\tMARIA\tF\tA-"
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.documento, "1098765432")
        self.assertEqual(cap.nombres, "ANA MARIA")
        self.assertEqual(cap.apellidos, "LOPEZ DIAZ")

    def test_fecha_no_es_documento(self) -> None:
        raw = "06041998@PEREZ@GOMEZ@JUAN@CARLOS"
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.documento, "")

    def test_barras_solo_digitos(self) -> None:
        cap = parse_captura_escaneo("1098765432")
        self.assertEqual(cap.documento, "1098765432")
        self.assertEqual(cap.origen, "barras")

    def test_basura_rh_sola_no_es_documento(self) -> None:
        cap = parse_captura_escaneo("O+")
        self.assertEqual(cap.documento, "")


class TestScanCaptureQrYBarras(unittest.TestCase):
    def test_qr_url_con_nuip_continuo(self) -> None:
        raw = "https://consultas.ejemplo.gov.co/cedula/1098765432?x=1"
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.origen, "qr")
        self.assertEqual(cap.metodo_aut, 2)
        self.assertEqual(cap.documento, "1098765432")

    def test_qr_url_digitos_dispersos_fallback_legacy(self) -> None:
        # Sin corrida 8–10 continua: concatena dígitos como antes.
        raw = (
            "https://verify.ejemplo.gov.co/q?a=10&b=987&c=65432"
            "&extra=abcdefghi"
        )
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.origen, "qr")
        self.assertEqual(cap.documento, "1098765432")

    def test_qr_no_roba_pdf417_con_arroba(self) -> None:
        raw = "1098765432@PEREZ@GOMEZ@JUAN@CARLOS@M@O+"
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.origen, "pdf417")
        self.assertEqual(cap.metodo_aut, 3)
        self.assertEqual(cap.documento, "1098765432")
        self.assertEqual(cap.nombres, "JUAN CARLOS")

    def test_pdf417_con_arroba_es_barras_no_qr(self) -> None:
        raw = "1097125827@CHAPARRO@RINCON@JUAN@CARLOS@M@O+@14082014"
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.origen, "pdf417")
        self.assertEqual(cap.metodo_aut, 3)

    def test_payload_largo_sin_url_no_es_qr(self) -> None:
        """Cédula/PDF417 sin '@' no debe marcarse metodo_aut=2."""
        raw = "1097125827CHAPARRORINCONJUANCARLOSMXEXTRA"
        self.assertGreater(len(raw), 30)
        cap = parse_captura_escaneo(raw)
        self.assertNotEqual(cap.metodo_aut, 2)
        self.assertEqual(cap.metodo_aut, 3)
        self.assertEqual(cap.documento, "1097125827")

    def test_barras_1d_solo_digitos_sigue_ok(self) -> None:
        cap = parse_captura_escaneo("1007692289")
        self.assertEqual(cap.origen, "barras")
        self.assertEqual(cap.metodo_aut, 3)
        self.assertEqual(cap.documento, "1007692289")

    def test_qr_no_acepta_solo_fecha(self) -> None:
        raw = "https://ejemplo.gov.co/doc?f=06041998&pad=abcdefghij"
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.origen, "qr")
        # 06041998 es fecha; sin más dígitos útiles → vacío.
        self.assertEqual(cap.documento, "")


def _trama_cedula_sin_pubdsk(campo_nuip: str) -> str:
    """Trama sintética (datos inventados) con la estructura real vista
    en el lector de portería el 2026-10-15: sin ``PubDSK_``, número de
    tarjeta al inicio, nombres de ancho fijo y binario con '|' / ';'."""
    campos = "".join(
        f"{n:<23}" for n in ("PEREZ", "GOMEZ", "ANA", "MARIA")
    )
    return (
        "0101010101" + "18B" + " " * 10 + "01234567890" + " " * 10
        + "12345678" + campo_nuip + campos
        + "0F19900101" + "05001" + "O+ "
        + "2aYp$|Zx;Q?98k6p8" * 8
    )


class TestCedulaSinPubdsk(unittest.TestCase):
    def test_nuip_8_digitos_sin_ceros_y_no_es_qr(self) -> None:
        raw = _trama_cedula_sin_pubdsk("0087654321")
        self.assertIn("|", raw)
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.documento, "87654321")
        self.assertEqual(cap.origen, "pdf417")
        self.assertEqual(cap.metodo_aut, 3)

    def test_nunca_toma_el_numero_de_tarjeta(self) -> None:
        cap = parse_captura_escaneo(_trama_cedula_sin_pubdsk("0087654321"))
        self.assertNotEqual(cap.documento, "0101010101")

    def test_nuip_10_digitos(self) -> None:
        cap = parse_captura_escaneo(_trama_cedula_sin_pubdsk("1012345678"))
        self.assertEqual(cap.documento, "1012345678")

    def test_nuip_que_parece_fecha_se_acepta(self) -> None:
        """Por posición es el NUIP: no rechazar 10121990 como fecha."""
        cap = parse_captura_escaneo(_trama_cedula_sin_pubdsk("0010121990"))
        self.assertEqual(cap.documento, "10121990")

    def test_cortada_en_enter_del_binario_conserva_nuip(self) -> None:
        """El lector corta en un Enter del binario: el NUIP va antes."""
        raw = _trama_cedula_sin_pubdsk("0087654321")[:258]
        self.assertEqual(parse_captura_escaneo(raw).documento, "87654321")

    def test_parece_cedula_sin_nuip_no_inventa(self) -> None:
        campos = "".join(f"{n:<23}" for n in ("PEREZ", "GOMEZ", "ANA"))
        raw = "0101010101" + "18B" + " " * 10 + campos + "$|;" * 10
        cap = parse_captura_escaneo(raw)
        self.assertEqual(cap.documento, "")
        self.assertEqual(cap.origen, "pdf417")

    def test_pubdsk_quita_ceros_de_relleno(self) -> None:
        raw = "0349601241PubDSK_14518891" + "0087654321" + "PEREZGOMEZ"
        self.assertEqual(parse_captura_escaneo(raw).documento, "87654321")
        self.assertEqual(documento_desde_entrada_campo(raw), "87654321")


if __name__ == "__main__":
    unittest.main()
