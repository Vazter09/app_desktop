"""
Captura de cámara — única excepción de dependencias de terceros
compartida entre la app principal y el motor biométrico (`opencv-python`,
ver REGLAS_APP_ESCRITORIO_SGI.md sección 5.1/5.2). Aquí solo se toma el
frame de la webcam y se muestra en vivo — el cómputo del vector facial
(embedding) NO ocurre en este módulo, va en `motor/embeddings.py`.

La conversión de frame a imagen mostrable en Tkinter se hace a mano en
formato PPM (P6) — sin agregar Pillow — porque `numpy`+`opencv` ya
alcanzan y `tk.PhotoImage` acepta PPM binario directo vía `data=`.
"""
from __future__ import annotations

import os
import tkinter as tk

import cv2
import numpy as np

MAX_INDICES_A_PROBAR = 8


def _backend_captura() -> int:
    """Backend de video según SO — en Windows DirectShow es el más fiable
    para webcams integradas y USB (MSMF suele fallar en equipos mixtos)."""
    if os.name == "nt" and hasattr(cv2, "CAP_DSHOW"):
        return cv2.CAP_DSHOW
    return cv2.CAP_ANY


def _abrir_captura(indice: int) -> cv2.VideoCapture:
    backend = _backend_captura()
    cap = cv2.VideoCapture(indice, backend)
    if not cap.isOpened() and backend != cv2.CAP_ANY:
        cap.release()
        cap = cv2.VideoCapture(indice)
    return cap


def _leer_frame_con_warmup(cap: cv2.VideoCapture, intentos: int = 8) -> bool:
    """Algunas cámaras en Windows entregan frames vacíos los primeros
    ciclos tras `open()` — descartarlos antes de dar la cámara por lista."""
    for _ in range(intentos):
        ok, frame = cap.read()
        if ok and frame is not None and frame.size > 0:
            return True
    return False


def _captura_entrega_frame(cap: cv2.VideoCapture) -> bool:
    """No basta con que `isOpened()` sea True: algunos nodos /dev/video*
    son metadata, no cámara real, y abren pero no leen frames."""
    return cap.isOpened() and _leer_frame_con_warmup(cap)


def _indice_entrega_frame_real(indice: int) -> bool:
    cap = _abrir_captura(indice)
    try:
        return _captura_entrega_frame(cap)
    finally:
        cap.release()


def listar_camaras_disponibles(max_indices: int = MAX_INDICES_A_PROBAR) -> list[int]:
    """Prueba los primeros `max_indices` índices de video del equipo y
    devuelve TODOS los que abren y entregan un frame real — permite
    detectar periféricos/cámaras externas además de la que trae el
    dispositivo por defecto (índice 0)."""
    return [i for i in range(max_indices) if _indice_entrega_frame_real(i)]


def detectar_camara_disponible(
    max_indices: int = MAX_INDICES_A_PROBAR,
    *,
    excluir: int | None = None,
) -> int | None:
    """Devuelve el primer índice de video disponible.

    Prueba primero el índice 0 (cámara conectada en la mayoría de equipos
    Windows) y solo escanea el resto si falla. `excluir` omite un índice que
    el llamador ya sabe que falló, para no volver a abrirlo."""
    for indice in range(max_indices):
        if indice == excluir:
            continue
        if _indice_entrega_frame_real(indice):
            return indice
    return None


class CameraSource:
    """Wrapper delgado sobre `cv2.VideoCapture` — abrir, leer, liberar."""

    def __init__(self, indice: int) -> None:
        self._indice = indice
        self._cap: cv2.VideoCapture | None = None

    def abrir(self) -> bool:
        self._cap = _abrir_captura(self._indice)
        if _captura_entrega_frame(self._cap):
            return True
        self.liberar()
        return False

    def leer_frame(self) -> np.ndarray | None:
        if self._cap is None:
            return None
        ok, frame = self._cap.read()
        return frame if ok else None

    def liberar(self) -> None:
        if self._cap is not None:
            self._cap.release()
            self._cap = None


def frame_a_photoimage(frame_bgr: np.ndarray, ancho: int, alto: int) -> tk.PhotoImage:
    """Convierte un frame BGR de OpenCV a `tk.PhotoImage` (formato PPM,
    sin depender de Pillow)."""
    redimensionado = cv2.resize(frame_bgr, (ancho, alto), interpolation=cv2.INTER_AREA)
    rgb = cv2.cvtColor(redimensionado, cv2.COLOR_BGR2RGB)

    header = f"P6\n{ancho} {alto}\n255\n".encode("ascii")
    return tk.PhotoImage(data=header + rgb.tobytes(), width=ancho, height=alto)
