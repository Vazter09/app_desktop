"""Utilidades de ventana Tkinter compartidas por modales de la app."""
from __future__ import annotations

import tkinter as tk


def centrar_ventana(
    ventana: tk.Misc,
    ancho: int | None = None,
    alto: int | None = None,
) -> None:
    """Centra una ventana en la pantalla (eje horizontal y vertical)."""
    if not ventana.winfo_exists():
        return

    ventana.update_idletasks()

    # 1) Fijar tamaño deseado, 2) leer tamaño real con decoraciones, 3) solo
    # posición — en Windows el alto pedido no coincide con el alto visible y
    # rompe el centrado vertical si se calcula en un solo paso.
    if ancho is not None and alto is not None:
        ventana.geometry(f"{ancho}x{alto}")
        ventana.update_idletasks()

    w = ventana.winfo_width()
    h = ventana.winfo_height()
    if w <= 1:
        w = ventana.winfo_reqwidth()
    if h <= 1:
        h = ventana.winfo_reqheight()

    sw = ventana.winfo_screenwidth()
    sh = ventana.winfo_screenheight()
    x = max(0, int((sw - w) / 2))
    y = max(0, int((sh - h) / 2))
    ventana.geometry(f"+{x}+{y}")


def centrar_ventana_al_mostrar(
    ventana: tk.Misc,
    ancho: int | None = None,
    alto: int | None = None,
) -> None:
    """Centra al abrir y reaplica al mostrarse (transient en Windows desplaza Y)."""
    centrar_ventana(ventana, ancho, alto)

    def _recentrar(_event: tk.Event | None = None) -> None:
        centrar_ventana(ventana, ancho, alto)

    ventana.bind("<Map>", _recentrar, add="+")
    ventana.after(50, _recentrar)
    ventana.after(200, _recentrar)
