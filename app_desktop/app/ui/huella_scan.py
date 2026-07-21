"""
Animación de escaneo de huella en Canvas Tkinter.

Solo usa stdlib + Pillow/numpy ya presentes en la app desktop.
Sin CSS ni librerías de animación de terceros.
"""
from __future__ import annotations

import time
import tkinter as tk
from pathlib import Path

import numpy as np
from PIL import Image, ImageTk

from ui import theme

# Idle = cyan corporativo; éxito = verde neón (referencia UI).
_COLOR_IDLE = (0, 229, 176)
_COLOR_OK = (57, 255, 20)

_OVAL_W = 110
_OVAL_H = 170
_TICK_MS = 33
_LASER_MS = 2400
_TINT_MS = 700
_N_PUNTOS = 36


def _ruta_huella_png() -> Path | None:
    app_dir = Path(__file__).resolve().parents[1]
    repo_root = app_dir.parent.parent
    candidatos = (
        app_dir / "assets" / "img" / "huella.png",
        repo_root / "frontend" / "web" / "public" / "assets" / "img" / "huella.png",
    )
    for ruta in candidatos:
        if ruta.is_file():
            return ruta
    return None


def _lerp_color(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    t = max(0.0, min(1.0, t))
    return (
        int(a[0] + (b[0] - a[0]) * t),
        int(a[1] + (b[1] - a[1]) * t),
        int(a[2] + (b[2] - a[2]) * t),
    )


def _hex(rgb: tuple[int, int, int]) -> str:
    return f"#{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"


class HuellaScanCanvas(tk.Canvas):
    """Óvalo + huella.png + puntos + láser descendente permanente."""

    def __init__(self, master: tk.Misc, **kwargs) -> None:
        kwargs.setdefault("bg", "#000000")
        kwargs.setdefault("highlightthickness", 1)
        kwargs.setdefault("highlightbackground", theme.BORDER)
        kwargs.setdefault("width", 360)
        kwargs.setdefault("height", 560)
        super().__init__(master, **kwargs)

        self._photo_ref: ImageTk.PhotoImage | None = None
        self._ridge_rgba: np.ndarray | None = None  # arr tintable (alpha fijo)
        self._base_size: tuple[int, int] = (1, 1)
        self._puntos_norm: list[tuple[float, float]] = []
        self._img_bbox: tuple[int, int, int, int] = (0, 0, 0, 0)

        self._tint_t = 0.0
        self._tint_target = 0.0
        self._tint_from = 0.0
        self._tint_started = 0.0
        self._exito = False
        self._mensaje = "Coloque el dedo índice derecho\nen el huellero."
        self._mensaje_color = theme.TEXT_MUTED

        self._after_id: str | None = None
        self._running = False
        self._last_layout: tuple[int, int] = (0, 0)
        self._cache_tint_key: tuple[int, int, int] | None = None

        self.bind("<Configure>", self._on_configure, add="+")
        self.bind("<Destroy>", self._on_destroy, add="+")

    # ---- API pública -------------------------------------------------

    def start(self) -> None:
        if self._running:
            return
        self._running = True
        self._cargar_base()
        self._tick()

    def stop(self) -> None:
        self._running = False
        if self._after_id is not None:
            try:
                self.after_cancel(self._after_id)
            except tk.TclError:
                pass
            self._after_id = None

    def set_exito(self, ok: bool) -> None:
        """True → transición a verde; False → vuelve a cyan."""
        self._exito = bool(ok)
        self._tint_from = self._tint_t
        self._tint_target = 1.0 if ok else 0.0
        self._tint_started = time.perf_counter()

    def set_mensaje(self, texto: str, color: str | None = None) -> None:
        self._mensaje = texto
        if color is not None:
            self._mensaje_color = color
        elif self._exito:
            self._mensaje_color = theme.SUCCESS
        else:
            self._mensaje_color = theme.TEXT_MUTED

    # ---- Ciclo -------------------------------------------------------

    def _on_destroy(self, event: tk.Event) -> None:
        if event.widget is self:
            self.stop()

    def _on_configure(self, _event: tk.Event | None = None) -> None:
        w = max(1, int(self.winfo_width()))
        h = max(1, int(self.winfo_height()))
        if (w, h) != self._last_layout and w > 40 and h > 40:
            self._last_layout = (w, h)
            self._cache_tint_key = None
            self._cargar_base()

    def _tick(self) -> None:
        if not self._running:
            return
        try:
            if not self.winfo_exists():
                self._running = False
                return
        except tk.TclError:
            self._running = False
            return

        # Interpolación de tinte cyan → verde.
        if abs(self._tint_t - self._tint_target) > 0.001:
            elapsed = (time.perf_counter() - self._tint_started) * 1000.0
            p = min(1.0, elapsed / _TINT_MS)
            self._tint_t = self._tint_from + (self._tint_target - self._tint_from) * p
        else:
            self._tint_t = self._tint_target

        self._redibujar()
        self._after_id = self.after(_TICK_MS, self._tick)

    # ---- Recursos ----------------------------------------------------

    def _cargar_base(self) -> None:
        ruta = _ruta_huella_png()
        if ruta is None:
            self._ridge_rgba = None
            self._puntos_norm = []
            return
        try:
            img = Image.open(ruta).convert("RGBA")
        except OSError:
            self._ridge_rgba = None
            return

        arr = np.asarray(img).copy()
        luminancia = (
            arr[:, :, 0].astype(np.int16) + arr[:, :, 1] + arr[:, :, 2]
        )
        mascara = (arr[:, :, 3] >= 16) & (luminancia >= 40)
        arr[~mascara, 3] = 0
        arr[mascara, 0] = 255
        arr[mascara, 1] = 255
        arr[mascara, 2] = 255
        arr[mascara, 3] = 255

        ys, xs = np.where(arr[:, :, 3] > 0)
        if ys.size == 0:
            self._ridge_rgba = None
            return
        arr = arr[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1]

        # Tamaño destino interior del óvalo (holgura para el trazo).
        max_w = max(24, _OVAL_W - 28)
        max_h = max(24, _OVAL_H - 36)
        img = Image.fromarray(arr, mode="RGBA")
        iw, ih = img.size
        scale = max(max_w / iw, max_h / ih)
        new_w = max(1, int(round(iw * scale)))
        new_h = max(1, int(round(ih * scale)))
        img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        left = max(0, (new_w - max_w) // 2)
        top = max(0, (new_h - max_h) // 2)
        img = img.crop((left, top, left + max_w, top + max_h))
        self._ridge_rgba = np.asarray(img).copy()
        self._base_size = (max_w, max_h)

        # Puntos sobre crestas (posiciones normalizadas 0..1).
        ys2, xs2 = np.where(self._ridge_rgba[:, :, 3] > 0)
        self._puntos_norm = []
        if ys2.size > 0:
            rng = np.random.default_rng(42)
            # Prefiere zona central (más “biométrica”).
            h, w = self._ridge_rgba.shape[:2]
            cx, cy = (w - 1) / 2.0, (h - 1) / 2.0
            dist = np.sqrt((xs2 - cx) ** 2 + (ys2 - cy) ** 2)
            peso = 1.0 / (1.0 + dist / max(w, h) * 3.0)
            peso = peso / peso.sum()
            idx = rng.choice(ys2.size, size=min(_N_PUNTOS, ys2.size), replace=False, p=peso)
            for i in idx:
                self._puntos_norm.append((float(xs2[i]) / w, float(ys2[i]) / h))

        self._cache_tint_key = None

    def _photo_tinte(self) -> ImageTk.PhotoImage | None:
        if self._ridge_rgba is None:
            return None
        rgb = _lerp_color(_COLOR_IDLE, _COLOR_OK, self._tint_t)
        key = (rgb[0], rgb[1], rgb[2])
        if self._cache_tint_key == key and self._photo_ref is not None:
            return self._photo_ref

        arr = self._ridge_rgba.copy()
        mask = arr[:, :, 3] > 0
        arr[mask, 0] = rgb[0]
        arr[mask, 1] = rgb[1]
        arr[mask, 2] = rgb[2]
        img = Image.fromarray(arr, mode="RGBA")
        try:
            photo = ImageTk.PhotoImage(img, master=self)
        except tk.TclError:
            return None
        self._photo_ref = photo
        self._cache_tint_key = key
        return photo

    # ---- Dibujo ------------------------------------------------------

    def _redibujar(self) -> None:
        self.delete("all")
        w = int(self.winfo_width())
        h = int(self.winfo_height())
        if w < 40:
            w = int(self.cget("width") or 360)
        if h < 40:
            h = int(self.cget("height") or 560)

        cx, cy = w // 2, h // 2
        ox0 = cx - _OVAL_W // 2
        oy0 = cy - _OVAL_H // 2
        ox1 = cx + _OVAL_W // 2
        oy1 = cy + _OVAL_H // 2

        ring = _lerp_color(_COLOR_IDLE, _COLOR_OK, self._tint_t)
        self.create_oval(
            ox0, oy0, ox1, oy1,
            outline=_hex(ring),
            dash=(5, 4),
            width=2,
            tags="ring",
        )

        photo = self._photo_tinte()
        iw, ih = self._base_size
        ix0 = cx - iw // 2
        iy0 = cy - ih // 2
        self._img_bbox = (ix0, iy0, ix0 + iw, iy0 + ih)
        if photo is not None:
            self.create_image(cx, cy, image=photo, anchor="center", tags="huella")

        # Fase del láser (solo descendente, reinicia arriba).
        phase = (time.perf_counter() * 1000.0) % _LASER_MS / _LASER_MS
        laser_y = oy0 + int(phase * (_OVAL_H - 2)) + 1

        # Clip suave: solo dibuja láser dentro del óvalo.
        inset = 8
        lx0 = ox0 + inset
        lx1 = ox1 - inset
        laser_rgb = _lerp_color((0, 200, 255), _COLOR_OK, self._tint_t * 0.55)
        laser_hex = _hex(laser_rgb)
        # Brillo (líneas superpuestas).
        self.create_line(lx0, laser_y, lx1, laser_y, fill="#003344", width=10, tags="laser")
        self.create_line(lx0, laser_y, lx1, laser_y, fill=laser_hex, width=3, tags="laser")
        self.create_line(lx0, laser_y, lx1, laser_y, fill="#ffffff", width=1, tags="laser")
        # Banda de “revelado” bajo el láser.
        band = self.create_rectangle(
            lx0,
            max(oy0, laser_y - 14),
            lx1,
            laser_y,
            fill=laser_hex,
            outline="",
            stipple="gray50",
            tags="laser",
        )
        # Si stipple no se ve bien en algunos temas, la banda igual aporta tono.
        _ = band

        # Puntos de mapeo biométrico.
        punto_rgb = _lerp_color((180, 255, 240), _COLOR_OK, self._tint_t)
        punto_hex = _hex(punto_rgb)
        for nx, ny in self._puntos_norm:
            px = ix0 + int(nx * iw)
            py = iy0 + int(ny * ih)
            # Destello cuando el láser pasa cerca.
            dist = abs(py - laser_y)
            r = 2
            fill = punto_hex
            if dist < 10:
                r = 3
                fill = "#ffffff"
            elif dist < 22:
                r = 2
                fill = laser_hex
            self.create_oval(
                px - r, py - r, px + r, py + r,
                fill=fill,
                outline="",
                tags="punto",
            )

        self.create_text(
            cx,
            oy1 + 28,
            text=self._mensaje,
            fill=self._mensaje_color,
            font=theme.FONT_LABEL_SMALL,
            justify="center",
            tags="msg",
        )
