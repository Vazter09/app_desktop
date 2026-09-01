"""
responsive — escala de UI según resolución del equipo (solo stdlib + Tk).

Nombre interno del cambio (equipo): «responsive».
Si piden «Elimina los cambios de responsive», revertir este módulo y
todas las llamadas a ``init`` / ``sx`` / ``sfont`` / fuentes escaladas.

Diseño base: 1920×1080. En pantallas más grandes crece; en más chicas
no baja de 0.80; tope 1.60 para no romper layouts en 4K extremos.
Sin dependencias externas.
"""
from __future__ import annotations

import tkinter as tk

# Resolución de diseño (referencia visual del layout actual).
BASE_WIDTH = 1920
BASE_HEIGHT = 1080
SCALE_MIN = 0.80
SCALE_MAX = 1.60

_scale: float = 1.0
_initialized: bool = False


def init(root: tk.Misc) -> float:
    """Calcula el factor de escala a partir de la pantalla real."""
    global _scale, _initialized
    root.update_idletasks()
    sw = max(1, int(root.winfo_screenwidth()))
    sh = max(1, int(root.winfo_screenheight()))
    raw = min(sw / BASE_WIDTH, sh / BASE_HEIGHT)
    _scale = max(SCALE_MIN, min(SCALE_MAX, raw))
    _initialized = True
    return _scale


def scale() -> float:
    """Factor actual (1.0 si aún no se llamó ``init``)."""
    return _scale


def sx(px: int | float) -> int:
    """Escala un tamaño en píxeles (ancho/alto/márgenes)."""
    return max(1, int(round(float(px) * _scale)))


def sfont(font: tuple) -> tuple:
    """Escala el tamaño de punto de una tupla de fuente Tk.

    Ej.: ``("Segoe UI", 10)`` → ``("Segoe UI", 12)`` si scale≈1.2
    """
    if not font:
        return font
    family = font[0]
    size = int(font[1]) if len(font) > 1 else 10
    rest = font[2:]
    new_size = max(8, int(round(size * _scale)))
    return (family, new_size, *rest)


def is_initialized() -> bool:
    return _initialized
