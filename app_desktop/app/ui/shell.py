"""
Shell autenticado — sidebar + topbar reales + área de contenido
intercambiable. Réplica funcional de `frontend/web/layout/{sidebar,
topbar}.php`: navegar entre "páginas" aquí reemplaza al SPA real
(`smartcset-spa.js`) que intercepta `data-spa-link` en la web — mismo
resultado (cambiar el contenido sin recargar toda la ventana), sin
necesitar navegador.

Páginas registradas (submenú "SGI - Ingresos" visible en sidebar):
  - Inicio              -> pages.inicio.InicioPage
  - Registro ingreso(102)-> pages.ingreso.IngresoPage
  - Registro salida (103)-> pages.salida.SalidaPage
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
            "ingreso": ("Registro ingreso", IngresoPage),
            "salida": ("Registro salida", SalidaPage),
        }

        self.columnconfigure(1, weight=1)
        self.rowconfigure(0, weight=1)

        self._nav_labels: dict[str, tk.Label] = {}
        self._active_key: str | None = None
        self._build_sidebar()

        self._main = ttk.Frame(self, style="App.TFrame")
        self._main.grid(row=0, column=1, sticky="nsew")
        self._main.columnconfigure(0, weight=1)
        self._main.rowconfigure(1, weight=1)

        self._breadcrumb_var = tk.StringVar()
        self._build_topbar()

        self._content = ttk.Frame(self._main, style="App.TFrame")
        self._content.grid(row=1, column=0, sticky="nsew")
        self._content.columnconfigure(0, weight=1)
        self._content.rowconfigure(0, weight=1)

        self._current_page: tk.Widget | None = None
        self.navigate("inicio")

    # ---- Sidebar ------------------------------------------------------

    def _build_sidebar(self) -> None:
        sidebar = tk.Frame(self, bg=theme.SIDEBAR_BG, width=220)
        sidebar.grid(row=0, column=0, sticky="ns")
        sidebar.grid_propagate(False)

        header = tk.Frame(sidebar, bg=theme.SIDEBAR_BG, height=54)
        header.pack(fill="x")
        header.pack_propagate(False)
        tk.Label(
            header,
            text="SMARTCSET",
            bg=theme.SIDEBAR_BG,
            fg=theme.TEXT_PRIMARY,
            font=("Segoe UI", 12, "bold"),
        ).pack(side="left", padx=14)

        tk.Frame(sidebar, bg=theme.BORDER, height=1).pack(fill="x")

        self._add_nav_item(sidebar, "inicio", "⌂  Inicio", top=True)

        tk.Frame(sidebar, bg=theme.BORDER, height=1).pack(fill="x", pady=6)

        tk.Label(
            sidebar,
            text="  →  SGI - Ingresos",
            bg=theme.SIDEBAR_BG,
            fg=theme.TEXT_PRIMARY,
            font=theme.FONT_BODY,
            anchor="w",
            padx=8,
            pady=8,
        ).pack(fill="x")

        self._add_nav_item(sidebar, "ingreso", "        Registro ingreso")
        self._add_nav_item(sidebar, "salida", "        Registro salida")

    def _add_nav_item(
        self, sidebar: tk.Frame, key: str, text: str, top: bool = False
    ) -> None:
        lbl = tk.Label(
            sidebar,
            text=text,
            bg=theme.SIDEBAR_BG,
            fg=theme.TEXT_PRIMARY,
            font=theme.FONT_BODY_BOLD if top else theme.FONT_BODY,
            anchor="w",
            padx=8,
            pady=9 if top else 6,
            cursor="hand2",
        )
        lbl.pack(fill="x", pady=(6, 0) if top else 0)
        lbl.bind("<Button-1>", lambda _e, k=key: self.navigate(k))
        lbl.bind("<Enter>", lambda _e, w=lbl, k=key: self._on_hover(w, k, True))
        lbl.bind("<Leave>", lambda _e, w=lbl, k=key: self._on_hover(w, k, False))
        self._nav_labels[key] = lbl

    def _on_hover(self, widget: tk.Label, key: str, entering: bool) -> None:
        if self._active_key == key:
            return
        widget.configure(bg="#22331f" if entering else theme.SIDEBAR_BG)

    def _set_active_nav(self, key: str) -> None:
        self._active_key = key
        for k, lbl in self._nav_labels.items():
            if k == key:
                lbl.configure(bg=theme.V_OLIVA, fg="#ffffff")
            else:
                lbl.configure(bg=theme.SIDEBAR_BG, fg=theme.TEXT_PRIMARY)

    # ---- Topbar ---------------------------------------------------------

    def _build_topbar(self) -> None:
        topbar = tk.Frame(self._main, bg=theme.BG_PANEL, height=theme.TOPBAR_HEIGHT)
        topbar.grid(row=0, column=0, sticky="ew")
        topbar.grid_propagate(False)

        tk.Label(
            topbar,
            textvariable=self._breadcrumb_var,
            bg=theme.BG_PANEL,
            fg=theme.V_OLIVA,
            font=theme.FONT_TOPBAR_BREADCRUMB,
        ).place(relx=0, rely=0.5, anchor="w", x=16)

        right = tk.Frame(topbar, bg=theme.BG_PANEL)
        right.place(relx=1, rely=0.5, anchor="e", x=-16)

        nombre = self._usuario.get("nombre") or self._usuario.get("id", "")
        tk.Label(
            right,
            text=f"\U0001F464 {nombre}",
            bg=theme.BG_PANEL,
            fg=theme.TEXT_PRIMARY,
            font=theme.FONT_TOPBAR_USER,
        ).pack(side="left", padx=(0, 14))

        ttk.Button(
            right,
            text="Salir",
            style="TopbarLogout.TButton",
            command=self._do_logout,
        ).pack(side="left")

    # ---- Navegación -------------------------------------------------------

    def navigate(self, key: str) -> None:
        title, page_cls = self._pages[key]
        self._breadcrumb_var.set(f"⌂ Inicio  ›  {title}" if key != "inicio" else "⌂ Inicio")
        self._set_active_nav(key)

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
