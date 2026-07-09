"""
Página placeholder — para "Datos estadísticos", que en la web real
TAMPOCO está implementada (`pages/modulos/en_construccion/estadisticos.php`
es un placeholder genérico "en construcción"). Se replica exactamente esa
paridad: la app de escritorio no inventa una funcionalidad que la web
tampoco tiene.
"""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk
from typing import Any, Callable

from smartcset_client import SmartcsetClient
from ui import theme


class PlaceholderPage(ttk.Frame):
    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        usuario: dict[str, Any],
        on_navigate: Callable[[str], None],
    ) -> None:
        super().__init__(master, style="App.TFrame", padding=40)
        self.columnconfigure(0, weight=1)
        self.rowconfigure(0, weight=1)

        box = ttk.Frame(self, style="Card.TFrame", padding=40)
        box.grid(row=0, column=0)

        ttk.Label(
            box, text="🚧  En construcción", style="Title.TLabel"
        ).pack()
        ttk.Label(
            box,
            text="Esta sección tampoco está implementada en el módulo web —\n"
            "se muestra el mismo estado aquí para mantener la paridad exacta.",
            style="CardMuted.TLabel",
            justify="center",
        ).pack(pady=(8, 0))
