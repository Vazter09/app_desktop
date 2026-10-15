"""Tests: detector de ráfagas del lector + guardia de teclado (bindtag).

Regresión del incidente 2026-10-15: la cola de una cédula PDF417
(espacios de relleno, Tab, binario) pulsó «Salir» y se escribió en el
login. Ver ``ui/scan_guard.py``.
"""
from __future__ import annotations

import tkinter as tk
import unittest
from tkinter import ttk

from tests.common import APP_DIR  # noqa: F401 — inserta src/ en sys.path
from ui import scan_burst, scan_guard
from ui.facial_modal import FacialRecognitionPanel
from ui.scan_burst import DetectorRafaga

_PUBDSK = "0349601241PubDSK_14518891010107829"
_COLA = "ORDUZPEREZ\tBRAYHAN JAHIR  0M19980406270010B+ 2c\r"


def _teclear(
    det: DetectorRafaga, texto: str, inicio_ms: float, paso_ms: float
) -> tuple[list[scan_burst.Decision], float]:
    decisiones = []
    t = inicio_ms
    for ch in texto:
        if ch == "\t":
            keysym, char = "Tab", "\t"
        elif ch == "\r":
            keysym, char = "Return", "\r"
        elif ch == " ":
            keysym, char = "space", " "
        else:
            keysym, char = ch, ch
        decisiones.append(det.tecla(keysym, char, t))
        t += paso_ms
    return decisiones, t


class TestDetectorRafaga(unittest.TestCase):
    def test_tecleo_humano_lento_no_pierde_caracteres(self) -> None:
        det = DetectorRafaga()
        decisiones, t = _teclear(det, "12345", 1000, 250)
        liberado = "".join(d.liberar for d in decisiones)
        liberado += det.tick(t + 250)
        self.assertEqual(liberado, "12345")
        self.assertTrue(all(d.trama is None for d in decisiones))

    def test_tecleo_humano_corto_y_enter_pasa_al_widget(self) -> None:
        det = DetectorRafaga()
        decisiones, t = _teclear(det, "123", 1000, 50)
        enter = det.tecla("Return", "\r", t)
        self.assertFalse(enter.consumir)
        self.assertIsNone(enter.trama)
        self.assertEqual(enter.liberar, "123")
        self.assertTrue(all(d.liberar == "" for d in decisiones))

    def test_barras_rapidas_con_enter_es_trama(self) -> None:
        det = DetectorRafaga()
        decisiones, _t = _teclear(det, "1007692289\r", 1000, 10)
        self.assertTrue(all(d.consumir for d in decisiones))
        self.assertEqual(decisiones[-1].trama, "1007692289")
        self.assertTrue(all(d.liberar == "" for d in decisiones))

    def test_cedula_pubdsk_cola_completa_se_descarta(self) -> None:
        """Toda la cola (Tab, espacios, Enter) se consume sin trama nueva."""
        det = DetectorRafaga()
        decisiones, t = _teclear(det, _PUBDSK + "O", 1000, 10)
        self.assertEqual(decisiones[-1].trama, _PUBDSK + "O")
        det.iniciar_descarte(t)
        # Cola lenta (60 ms/tecla, > COLA_MS en total): igual se come.
        cola, t = _teclear(det, _COLA * 3, t, 60)
        self.assertTrue(all(d.consumir for d in cola))
        self.assertTrue(all(d.trama is None for d in cola))
        self.assertTrue(all(d.liberar == "" for d in cola))
        # Pasada la ventana, el teclado humano vuelve a funcionar.
        _humano, t = _teclear(det, "9", t + scan_burst.COLA_MS + 1, 0)
        self.assertEqual(det.tick(t + 500), "9")

    def test_tab_en_rafaga_es_separador(self) -> None:
        det = DetectorRafaga()
        _teclear(det, "1234", 1000, 10)
        tab = det.tecla("Tab", "\t", 1040)
        self.assertTrue(tab.consumir)
        fin = det.tecla("Return", "\r", 1050)
        self.assertEqual(fin.trama, "1234@")

    def test_tab_humano_sin_rafaga_navega(self) -> None:
        det = DetectorRafaga()
        self.assertFalse(det.tecla("Tab", "\t", 1000).consumir)


class _TkTestCase(unittest.TestCase):
    def setUp(self) -> None:
        try:
            self.root = tk.Tk()
        except tk.TclError as exc:  # sin display
            self.skipTest(f"Tk no disponible: {exc}")
        self.root.geometry("200x120+10+10")

    def tearDown(self) -> None:
        for c in list(scan_guard._consumidores):
            scan_guard.liberar(c)
        self.root.destroy()

    def _enfocar(self, widget: tk.Misc) -> None:
        self.root.update()
        widget.focus_force()
        self.root.update()
        if self.root.focus_get() is not widget:
            self.skipTest("El entorno no entrega el foco a la ventana")


class TestScanGuardTk(_TkTestCase):
    def test_espacio_de_rafaga_no_pulsa_boton(self) -> None:
        pulsado: list[int] = []
        btn = ttk.Button(self.root, command=lambda: pulsado.append(1))
        btn.pack()
        scan_guard.instalar(self.root)
        self._enfocar(btn)
        self.assertEqual(
            self.root.tk.splitlist(self.root.tk.call("bindtags", str(btn)))[0],
            scan_guard.TAG,
        )

        # Control: sin consumidor el espacio sí pulsa (como antes).
        btn.event_generate("<KeyPress>", keysym="space", when="now")
        self.root.update()
        if not pulsado:
            self.skipTest("El entorno no entrega eventos de teclado")

        pulsado.clear()
        scan_guard.registrar(lambda _e: "break")
        btn.event_generate("<KeyPress>", keysym="space", when="now")
        self.root.update()
        self.assertEqual(pulsado, [])

    def test_tab_de_rafaga_no_mueve_foco(self) -> None:
        a = ttk.Entry(self.root)
        b = ttk.Entry(self.root)
        a.pack()
        b.pack()
        scan_guard.instalar(self.root)
        scan_guard.registrar(lambda _e: "break")
        self._enfocar(a)
        a.event_generate("<KeyPress>", keysym="Tab", when="now")
        self.root.update()
        self.assertIs(self.root.focus_get(), a)

    def test_liberar_consumidor_restaura_teclado(self) -> None:
        def consumidor(_e: tk.Event) -> str:
            return "break"

        scan_guard.registrar(consumidor)
        self.assertIs(scan_guard.consumidor_activo(), consumidor)
        scan_guard.liberar(consumidor)
        self.assertIsNone(scan_guard.consumidor_activo())


class TestInsertarTextoHumano(_TkTestCase):
    def test_inserta_en_entry_editable(self) -> None:
        entry = ttk.Entry(self.root)
        entry.insert(0, "12")
        FacialRecognitionPanel._insertar_texto_humano(entry, "34")
        self.assertEqual(entry.get(), "1234")

    def test_no_toca_combobox_readonly_ni_widgets_texto(self) -> None:
        combo = ttk.Combobox(self.root, values=["CC"], state="readonly")
        combo.set("CC")
        FacialRecognitionPanel._insertar_texto_humano(combo, "9")
        self.assertEqual(combo.get(), "CC")
        # Tk puede entregar el widget como nombre (str): se ignora.
        FacialRecognitionPanel._insertar_texto_humano(".!entry", "9")


if __name__ == "__main__":
    unittest.main()
