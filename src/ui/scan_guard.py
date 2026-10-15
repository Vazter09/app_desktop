"""
Guardia de teclado para el lector (keyboard wedge) a nivel de bindtag.

Problema que resuelve (incidente 2026-10-15): el handler de escaneo
vivía en ``bind_all`` (etiqueta ``all``), que Tk evalúa de ÚLTIMA. Para
entonces la clase del widget ya había actuado: un espacio de la trama
activaba el ``ttk.Button`` con foco y un Tab movía el foco (el binding
``<Tab>`` por defecto de ``all`` es más específico que ``<KeyPress>`` y
se ejecutaba en su lugar). Así la trama de una cédula llegó a pulsar
«Salir» y el resto se escribió en el login.

Aquí la etiqueta ``SmartcsetScanGuard`` se antepone a los bindtags de
cada widget que recibe el foco, de modo que el consumidor registrado ve
TODAS las teclas antes que el widget y su clase; si devuelve "break",
ni el botón, ni el Entry, ni la navegación por Tab reciben la tecla.

Un solo consumidor activo (pila): la página de portería se registra al
crearse y se libera al destruirse. Sin consumidor, el teclado se
comporta de forma normal (login, salida manual).
"""
from __future__ import annotations

import tkinter as tk
from collections.abc import Callable

from app_log import get_logger, log_exception

log = get_logger("ui.scan_guard")

TAG = "SmartcsetScanGuard"

Consumidor = Callable[[tk.Event], "str | None"]

_root: tk.Misc | None = None
_consumidores: list[Consumidor] = []


def instalar(widget: tk.Misc) -> None:
    """Idempotente: deja la guardia activa en la app de ``widget``."""
    global _root
    root = widget._root()
    if _root is root:
        return
    _root = root
    root.bind_class(TAG, "<KeyPress>", _despachar)
    root.bind_all("<FocusIn>", _al_recibir_foco, add="+")
    foco = _ruta_foco(root)
    anteponer_tag(root, foco or str(root))


def registrar(consumidor: Consumidor) -> None:
    liberar(consumidor)
    _consumidores.append(consumidor)


def liberar(consumidor: Consumidor) -> None:
    # Métodos ligados no son idénticos entre accesos: comparar con ==.
    _consumidores[:] = [c for c in _consumidores if c != consumidor]


def consumidor_activo() -> Consumidor | None:
    return _consumidores[-1] if _consumidores else None


def anteponer_tag(root: tk.Misc, ruta: str) -> None:
    """Pone ``TAG`` primero en los bindtags del widget ``ruta``."""
    try:
        tags = root.tk.splitlist(root.tk.call("bindtags", ruta))
    except tk.TclError:
        return
    if tags and tags[0] == TAG:
        return
    nuevos = (TAG, *[t for t in tags if t != TAG])
    try:
        root.tk.call("bindtags", ruta, nuevos)
    except tk.TclError:
        pass


def _ruta_foco(root: tk.Misc) -> str:
    try:
        return str(root.tk.call("focus"))
    except tk.TclError:
        return ""


def _al_recibir_foco(event: tk.Event) -> None:
    if _root is None:
        return
    # event.widget puede ser str (widgets internos de Tk sin wrapper).
    anteponer_tag(_root, str(event.widget))


def _despachar(event: tk.Event) -> str | None:
    consumidor = consumidor_activo()
    if consumidor is None:
        return None
    try:
        return consumidor(event)
    except Exception as exc:  # noqa: BLE001 — nunca romper el teclado
        log_exception(log, "Guardia de escaneo", exc)
        return None
