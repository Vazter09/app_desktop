"""
Rutas de la app: desarrollo (fuentes) vs ejecutable PyInstaller (frozen).

Estructura de desarrollo (app_desktop/):
  src/       → código + assets + modelos (resource_root)
  runtime/   → app_config.json, logs/, images/, .venv/ (writable_root)

En ejecutable:
  resource_root → _MEIPASS / carpeta del bundle
  writable_root → carpeta del .exe (app_config editable en portería)
"""
from __future__ import annotations

import sys
from pathlib import Path


def is_frozen() -> bool:
    return bool(getattr(sys, "frozen", False))


def module_root() -> Path:
    """Raíz del módulo app_desktop/ (padre de src/)."""
    return Path(__file__).resolve().parent.parent


def resource_root() -> Path:
    """Recursos de solo lectura: assets/, motor/models/."""
    if is_frozen():
        return Path(getattr(sys, "_MEIPASS", Path(sys.executable).resolve().parent))
    return Path(__file__).resolve().parent  # src/


def ruta_asset_img(nombre: str) -> Path | None:
    """Imagen de `assets/img/`: bundle/src primero, luego el frontend web (dev)."""
    candidatos = (
        resource_root() / "assets" / "img" / nombre,
        Path(__file__).resolve().parent / "assets" / "img" / nombre,
        resource_root().parent.parent
        / "frontend"
        / "web"
        / "public"
        / "assets"
        / "img"
        / nombre,
    )
    for ruta in candidatos:
        if ruta.is_file():
            return ruta
    return None


def writable_root() -> Path:
    """Datos escribibles: config, logs, cache de fotos, .venv."""
    if is_frozen():
        return Path(sys.executable).resolve().parent
    path = module_root() / "runtime"
    path.mkdir(parents=True, exist_ok=True)
    return path
