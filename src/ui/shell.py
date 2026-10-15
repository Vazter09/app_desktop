"""
Shell autenticado — topbar + área de contenido a ancho completo.

Tras el login, la app muestra solo IngresoPage (cámara + formulario +
huella, sin tablero ni sidebar). Ingresos y salidas se registran ahí; la
topbar solo tiene el usuario y «Salir» (botones «Portería» / «Salida
manual» eliminados el 2026-10-15).
"""
from __future__ import annotations

import tkinter as tk
from tkinter import messagebox, ttk
from typing import Callable

from app_log import get_logger
from smartcset_client import SmartcsetClient
from ui import theme
from ui.pages.ingreso import IngresoPage
from ui.responsive import sfont, sx

log = get_logger("ui.shell")

_BREADCRUMB = "⌂ Portería  ›  Sistema de Reconocimiento Multibiométrico"


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

        self.columnconfigure(0, weight=1)
        self.rowconfigure(0, weight=1)

        self._main = ttk.Frame(self, style="App.TFrame")
        self._main.grid(row=0, column=0, sticky="nsew")
        self._main.columnconfigure(0, weight=1)
        self._main.rowconfigure(1, weight=1)

        self._breadcrumb_var = tk.StringVar(value=_BREADCRUMB)
        self._build_topbar()

        self._content = ttk.Frame(self._main, style="App.TFrame")
        self._content.grid(row=1, column=0, sticky="nsew")
        self._content.columnconfigure(0, weight=1)
        self._content.rowconfigure(0, weight=1)

        # Portería: al autenticarse, cámara facial de inmediato.
        IngresoPage(self._content, self._client).grid(
            row=0, column=0, sticky="nsew"
        )

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

        # takefocus=False: el lector teclea Tab/espacio (trama PDF417) y
        # no debe poder enfocar ni pulsar este botón (incidente
        # 2026-10-15: una cédula activó «Salir»). Solo mouse.
        ttk.Button(
            right,
            text="Salir",
            style="TopbarLogout.TButton",
            command=self._do_logout,
            takefocus=False,
        ).pack(side="left")

    def _do_logout(self) -> None:
        # default=no: un Enter/espacio del lector nunca confirma.
        if not messagebox.askyesno(
            "Cerrar sesión",
            "¿Desea cerrar la sesión de portería?",
            default="no",
            parent=self,
        ):
            return
        log.info("Logout solicitado por el operario")
        self._client.logout()
        self._on_logout()
