"""
Rutas de la app: desarrollo (fuentes) vs ejecutable PyInstaller (frozen).

- resource_root(): assets/modelos empaquetados (solo lectura en onefile/_MEIPASS).
- writable_root(): junto al .exe (app_config.json editable en el PC de portería).
"""
from __future__ import annotations

import sys
from pathlib import Path


def is_frozen() -> bool:
    return bool(getattr(sys, "frozen", False))


def resource_root() -> Path:
    if is_frozen():
        # PyInstaller onedir/onefile: datos en sys._MEIPASS
        return Path(getattr(sys, "_MEIPASS", Path(sys.executable).resolve().parent))
    return Path(__file__).resolve().parent


def writable_root() -> Path:
    if is_frozen():
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parent
