"""
Página "Inicio" — réplica del dashboard real
(frontend/web/pages/menu/menu_principal.php): hero de bienvenida y 3 KPI.
"""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk
from typing import Any, Callable

from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError
from ui import theme


class InicioPage(ttk.Frame):
    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        usuario: dict[str, Any],
        on_navigate: Callable[[str], None],
    ) -> None:
        super().__init__(master, style="App.TFrame", padding=24)
        self._client = client
        self._usuario = usuario
        self._on_navigate = on_navigate

        self.columnconfigure(0, weight=1)

        self._build_hero()
        self.after(10, self._load)

    def _build_hero(self) -> None:
        hero = tk.Frame(self, bg=theme.V_OSCURO, padx=22, pady=18)
        hero.grid(row=0, column=0, sticky="ew")
        hero.columnconfigure(0, weight=1)

        nombre = self._usuario.get("nombre") or self._usuario.get("id", "")
        tk.Label(
            hero, text="PANEL PRINCIPAL", bg=theme.V_OSCURO, fg="#cfe0c8",
            font=theme.FONT_LABEL_SMALL,
        ).grid(row=0, column=0, sticky="w")
        tk.Label(
            hero, text=f"Bienvenido, {nombre}", bg=theme.V_OSCURO, fg="#ffffff",
            font=("Segoe UI", 18, "bold"),
        ).grid(row=1, column=0, sticky="w", pady=(2, 4))
        tk.Label(
            hero,
            text="Resumen operativo del día. Use el menú lateral para las tareas frecuentes.",
            bg=theme.V_OSCURO, fg="#dbe8d4", font=theme.FONT_BODY, justify="left",
        ).grid(row=2, column=0, sticky="w")

        kpis = tk.Frame(hero, bg=theme.V_OSCURO)
        kpis.grid(row=3, column=0, sticky="ew", pady=(16, 0))
        for i in range(3):
            kpis.columnconfigure(i, weight=1)

        self._kpi_ingresos = self._make_kpi_card(kpis, "INGRESOS HOY", 0)
        self._kpi_salidas = self._make_kpi_card(kpis, "SALIDAS HOY", 1)
        self._kpi_dentro = self._make_kpi_card(kpis, "PERSONAS DENTRO AHORA", 2, highlight=True)

    def _make_kpi_card(
        self, parent: tk.Frame, label: str, col: int, highlight: bool = False
    ) -> tk.Label:
        bg = theme.V_OLIVA if highlight else "#3a5640"
        card = tk.Frame(parent, bg=bg, padx=14, pady=10)
        card.grid(row=0, column=col, sticky="ew", padx=(0 if col == 0 else 8, 0))
        value_label = tk.Label(card, text="0", bg=bg, fg="#ffffff", font=("Segoe UI", 20, "bold"))
        value_label.pack(anchor="w")
        tk.Label(card, text=label, bg=bg, fg="#ecf3e6", font=theme.FONT_LABEL_SMALL).pack(anchor="w")
        return value_label

    def _load(self) -> None:
        try:
            ingresos = self._client.ingresos_hoy()
            salidas = self._client.salidas_hoy()
        except (SmartcsetApiError, SmartcsetConnectionError):
            ingresos, salidas = [], []

        self._kpi_ingresos.configure(text=str(len(ingresos)))
        self._kpi_salidas.configure(text=str(len(salidas)))
        self._kpi_dentro.configure(text=str(max(0, len(ingresos) - len(salidas))))
