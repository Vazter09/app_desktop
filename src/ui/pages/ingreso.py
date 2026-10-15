"""
Página de portería biométrica — layout fijo:

  [ Cámara | Formulario manual | Huella ]

Sin tablero de accesos ni scrollbar. Toda la lógica (biometría, escáner
de pistola/QR/PDF417, formulario manual de ingreso) vive en
`FacialRecognitionPanel`, con los mismos endpoints reales que la web.
Las salidas se registran en el mismo panel (lector, rostro o huella).
"""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk

from smartcset_client import SmartcsetClient
from ui.facial_modal import FacialRecognitionPanel


class IngresoPage(ttk.Frame):
    def __init__(self, master: tk.Misc, client: SmartcsetClient) -> None:
        super().__init__(master, style="App.TFrame", padding=8)

        self.columnconfigure(0, weight=1)
        self.rowconfigure(0, weight=1)

        self._panel = FacialRecognitionPanel(
            self,
            client,
            on_registrado=None,
        )
        self._panel.grid(row=0, column=0, sticky="nsew")
