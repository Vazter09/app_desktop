"""
Shell autenticado — topbar + área de contenido a ancho completo.

Tras el login, la app entra a IngresoPage (cámara + huella embebidas,
sin tablero ni sidebar). Otras páginas quedan registradas para
navegación interna.
"""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk
from typing import Callable

from smartcset_client import SmartcsetClient
from ui import theme
from ui.pages.inicio import InicioPage
from ui.pages.ingreso import IngresoPage
from ui.pages.salida import SalidaPage
from ui.responsive import sfont, sx


class AppShell(ttk.Frame):
    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        usuario: dict,
        on_logout: Callable[[], None],
    ) -> None:
        super().__init__(master, style="App.TFrame")
        self._client = client
        self._usuario = usuario
        self._on_logout = on_logout

        self._pages = {
            "inicio": ("Inicio", InicioPage),
            "ingreso": ("Sistema de Reconocimiento Multibiométrico", IngresoPage),
            "salida": ("Registro salida", SalidaPage),
        }

        self.columnconfigure(0, weight=1)
        self.rowconfigure(0, weight=1)

        self._main = ttk.Frame(self, style="App.TFrame")
        self._main.grid(row=0, column=0, sticky="nsew")
        self._main.columnconfigure(0, weight=1)
        self._main.rowconfigure(1, weight=1)

        self._breadcrumb_var = tk.StringVar()
        self._build_topbar()

        self._content = ttk.Frame(self._main, style="App.TFrame")
        self._content.grid(row=1, column=0, sticky="nsew")
        self._content.columnconfigure(0, weight=1)
        self._content.rowconfigure(0, weight=1)

        self._current_page: tk.Widget | None = None
        # Portería: al autenticarse, cámara facial de inmediato.
        self.navigate("ingreso")

    # ---- Topbar ---------------------------------------------------------

    def _build_topbar(self) -> None:
        topbar = tk.Frame(self._main, bg=theme.BG_PANEL, height=theme.TOPBAR_HEIGHT)
        topbar.grid(row=0, column=0, sticky="ew")
        topbar.grid_propagate(False)

        left = tk.Frame(topbar, bg=theme.BG_PANEL)
        left.place(relx=0, rely=0.5, anchor="w", x=sx(16))

        tk.Label(
            left,
            text="SMARTCSET",
            bg=theme.BG_PANEL,
            fg=theme.TEXT_PRIMARY,
            font=sfont(("Segoe UI", 12, "bold")),
        ).pack(side="left")

        tk.Label(
            left,
            textvariable=self._breadcrumb_var,
            bg=theme.BG_PANEL,
            fg=theme.V_OLIVA,
            font=theme.FONT_TOPBAR_BREADCRUMB,
        ).pack(side="left", padx=(sx(16), 0))

        right = tk.Frame(topbar, bg=theme.BG_PANEL)
        right.place(relx=1, rely=0.5, anchor="e", x=-sx(16))

        nombre = self._usuario.get("nombre") or self._usuario.get("id", "")
        tk.Label(
            right,
            text=f"\U0001F464 {nombre}",
            bg=theme.BG_PANEL,
            fg=theme.TEXT_PRIMARY,
            font=theme.FONT_TOPBAR_USER,
        ).pack(side="left", padx=(0, sx(14)))

        ttk.Button(
            right,
            text="Salir",
            style="TopbarLogout.TButton",
            command=self._do_logout,
        ).pack(side="left")

    # ---- Navegación -------------------------------------------------------

    def navigate(self, key: str) -> None:
        title, page_cls = self._pages[key]
        if key == "inicio":
            self._breadcrumb_var.set("⌂ Inicio")
        elif key == "ingreso":
            self._breadcrumb_var.set(
                "⌂ Portería  ›  Sistema de Reconocimiento Multibiométrico"
            )
        else:
            self._breadcrumb_var.set(f"⌂ Inicio  ›  {title}")

        if self._current_page is not None:
            self._current_page.destroy()

        page = page_cls(
            self._content, self._client, usuario=self._usuario, on_navigate=self.navigate
        )
        page.grid(row=0, column=0, sticky="nsew")
        self._current_page = page

    def _do_logout(self) -> None:
        self._client.logout()
        self._on_logout()
