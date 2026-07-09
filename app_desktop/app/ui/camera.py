"""
Captura de cámara — única excepción de dependencias de terceros
compartida entre la app principal y el motor biométrico (`opencv-python`,
ver REGLAS_APP_ESCRITORIO_SGI.md sección 5.1/5.2). Aquí solo se toma el
frame de la webcam y se muestra en vivo — el cómputo del vector facial
(embedding) NO ocurre en este módulo, va en el motor biométrico local
aparte (todavía no construido).

La conversión de frame a imagen mostrable en Tkinter se hace a mano en
formato PPM (P6) — sin agregar Pillow — porque `numpy`+`opencv` ya
alcanzan y `tk.PhotoImage` acepta PPM binario directo vía `data=`.
"""
from __future__ import annotations

import tkinter as tk

import cv2
import numpy as np

MAX_INDICES_A_PROBAR = 4


def detectar_camara_disponible(max_indices: int = MAX_INDICES_A_PROBAR) -> int | None:
    """Prueba los primeros `max_indices` índices de video del equipo y
    devuelve el primero que abre Y entrega un frame real — no basta con
    que `isOpened()` sea True (algunos nodos /dev/video* son metadata,
    no cámara real, y abren pero no leen)."""
    for indice in range(max_indices):
        cap = cv2.VideoCapture(indice)
        try:
            if not cap.isOpened():
                continue
            ok, frame = cap.read()
            if ok and frame is not None:
                return indice
        finally:
            cap.release()
    return None


class CameraSource:
    """Wrapper delgado sobre `cv2.VideoCapture` — abrir, leer, liberar."""

    def __init__(self, indice: int) -> None:
        self._indice = indice
        self._cap: cv2.VideoCapture | None = None

    def abrir(self) -> bool:
        self._cap = cv2.VideoCapture(self._indice)
        return self._cap.isOpened()

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
