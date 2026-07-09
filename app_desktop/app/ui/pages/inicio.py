"""
Página "Inicio" — réplica del dashboard real
(frontend/web/pages/menu/menu_principal.php): hero de bienvenida, 3 KPI,
"Acciones rápidas" (navegan de verdad a Ingreso/Salida) y "Actividad
reciente" con datos reales de hoy.
"""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk
from typing import Any, Callable

from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError
from ui import theme
from ui.format_utils import format_db_timestamp


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
        self.rowconfigure(1, weight=1)

        self._build_hero()
        self._build_panels()
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
            text="Resumen operativo del día. Use el menú lateral o las acciones\n"
            "rápidas para tareas frecuentes.",
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

    def _build_panels(self) -> None:
        panels = ttk.Frame(self, style="App.TFrame")
        panels.grid(row=1, column=0, sticky="nsew", pady=(16, 0))
        panels.columnconfigure(0, weight=1)
        panels.columnconfigure(1, weight=1)

        acciones = ttk.Frame(panels, style="Card.TFrame", padding=16)
        acciones.grid(row=0, column=0, sticky="nsew", padx=(0, 8))
        ttk.Label(acciones, text="⚡ Acciones rápidas", style="Card.TLabel").pack(anchor="w", pady=(0, 10))
        ttk.Button(
            acciones, text="Registro de ingreso  →", style="Nav.TButton",
            command=lambda: self._on_navigate("ingreso"),
        ).pack(fill="x", pady=3)
        ttk.Button(
            acciones, text="Registro de salida  →", style="Nav.TButton",
            command=lambda: self._on_navigate("salida"),
        ).pack(fill="x", pady=3)

        actividad = ttk.Frame(panels, style="Card.TFrame", padding=16)
        actividad.grid(row=0, column=1, sticky="nsew", padx=(8, 0))
        ttk.Label(actividad, text="⏱ Actividad reciente", style="Card.TLabel").pack(anchor="w", pady=(0, 10))
        self._actividad_frame = actividad

    def _load(self) -> None:
        try:
            ingresos = self._client.ingresos_hoy()
            salidas = self._client.salidas_hoy()
        except (SmartcsetApiError, SmartcsetConnectionError):
            ingresos, salidas = [], []

        self._kpi_ingresos.configure(text=str(len(ingresos)))
        self._kpi_salidas.configure(text=str(len(salidas)))
        self._kpi_dentro.configure(text=str(max(0, len(ingresos) - len(salidas))))

        for child in list(self._actividad_frame.winfo_children())[1:]:
            child.destroy()

        if not ingresos:
            ttk.Label(
                self._actividad_frame, text="Sin ingresos registrados hoy.", style="CardMuted.TLabel"
            ).pack(anchor="w")
            return

        for item in ingresos[:8]:
            nombre = f"{item.get('nombres', '')} {item.get('apellidos', '')}".strip()
            hora = format_db_timestamp(item.get("fec_ingreso"))
            ttk.Label(
                self._actividad_frame, text=f"{nombre or '—'}   ·   {hora}", style="CardMuted.TLabel"
            ).pack(anchor="w", pady=2)
