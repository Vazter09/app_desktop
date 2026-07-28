"""
Panel / modal "Reconocimiento biométrico" — flujo único de portería.

`FacialRecognitionPanel` es el layout fijo (cámara izquierda + huella
derecha). `FacialRecognitionModal` es un Toplevel opcional que reutiliza
el mismo panel (p. ej. desde la página de salida).

Tras identificar un rostro, consulta `ingreso/consultar.php`:
  - si puede ingresar → registra ingreso
  - si hay ingreso abierto y aún no pasan 5 min → UPDATE de captura
  - si hay ingreso abierto y ya pasaron 5 min → registra salida

ESTADO: flujo completo real (facial). Huella: solo UI por ahora.
1. Cámara en vivo (`ui/camera.py`, OpenCV).
2. Motor de embeddings (`motor/embeddings.py`, SFace + YuNet).
3. "Capturar Rostro": documento + frame → `biometria/enrolar.php`.
4. "Identificar": frame → `biometria/identificar.php` → panel
   «Persona encontrada» (~2.5 s) → ingreso / actualizar / salida
   (`metodo_aut=4`) y vuelve al formulario vacío.
"""
from __future__ import annotations

import base64
import io
import threading
import time
import tkinter as tk
from tkinter import ttk
from typing import Any, Callable, Literal

import cv2
import numpy as np
from PIL import Image, ImageTk

from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError
from tkinter import messagebox
from ui import theme
from ui.camera import (
    CameraSource,
    detectar_camara_disponible,
    frame_a_photoimage,
    listar_camaras_disponibles,
)
from ui.huella_scan import HuellaScanCanvas
from ui.identification_confirmation_modal import IdentificationConfirmationPanel
from ui.ingreso_form_panel import IngresoFormPanel
from ui.window_utils import centrar_ventana_al_mostrar

Modo = Literal["ingreso", "salida", "actualizar_captura", "espera_reingreso"]

# Tres secciones: cámara | formulario | huella.
# Alto base generoso para emparejar el formulario central.
MODAL_ANCHO = 1280
MODAL_ALTO = 820
CAM_ANCHO = 360
# Alto contenido: deja espacio fijo abajo para barra de estado + acciones
# (ventana app ~820 px con topbar; 560 empujaba esos mensajes fuera de vista).
CAM_ALTO = 420
HUELLA_ANCHO = 360
HUELLA_ALTO = 420
CAM_INTERVALO_MS = 33  # ~30 fps

# Auto-identificación: revisar rostro cada N ticks (~165 ms) en el hilo
# principal (Tkinter no es thread-safe con OpenCV). Dos detecciones
# seguidas bastan tras bajar el umbral interno de YuNet (ver embeddings).
AUTO_DETECT_CADA_TICKS = 5
MIN_ROSTRO_CONSECUTIVOS = 2
MIN_CONFIANZA_ROSTRO = 0.22
COOLDOWN_TRAS_FALLO_MS = 2000

# El motor carga 2 modelos ONNX (~39MB) — se instancia una sola vez por
# proceso, no una vez por modal abierto (abrir/cerrar el modal repetidas
# veces no debe recargar los modelos cada vez).
_embedder_singleton = None


def _get_embedder():
    global _embedder_singleton
    if _embedder_singleton is None:
        from motor.embeddings import FaceEmbedder

        _embedder_singleton = FaceEmbedder()
    return _embedder_singleton


class FacialRecognitionPanel(ttk.Frame):
    """Cámara (izq.) + huella (der.) — usable embebido en página o en modal."""

    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        modo: Modo,
        on_registrado: Callable[[], None] | None = None,
        *,
        show_close_button: bool = False,
        on_close: Callable[[], None] | None = None,
    ) -> None:
        """
        `modo`: "ingreso" o "salida" — decide el endpoint de
        consultar/registrar al identificar.

        `on_registrado`: callback opcional tras un registro exitoso.
        `show_close_button` / `on_close`: solo para uso en Toplevel.
        """
        super().__init__(master, style="App.TFrame")
        self._client = client
        self._modo = modo
        self._on_registrado = on_registrado
        self._show_close_button = show_close_button
        self._on_close = on_close
        self._capturando = False
        self._camara: CameraSource | None = None
        self._after_id: str | None = None
        self._ultimo_frame = None
        # None = auto-detectar la primera disponible (comportamiento
        # previo); si el usuario elige una cámara puntual con el botón
        # 🎥, queda fija acá hasta que la cambie de nuevo.
        self._camara_indice_seleccionado: int | None = None
        self._frames_sin_senal = 0
        self._abriendo_camara = False
        self._tick_contador = 0
        self._identificando = False
        self._confirmacion_abierta = False
        self._rostro_consecutivos = 0
        self._cooldown_hasta_ms = 0.0
        self._confirmacion_modal: IdentificationConfirmationPanel | None = None
        self._motor_listo = False
        self._ultimo_embedding: list[float] | None = None
        self._ultimo_huella_b64: str | None = None
        self._huella_scan: HuellaScanCanvas | None = None
        self._huella_header_icon: ImageTk.PhotoImage | None = None
        self._form_panel: IngresoFormPanel | None = None
        self._centro_wrap: tk.Frame | None = None
        self._syncing_centro = False
        # 4=facial, 5=huella (tab_metodos_aut)
        self._ultimo_metodo_biometrico: int = 4

        self.columnconfigure(0, weight=1)
        # Solo la fila biométrica crece; estado y acciones quedan fijas abajo.
        self.rowconfigure(0, weight=1)
        self.rowconfigure(1, weight=0)
        self.rowconfigure(2, weight=0)
        self._build()
        self.bind("<Destroy>", self._on_destroy, add="+")
        self.after(150, self._iniciar_captura)

    def _on_destroy(self, event: tk.Event) -> None:
        if event.widget is not self:
            return
        # Solo liberar hardware: los widgets ya se están destruyendo.
        self._abriendo_camara = False
        self._capturando = False
        if self._after_id is not None:
            try:
                self.after_cancel(self._after_id)
            except tk.TclError:
                pass
            self._after_id = None
        if self._camara is not None:
            self._camara.liberar()
            self._camara = None
        if self._huella_scan is not None:
            self._huella_scan.stop()

    # ---- UI ---------------------------------------------------------

    def _build(self) -> None:
        # ---- Tres secciones: cámara | formulario | huella (fila 0) ----
        bio_row = tk.Frame(self, bg=theme.BG_DEEP)
        bio_row.grid(row=0, column=0, sticky="nsew", padx=12, pady=(12, 4))
        bio_row.columnconfigure(0, weight=1, minsize=CAM_ANCHO + 40)
        bio_row.columnconfigure(1, weight=1, minsize=300)
        bio_row.columnconfigure(2, weight=1, minsize=HUELLA_ANCHO + 40)
        bio_row.rowconfigure(0, weight=1)

        self._build_columna_camara(bio_row)
        self._build_columna_formulario(bio_row)
        self._build_columna_huella(bio_row)
        bio_row.bind("<Configure>", self._on_bio_row_configure, add="+")

        # ---- Estado (fila 1, altura fija — siempre visible) ----
        self._estado_var = tk.StringVar(value="Iniciando cámara...")
        estado_row = ttk.Frame(self, style="App.TFrame", padding=(16, 6))
        estado_row.grid(row=1, column=0, sticky="ew")
        self._estado_dot = tk.Canvas(
            estado_row, width=10, height=10, bg=theme.BG_DEEP, highlightthickness=0
        )
        self._estado_dot.pack(side="left", padx=(0, 8))
        self._estado_dot.create_oval(1, 1, 9, 9, fill=theme.TEXT_MUTED, outline="")
        ttk.Label(
            estado_row,
            textvariable=self._estado_var,
            style="Muted.TLabel",
            wraplength=1100,
        ).pack(side="left", fill="x", expand=True)

        # ---- Acciones (fila 2, altura fija — siempre visible) ----
        actions = ttk.Frame(self, style="App.TFrame", padding=(16, 8, 16, 12))
        actions.grid(row=2, column=0, sticky="ew")
        actions.columnconfigure(0, weight=1)
        if self._show_close_button:
            actions.columnconfigure(1, weight=1)

        self._toggle_btn = ttk.Button(
            actions,
            text="Iniciar captura",
            style="Primary.TButton",
            command=self._toggle_captura,
        )
        self._toggle_btn.grid(
            row=0,
            column=0,
            sticky="ew",
            padx=(0, 4) if self._show_close_button else 0,
        )

        if self._show_close_button:
            ttk.Button(
                actions, text="Cerrar", style="Nav.TButton", command=self._cerrar
            ).grid(row=0, column=1, sticky="ew", padx=(4, 0))

        self.after(30, self._cargar_catalogos_formulario)

    def _build_columna_camara(self, parent: tk.Frame) -> None:
        cam_wrap = tk.Frame(parent, bg=theme.BG_PANEL, padx=12, pady=12)
        cam_wrap.grid(row=0, column=0, sticky="nsew", padx=(0, 6))

        cam_header = tk.Frame(cam_wrap, bg=theme.BG_PANEL)
        cam_header.pack(fill="x", pady=(0, 8))

        self._camara_activa_var = tk.StringVar(value="Cámara: conectando...")
        ttk.Label(
            cam_header, textvariable=self._camara_activa_var, style="Muted.TLabel"
        ).pack(side="left")

        ttk.Button(
            cam_header,
            text="📷 Cambiar",
            style="Nav.TButton",
            command=self._seleccionar_camara,
        ).pack(side="right")

        # Botón anclado abajo primero: el canvas no puede aplastarlo.
        self._enrolar_btn = ttk.Button(
            cam_wrap,
            text="Capturar Rostro",
            style="Primary.TButton",
            command=self._enrolar,
        )
        self._enrolar_btn.pack(side="bottom", fill="x", pady=(10, 0), ipady=2)

        self._cam_canvas = tk.Canvas(
            cam_wrap,
            width=CAM_ANCHO,
            height=CAM_ALTO,
            bg="#000000",
            highlightthickness=1,
            highlightbackground=theme.BORDER,
        )
        self._cam_canvas.pack(fill="both", expand=True)
        self._cam_image_id: int | None = None
        self._draw_placeholder()
        self._cam_canvas.bind("<Configure>", self._on_cam_resize, add="+")

    def _build_columna_formulario(self, parent: tk.Frame) -> None:
        self._centro_wrap = tk.Frame(parent, bg=theme.BG_DEEP)
        self._centro_wrap.grid(row=0, column=1, sticky="nsew", padx=6)
        self._centro_wrap.columnconfigure(0, weight=1)
        self._centro_wrap.rowconfigure(0, weight=1)

        self._form_panel = IngresoFormPanel(
            self._centro_wrap,
            self._client,
            on_registrado=self._on_registrado,
            on_mensaje_estado=self._set_estado,
            on_ingreso_exitoso=self._mostrar_confirmacion_post_registro,
        )
        self._form_panel.grid(row=0, column=0, sticky="nsew")
        # Tras el primer layout, fija el tamaño de la columna central para que
        # «Persona encontrada» ocupe exactamente la misma caja.
        self.after_idle(self._fijar_tamano_columna_central)

    def _fijar_tamano_columna_central(self) -> None:
        """Congela ancho/alto de `_centro_wrap` al del formulario Nuevo ingreso."""
        if self._centro_wrap is None or self._form_panel is None:
            return
        try:
            if not self._form_panel.winfo_exists():
                return
            self._form_panel.update_idletasks()
            w = int(self._form_panel.winfo_width())
            h = int(self._form_panel.winfo_height())
            if w < 50 or h < 50:
                self.after(80, self._fijar_tamano_columna_central)
                return
            self._centro_wrap.grid_propagate(False)
            self._centro_wrap.configure(width=w, height=h)
        except tk.TclError:
            return

    def _on_bio_row_configure(self, _event: tk.Event | None = None) -> None:
        """Si el formulario está visible, re-sincroniza la caja central al layout."""
        if self._confirmacion_abierta or self._syncing_centro:
            return
        if self._form_panel is None or self._centro_wrap is None:
            return
        try:
            if not self._form_panel.winfo_ismapped():
                return
            self._syncing_centro = True
            # Reactivar propagate un instante para heredar el alto de cámara/huella.
            self._centro_wrap.grid_propagate(True)
            self._form_panel.update_idletasks()
            w = int(self._centro_wrap.winfo_width())
            h = int(self._centro_wrap.winfo_height())
            if w >= 50 and h >= 50:
                self._centro_wrap.grid_propagate(False)
                self._centro_wrap.configure(width=w, height=h)
        except tk.TclError:
            return
        finally:
            self._syncing_centro = False

    def _build_columna_huella(self, parent: tk.Frame) -> None:
        huella_wrap = tk.Frame(parent, bg=theme.BG_PANEL, padx=12, pady=12)
        huella_wrap.grid(row=0, column=2, sticky="nsew", padx=(6, 0))

        huella_header = tk.Frame(huella_wrap, bg=theme.BG_PANEL)
        huella_header.pack(fill="x", pady=(0, 8))

        ttk.Label(huella_header, text="Huella dactilar", style="Muted.TLabel").pack(
            side="left"
        )
        # Ícono ~tamaño del emoji 📷 del botón "Cambiar".
        self._huella_header_icon = self._photo_huella_icono(18)
        if self._huella_header_icon is not None:
            tk.Label(
                huella_header,
                image=self._huella_header_icon,
                bg=theme.BG_PANEL,
                borderwidth=0,
            ).pack(side="right")
        else:
            ttk.Label(huella_header, text="🖐", style="Muted.TLabel").pack(side="right")

        ttk.Button(
            huella_wrap,
            text="Capturar Huella",
            style="Primary.TButton",
            command=self._identificar_huella,
        ).pack(side="bottom", fill="x", pady=(10, 0), ipady=2)

        self._huella_scan = HuellaScanCanvas(
            huella_wrap, width=HUELLA_ANCHO, height=HUELLA_ALTO
        )
        self._huella_canvas = self._huella_scan  # compat. helpers de tamaño
        self._huella_scan.pack(fill="both", expand=True)
        self._huella_scan.start()
        self._sync_huella_mensaje()

    def _cargar_catalogos_formulario(self) -> None:
        if self._form_panel is None:
            return
        try:
            catalogos = self._client.catalogos()
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._set_estado(f"No se pudieron cargar catálogos: {exc}", theme.ERROR)
            return
        self._form_panel.cargar_catalogos(catalogos)

    def _documento_formulario(self) -> str:
        if self._form_panel is not None:
            return self._form_panel.documento()
        return ""

    def _tamano_canvas(
        self, canvas: tk.Canvas, fallback_w: int, fallback_h: int
    ) -> tuple[int, int]:
        w = int(canvas.winfo_width())
        h = int(canvas.winfo_height())
        if w < 40:
            w = fallback_w
        if h < 40:
            h = fallback_h
        return w, h

    def _on_cam_resize(self, _event: tk.Event | None = None) -> None:
        # Solo redibuja placeholder si no hay stream activo.
        if not self._capturando:
            self._draw_placeholder()

    def _photo_huella_icono(self, size_px: int = 18) -> ImageTk.PhotoImage | None:
        """Miniatura blanca de huella.png (mismo orden de tamaño que 📷)."""
        from ui.huella_scan import _ruta_huella_png

        ruta = _ruta_huella_png()
        if ruta is None:
            return None
        try:
            img = Image.open(ruta).convert("RGBA")
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
            img = Image.fromarray(arr, mode="RGBA")
            img.thumbnail((size_px, size_px), Image.Resampling.LANCZOS)
            return ImageTk.PhotoImage(img, master=self)
        except (OSError, ValueError, tk.TclError):
            return None

    def _sync_huella_mensaje(self) -> None:
        if self._huella_scan is None:
            return
        if self._ultimo_huella_b64:
            self._huella_scan.set_mensaje(
                "Plantilla capturada\n(listo para enrolar / identificar)",
                theme.SUCCESS,
            )
        else:
            self._huella_scan.set_mensaje(
                "Coloque el dedo índice derecho\nen el huellero.",
                theme.TEXT_MUTED,
            )

    def _draw_huella_placeholder(self) -> None:
        """Actualiza texto/estado del panel animado de huella."""
        self._sync_huella_mensaje()

    def _draw_placeholder(self, mensaje: str = "Sin señal de cámara") -> None:
        c = self._cam_canvas
        c.delete("all")
        self._cam_image_id = None
        w, h = self._tamano_canvas(c, CAM_ANCHO, CAM_ALTO)
        cx, cy = w // 2, h // 2
        c.create_oval(cx - 70, cy - 90, cx + 70, cy + 90, outline=theme.CYAN, dash=(5, 4), width=2)
        c.create_text(
            cx, cy + 120, text=mensaje, fill=theme.TEXT_MUTED, font=theme.FONT_LABEL_SMALL
        )

    def _set_estado(self, texto: str, color: str) -> None:
        self._estado_var.set(texto)
        self._estado_dot.itemconfig(1, fill=color)

    # ---- Captura de cámara -------------------------------------------

    def _toggle_captura(self) -> None:
        if self._capturando:
            self._detener_captura()
        else:
            self._iniciar_captura()

    def _iniciar_captura(self) -> None:
        if self._capturando or self._abriendo_camara:
            return

        indice = self._camara_indice_seleccionado
        if indice is None:
            indice = 0

        self._abriendo_camara = True
        self._set_estado("Conectando cámara...", theme.CYAN)
        self._camara_activa_var.set(f"Cámara: {indice}")
        threading.Thread(
            target=self._abrir_camara_en_hilo,
            args=(indice,),
            daemon=True,
        ).start()

    def _abrir_camara_en_hilo(self, indice: int) -> None:
        camara = CameraSource(indice)
        ok = camara.abrir()
        indice_final = indice

        if not ok and self._camara_indice_seleccionado is None:
            alterno = detectar_camara_disponible(preferido=None)
            if alterno is not None and alterno != indice:
                camara.liberar()
                indice_final = alterno
                camara = CameraSource(indice_final)
                ok = camara.abrir()

        self.after(0, lambda: self._finalizar_apertura_camara(indice_final, camara, ok))

    def _finalizar_apertura_camara(
        self, indice: int, camara: CameraSource, ok: bool
    ) -> None:
        self._abriendo_camara = False

        if self._capturando:
            camara.liberar()
            return

        if not ok:
            self._set_estado(
                "No se pudo abrir la cámara — verifique que no la use otra aplicación.",
                theme.ERROR,
            )
            self._draw_placeholder("Cámara no disponible")
            return

        self._camara = camara
        self._capturando = True
        self._frames_sin_senal = 0
        self._toggle_btn.configure(text="Detener")
        self._camara_activa_var.set(f"Cámara: {indice}")
        self._precargar_motor()
        self._cam_canvas.delete("all")
        self._cam_image_id = None
        self._tick_contador = 0
        self._rostro_consecutivos = 0
        self._tick_camara()

    def _precargar_motor(self) -> None:
        if self._motor_listo:
            return
        self._set_estado("Cargando motor de reconocimiento...", theme.CYAN)
        self.update()
        try:
            _get_embedder()
        except FileNotFoundError as exc:
            self._set_estado(str(exc), theme.ERROR)
            return
        except cv2.error as exc:
            self._set_estado(
                "Motor biométrico no disponible. Reinicie la aplicación "
                f"o contacte al administrador. ({exc})",
                theme.ERROR,
            )
            return
        except Exception as exc:
            self._set_estado(f"Motor biométrico no disponible: {exc}", theme.ERROR)
            return
        self._motor_listo = True
        indice = self._camara_indice_seleccionado
        if indice is None:
            indice = 0
        self._set_estado(
            f"Cámara activa (índice {indice}). Acérquese al lente.",
            theme.CYAN,
        )

    def _seleccionar_camara(self) -> None:
        """Escanea los índices de video disponibles (periféricos
        externos incluidos, no solo la cámara por defecto del equipo)
        y abre un diálogo para que el usuario elija cuál usar."""
        estaba_capturando = self._capturando
        if estaba_capturando:
            self._detener_captura()

        self._set_estado("🔍 Buscando cámaras conectadas...", theme.CYAN)
        self.update()

        indices = listar_camaras_disponibles()
        if not indices:
            self._set_estado(
                "No se detectó ninguna cámara en este equipo.", theme.ERROR
            )
            self._draw_placeholder("Cámara no disponible")
            messagebox.showwarning(
                "Sin cámaras",
                "No se detectó ninguna cámara conectada al equipo.",
            )
            return

        self._abrir_dialogo_camaras(indices)

    def _abrir_dialogo_camaras(self, indices: list[int]) -> None:
        dialogo = tk.Toplevel(self)
        dialogo.title("Elegir cámara")
        dialogo.configure(bg=theme.BG_CARD)
        dialogo.resizable(False, False)
        dialogo.transient(self)
        dialogo.grab_set()

        ttk.Label(
            dialogo,
            text="Cámaras detectadas",
            style="Card.TLabel",
            font=theme.FONT_TITLE,
        ).pack(anchor="w", padx=16, pady=(16, 4))
        ttk.Label(
            dialogo,
            text="Elija cuál usar para el reconocimiento facial.",
            style="CardMuted.TLabel",
        ).pack(anchor="w", padx=16, pady=(0, 12))

        actual = self._camara_indice_seleccionado
        valor_inicial = actual if actual in indices else indices[0]
        seleccion_var = tk.IntVar(value=valor_inicial)

        for indice in indices:
            etiqueta = f"Cámara {indice}"
            if indice == 0:
                etiqueta += " (por defecto del equipo)"
            ttk.Radiobutton(
                dialogo, text=etiqueta, value=indice, variable=seleccion_var
            ).pack(anchor="w", padx=24, pady=2)

        botones = ttk.Frame(dialogo, style="App.TFrame", padding=16)
        botones.pack(fill="x")

        def _confirmar() -> None:
            self._camara_indice_seleccionado = seleccion_var.get()
            self._camara_activa_var.set(
                f"Cámara: {self._camara_indice_seleccionado}"
            )
            dialogo.destroy()
            self._iniciar_captura()

        ttk.Button(
            botones, text="Usar esta cámara", style="Primary.TButton",
            command=_confirmar,
        ).pack(side="left", padx=(0, 8))
        ttk.Button(
            botones, text="Cancelar", style="Nav.TButton",
            command=dialogo.destroy,
        ).pack(side="left")

    def _tick_camara(self) -> None:
        if not self._capturando or self._camara is None:
            return

        frame = self._camara.leer_frame()
        if frame is not None:
            self._frames_sin_senal = 0
            self._ultimo_frame = frame
            photo = frame_a_photoimage(
                frame, *self._tamano_canvas(self._cam_canvas, CAM_ANCHO, CAM_ALTO)
            )
            self._cam_photo_ref = photo  # evita garbage collection
            if self._cam_image_id is None:
                self._cam_image_id = self._cam_canvas.create_image(
                    0, 0, anchor="nw", image=photo
                )
            else:
                self._cam_canvas.itemconfig(self._cam_image_id, image=photo)
            self._tick_contador += 1
            self._evaluar_auto_identificacion(frame)
        else:
            self._frames_sin_senal += 1
            if self._frames_sin_senal >= 45:
                self._set_estado(
                    "La cámara dejó de entregar imagen — pruebe otra con 📷 Cambiar cámara.",
                    theme.ERROR,
                )
                self._draw_placeholder("Sin señal de cámara")
                self._detener_captura()
                return

        self._after_id = self.after(CAM_INTERVALO_MS, self._tick_camara)

    def _evaluar_auto_identificacion(self, frame: np.ndarray) -> None:
        if (
            not self._motor_listo
            or self._identificando
            or self._confirmacion_abierta
            or time.monotonic() * 1000 < self._cooldown_hasta_ms
        ):
            return
        if self._tick_contador % AUTO_DETECT_CADA_TICKS != 0:
            return

        try:
            confianza = _get_embedder().detectar_confianza(frame)
        except Exception as exc:
            self._set_estado(f"Motor biométrico: {exc}", theme.ERROR)
            return

        self._on_rostro_chequeado(confianza)

    def _on_rostro_chequeado(self, confianza: float | None) -> None:
        if not self.winfo_exists() or not self._capturando:
            return
        if self._identificando or self._confirmacion_abierta:
            return

        indice = self._camara_indice_seleccionado
        if indice is None:
            indice = 0

        if confianza is not None and confianza >= MIN_CONFIANZA_ROSTRO:
            self._rostro_consecutivos += 1
            pct = int(confianza * 100)
            if self._rostro_consecutivos >= MIN_ROSTRO_CONSECUTIVOS:
                self._set_estado("Rostro detectado — identificando...", theme.CYAN)
                self._identificar(auto=True)
                return
            self._set_estado(
                f"Rostro detectado ({pct}%) — confirmando...",
                theme.CYAN,
            )
            return

        self._rostro_consecutivos = 0
        if confianza is not None and confianza >= 0.25:
            pct = int(confianza * 100)
            self._set_estado(
                f"Detectando rostro ({pct}%) — acérquese un poco más.",
                theme.CYAN,
            )
            return
        self._set_estado(
            f"Cámara activa (índice {indice}). Acérquese al lente.",
            theme.CYAN,
        )

    def _detener_captura(self) -> None:
        self._abriendo_camara = False
        self._capturando = False
        if self._after_id is not None:
            self.after_cancel(self._after_id)
            self._after_id = None
        if self._camara is not None:
            self._camara.liberar()
            self._camara = None
        self._ultimo_frame = None
        self._tick_contador = 0
        self._rostro_consecutivos = 0
        self._identificando = False
        self._toggle_btn.configure(text="Iniciar captura")
        self._set_estado("En espera — inicie la captura.", theme.TEXT_MUTED)
        self._draw_placeholder()

    # ---- Extracción del vector (motor) --------------------------------

    def _extraer_embedding(self) -> tuple[list[float], float] | None:
        if self._ultimo_frame is None:
            self._set_estado("Inicie la captura de cámara primero.", theme.ERROR)
            return None

        try:
            embedder = _get_embedder()
        except FileNotFoundError as exc:
            self._set_estado(str(exc), theme.ERROR)
            return None

        resultado = embedder.extraer(self._ultimo_frame)
        if resultado is None:
            self._set_estado("No se detectó ningún rostro en la imagen — acérquese a la cámara.", theme.ERROR)
            return None

        return resultado

    # ---- Enrolar (con foto — 2026-07-09) --------------------------------

    def _frame_a_base64(self, frame: np.ndarray) -> str:
        """Convierte frame OpenCV (BGR) a base64 JPG.

        E2: Foto se codifica en base64 para transmitir al servidor sin
        dependencias de terceros (urllib + stdlib). El servidor validará
        que sea imagen válida.
        """
        try:
            # Convertir BGR (OpenCV) → RGB (PIL)
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            pil_image = Image.fromarray(frame_rgb)

            # Guardar a buffer JPG
            buffer = io.BytesIO()
            pil_image.save(buffer, format="JPEG", quality=85)
            buffer.seek(0)

            # Codificar a base64
            foto_base64 = base64.b64encode(buffer.read()).decode("utf-8")
            return foto_base64
        except Exception as e:
            self._set_estado(f"Error capturando foto: {e}", theme.ERROR)
            return ""

    def _enrolar(self) -> None:
        documento = self._documento_formulario()
        if not documento:
            self._set_estado("Ingrese un número de documento antes de enrolar.", theme.ERROR)
            if self._form_panel is not None:
                self._form_panel.focus_documento()
            return

        extraido = self._extraer_embedding()
        if extraido is None:
            return
        embedding, calidad = extraido

        # Capturar foto del último frame (2026-07-09)
        self._set_estado("📸 Capturando foto y enrolando...", theme.CYAN)
        self.update()  # Refrescar UI inmediatamente

        foto_base64 = ""
        if self._ultimo_frame is not None:
            foto_base64 = self._frame_a_base64(self._ultimo_frame)

        self._enrolar_btn.state(["disabled"])
        try:
            # Enviar con foto si se capturó (E2, E6: validación)
            self._client.biometria_enrolar(documento, embedding, calidad, foto_base64 or None)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._set_estado(f"Error al enrolar: {exc}", theme.ERROR)
            return
        finally:
            self._enrolar_btn.state(["!disabled"])

        self._set_estado(f"✅ Rostro enrolado para {documento} (calidad {calidad}%).", theme.SUCCESS)

    # ---- Huella (plantilla → tab_personas.val_huella_digital) ------------

    def _simular_captura_huella(self) -> None:
        from motor.huella import capturar_template_prueba, template_a_base64

        documento = self._documento_formulario()
        try:
            template = capturar_template_prueba(documento)
            self._ultimo_huella_b64 = template_a_base64(template)
        except ValueError as exc:
            self._set_estado(str(exc), theme.ERROR)
            if self._form_panel is not None:
                self._form_panel.focus_documento()
            return
        self._draw_huella_placeholder()
        self._set_estado(
            f"Huella simulada para documento {documento} (listo).",
            theme.SUCCESS,
        )

    def _enrolar_huella(self) -> None:
        documento = self._documento_formulario()
        if not documento:
            self._set_estado("Ingrese el documento antes de enrolar la huella.", theme.ERROR)
            if self._form_panel is not None:
                self._form_panel.focus_documento()
            return
        if not self._ultimo_huella_b64:
            self._simular_captura_huella()
            if not self._ultimo_huella_b64:
                return
        try:
            self._client.biometria_huella_enrolar(documento, self._ultimo_huella_b64)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._set_estado(f"Error al enrolar huella: {exc}", theme.ERROR)
            return
        self._set_estado(f"✅ Huella enrolada para {documento}.", theme.SUCCESS)

    def _identificar_huella(self) -> None:
        if self._identificando or self._confirmacion_abierta:
            return
        if not self._ultimo_huella_b64:
            self._simular_captura_huella()
            if not self._ultimo_huella_b64:
                return

        self._identificando = True
        self._ultimo_metodo_biometrico = 5
        if self._huella_scan is not None:
            self._huella_scan.set_exito(False)
            self._huella_scan.set_mensaje("Escaneando huella...", theme.CYAN)
        self._set_estado("🔍 Identificando por huella...", theme.CYAN)
        self.update()

        try:
            resultado = self._client.biometria_huella_identificar(self._ultimo_huella_b64)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            if self._huella_scan is not None:
                self._huella_scan.set_exito(False)
            self._set_estado(f"Error al identificar huella: {exc}", theme.ERROR)
            self._identificando = False
            return

        if not resultado.get("match"):
            if self._huella_scan is not None:
                self._huella_scan.set_exito(False)
                self._huella_scan.set_mensaje(
                    "Huella no reconocida", theme.ERROR
                )
            self._set_estado("❌ Huella no reconocida — no está enrolada.", theme.ERROR)
            self._identificando = False
            return

        persona_datos = dict(resultado.get("persona") or {})
        documento = str(
            persona_datos.get("documento")
            or persona_datos.get("id_persona")
            or ""
        )
        try:
            modo_efectivo = self._resolver_modo_acceso(documento)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            if self._huella_scan is not None:
                self._huella_scan.set_exito(False)
            self._set_estado(f"Error al consultar acceso: {exc}", theme.ERROR)
            self._identificando = False
            return

        if resultado.get("foto_base64"):
            persona_datos["foto_base64"] = resultado.get("foto_base64")
        persona_datos["_modo_acceso"] = modo_efectivo

        if modo_efectivo == "espera_reingreso":
            self._avisar_espera_reingreso(documento, desde_huella=True)
            return

        accion = self._etiqueta_accion(modo_efectivo)
        if self._huella_scan is not None:
            self._huella_scan.set_exito(True)
            self._huella_scan.set_mensaje(
                f"Identificado — {accion}", theme.SUCCESS
            )
        self._set_estado(
            f"✅ Identificado por huella — {accion}...",
            theme.SUCCESS,
        )
        self._mostrar_confirmacion_centro(persona_datos, modo_efectivo)

    def _mostrar_confirmacion_centro(
        self, persona_datos: dict, modo_efectivo: Modo
    ) -> None:
        """Sustituye temporalmente el formulario por «Persona encontrada» (~2.5 s)."""
        if self._centro_wrap is None:
            return
        self._fijar_tamano_columna_central()
        if self._confirmacion_modal is not None:
            try:
                self._confirmacion_modal.destroy()
            except tk.TclError:
                pass
            self._confirmacion_modal = None

        if self._form_panel is not None:
            self._form_panel.grid_remove()

        self._confirmacion_abierta = True
        self._identificando = False
        panel = IdentificationConfirmationPanel(
            self._centro_wrap,
            self._client,
            persona_datos,
            modo=modo_efectivo,
            on_confirmar=self._on_confirmacion_modal,
            auto_registro=True,
            persona_existente=True,
            on_cerrado=self._restaurar_formulario_central,
        )
        panel.grid(row=0, column=0, sticky="nsew")
        self._confirmacion_modal = panel

    def _mostrar_confirmacion_post_registro(
        self, persona_datos: dict[str, Any]
    ) -> None:
        """Tras Registrar ingreso (manual): mismo panel, sin volver a registrar."""
        if self._centro_wrap is None:
            return
        self._fijar_tamano_columna_central()
        if self._confirmacion_modal is not None:
            try:
                self._confirmacion_modal.destroy()
            except tk.TclError:
                pass
            self._confirmacion_modal = None

        if self._form_panel is not None:
            self._form_panel.grid_remove()

        self._confirmacion_abierta = True
        self._identificando = False
        era_existente = bool(persona_datos.pop("_persona_existente", False))
        panel = IdentificationConfirmationPanel(
            self._centro_wrap,
            self._client,
            persona_datos,
            modo="registrado",
            on_confirmar=None,
            auto_registro=True,
            persona_existente=era_existente,
            on_cerrado=self._restaurar_formulario_central,
        )
        panel.grid(row=0, column=0, sticky="nsew")
        self._confirmacion_modal = panel

    def _restaurar_formulario_central(self) -> None:
        """Vuelve al formulario vacío tras el panel de confirmación."""
        self._confirmacion_modal = None
        self._confirmacion_abierta = False
        self._rostro_consecutivos = 0
        self._ultimo_embedding = None
        self._cooldown_hasta_ms = time.monotonic() * 1000 + 1500
        if self._form_panel is not None and self._form_panel.winfo_exists():
            self._form_panel.limpiar()
            self._form_panel.grid()
        if self._on_registrado is not None:
            self._on_registrado()
        indice = self._camara_indice_seleccionado
        if indice is None:
            indice = 0
        if self._capturando and self.winfo_exists():
            self._set_estado(
                f"Cámara activa (índice {indice}). Acérquese al lente.",
                theme.CYAN,
            )

    def _identificar(self, *, auto: bool = False) -> None:
        if self._identificando or self._confirmacion_abierta:
            return

        extraido = self._extraer_embedding()
        if extraido is None:
            if auto:
                self._cooldown_hasta_ms = (
                    time.monotonic() * 1000 + COOLDOWN_TRAS_FALLO_MS
                )
            return

        embedding, _calidad = extraido
        self._identificando = True
        self._rostro_consecutivos = 0
        self._ultimo_embedding = list(embedding)
        self._ultimo_metodo_biometrico = 4

        self._set_estado("🔍 Buscando en base de datos...", theme.CYAN)
        self.update()

        try:
            resultado = self._client.biometria_identificar(embedding)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._set_estado(f"Error al identificar: {exc}", theme.ERROR)
            self._identificando = False
            self._cooldown_hasta_ms = time.monotonic() * 1000 + COOLDOWN_TRAS_FALLO_MS
            return

        if not resultado.get("match"):
            self._set_estado("❌ Rostro no reconocido — no está enrolado.", theme.ERROR)
            self._identificando = False
            self._cooldown_hasta_ms = time.monotonic() * 1000 + COOLDOWN_TRAS_FALLO_MS
            return

        persona_datos = dict(resultado.get("persona") or {})
        documento = str(
            persona_datos.get("documento")
            or persona_datos.get("num_docum")
            or persona_datos.get("id_persona")
            or ""
        )

        try:
            modo_efectivo = self._resolver_modo_acceso(documento)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._set_estado(f"Error al consultar acceso: {exc}", theme.ERROR)
            self._identificando = False
            self._cooldown_hasta_ms = time.monotonic() * 1000 + COOLDOWN_TRAS_FALLO_MS
            return

        if resultado.get("foto_base64"):
            persona_datos["foto_base64"] = resultado.get("foto_base64")
        elif self._ultimo_frame is not None:
            persona_datos["foto_base64"] = self._frame_a_base64(self._ultimo_frame)

        persona_datos["_modo_acceso"] = modo_efectivo

        if modo_efectivo == "espera_reingreso":
            self._avisar_espera_reingreso(documento, desde_huella=False)
            return

        accion = self._etiqueta_accion(modo_efectivo)
        self._set_estado(
            f"✅ Identificado — {accion}...",
            theme.SUCCESS,
        )
        self._mostrar_confirmacion_centro(persona_datos, modo_efectivo)

    def _avisar_espera_reingreso(
        self, documento: str, *, desde_huella: bool = False
    ) -> None:
        """Cooldown post-salida: aviso sin modal ni PII; formulario visible."""
        consulta = self._client.ingreso_consultar(documento, "CC")
        rest = int(consulta.get("segundos_restantes_reingreso") or 0)
        min_rest = max(1, (rest + 59) // 60)
        msg = (
            f"Salida reciente: espere ~{min_rest} min para un nuevo ingreso "
            "(mínimo 5 min)."
        )
        if desde_huella and self._huella_scan is not None:
            self._huella_scan.set_exito(True)
            self._huella_scan.set_mensaje("Espere 5 min", theme.CYAN)
        self._set_estado(f"⏳ {msg}", theme.CYAN)
        self._identificando = False
        self._confirmacion_abierta = False
        self._rostro_consecutivos = 0
        self._ultimo_embedding = None
        self._cooldown_hasta_ms = time.monotonic() * 1000 + 2000
        if self._form_panel is not None and self._form_panel.winfo_exists():
            self._form_panel.limpiar()
            self._form_panel.grid()
        if self._on_registrado is not None:
            self._on_registrado()

    @staticmethod
    def _etiqueta_accion(modo: Modo) -> str:
        if modo == "ingreso":
            return "se registrará ingreso"
        if modo == "salida":
            return "se registrará salida"
        if modo == "espera_reingreso":
            return "espere 5 min para un nuevo ingreso"
        return "se actualizará la captura del ingreso"

    def _resolver_modo_acceso(self, documento: str) -> Modo:
        """Ingreso / actualizar captura / salida / espera post-salida."""
        if not documento:
            raise SmartcsetApiError("Documento vacío tras la identificación.")
        consulta = self._client.ingreso_consultar(documento, "CC")
        if consulta.get("en_ventana_recaptura") or consulta.get("puede_actualizar_captura"):
            return "actualizar_captura"
        if consulta.get("puede_salir"):
            return "salida"
        if consulta.get("en_espera_reingreso"):
            return "espera_reingreso"
        if consulta.get("puede_ingresar"):
            return "ingreso"
        return "espera_reingreso"

    def _on_confirmacion_modal(self, persona_datos: dict) -> None:
        """Acción al confirmar el panel (auto ~2.5 s o botón)."""
        documento = str(
            persona_datos.get("documento") or persona_datos.get("num_docum") or ""
        )
        nombre = (
            f"{persona_datos.get('nombres', '')} {persona_datos.get('apellidos', '')}"
        ).strip()

        modo = self._resolver_modo_acceso(documento)
        if modo == "espera_reingreso":
            self._avisar_espera_reingreso(documento)
            return

        try:
            if modo == "ingreso":
                self._registrar_ingreso_identificado(documento, nombre, persona_datos)
            elif modo == "actualizar_captura":
                self._actualizar_captura_identificada(documento, nombre)
            else:
                self._registrar_salida_identificada(documento, nombre)
        except (SmartcsetApiError, SmartcsetConnectionError):
            consulta = self._client.ingreso_consultar(documento, "CC")
            if consulta.get("puede_actualizar_captura") or consulta.get(
                "en_ventana_recaptura"
            ):
                self._actualizar_captura_identificada(documento, nombre)
            elif consulta.get("en_espera_reingreso"):
                self._avisar_espera_reingreso(documento)
            else:
                raise

    def _payload_biometrico_basico(self, documento: str, nombre: str = "") -> dict:
        metodo = self._ultimo_metodo_biometrico
        obs = (
            "Re-captura por huella dactilar."
            if metodo == 5
            else "Re-captura por reconocimiento facial."
        )
        payload: dict = {
            "tipo_doc": "CC",
            "documento": documento,
            "observaciones": obs,
            "metodo_aut": metodo,
        }
        if metodo == 4 and self._ultimo_embedding is not None:
            payload["embedding"] = self._ultimo_embedding
        if metodo == 5 and self._ultimo_huella_b64:
            payload["huella_template_b64"] = self._ultimo_huella_b64
        return payload

    def _registrar_ingreso_identificado(
        self, documento: str, nombre: str, persona_datos: dict | None = None
    ) -> None:
        consulta = self._client.ingreso_consultar(documento, "CC")
        if consulta.get("puede_actualizar_captura"):
            self._actualizar_captura_identificada(documento, nombre)
            return
        if not consulta.get("puede_ingresar"):
            if consulta.get("puede_salir"):
                self._registrar_salida_identificada(documento, nombre)
                return
            if consulta.get("en_espera_reingreso"):
                rest = int(consulta.get("segundos_restantes_reingreso") or 0)
                min_rest = max(1, (rest + 59) // 60)
                msg = (
                    f"Debe esperar ~{min_rest} min tras la salida "
                    "para un nuevo ingreso."
                )
                self._set_estado(f"⏳ {msg}", theme.CYAN)
                raise SmartcsetApiError(msg)
            if consulta.get("puede_actualizar_captura"):
                self._actualizar_captura_identificada(documento, nombre)
                return
            msg = f"{nombre}: no se puede registrar ingreso en este momento."
            self._set_estado(msg, theme.CYAN)
            raise SmartcsetApiError(msg)

        # Puerta: primera del catálogo hasta config local por PC.
        entradas = self._client.catalogos().get("entradas", [])
        if not entradas:
            self._set_estado("No hay puertas configuradas en el catálogo.", theme.ERROR)
            raise SmartcsetApiError("No hay puertas configuradas en el catálogo.")

        persona = persona_datos or consulta.get("persona") or {}
        metodo = self._ultimo_metodo_biometrico
        obs = (
            "Identificado por huella dactilar."
            if metodo == 5
            else "Identificado por reconocimiento facial."
        )
        payload: dict = {
            "tipo_doc": "CC",
            "documento": documento,
            "nombres": persona.get("nombres", ""),
            "apellidos": persona.get("apellidos", ""),
            "tipo_persona": persona.get("tipo_persona", 0),
            "id_entrada": entradas[0]["id"],
            "observaciones": obs,
            "metodo_aut": metodo,
        }
        if metodo == 4 and self._ultimo_embedding is not None:
            payload["embedding"] = self._ultimo_embedding
        if metodo == 5 and self._ultimo_huella_b64:
            payload["huella_template_b64"] = self._ultimo_huella_b64

        self._client.ingreso_registrar(payload)
        if metodo == 5 and self._huella_scan is not None:
            self._huella_scan.set_exito(True)
            self._huella_scan.set_mensaje(
                f"Ingreso OK\n{nombre}", theme.SUCCESS
            )
        self._set_estado(f"Ingreso registrado: {nombre}.", theme.SUCCESS)

    def _actualizar_captura_identificada(self, documento: str, nombre: str) -> None:
        metodo = self._ultimo_metodo_biometrico
        payload = self._payload_biometrico_basico(documento, nombre)
        if "embedding" not in payload and "huella_template_b64" not in payload:
            raise SmartcsetApiError(
                "No hay captura biométrica para actualizar el ingreso."
            )

        self._client.ingreso_actualizar_captura(payload)
        if metodo == 5 and self._huella_scan is not None:
            self._huella_scan.set_exito(True)
            self._huella_scan.set_mensaje(
                f"Captura OK\n{nombre}", theme.SUCCESS
            )
        self._set_estado(
            f"Captura actualizada: {nombre}.",
            theme.SUCCESS,
        )

    def _registrar_salida_identificada(self, documento: str, nombre: str) -> None:
        consulta = self._client.salida_consultar(documento, "CC")
        if not consulta.get("puede_salir"):
            rest = int(consulta.get("segundos_restantes_salida") or 0)
            if rest > 0 or consulta.get("ingreso_abierto"):
                # Aún dentro de la ventana mínima → actualizar captura, no error.
                self._actualizar_captura_identificada(documento, nombre)
                return
            self._set_estado(
                f"{nombre}: no tiene un ingreso abierto para registrar salida.",
                theme.ERROR,
            )
            raise SmartcsetApiError(
                f"{nombre}: no tiene un ingreso abierto para registrar salida."
            )

        metodo = self._ultimo_metodo_biometrico
        obs = (
            "Identificado por huella dactilar."
            if metodo == 5
            else "Identificado por reconocimiento facial."
        )
        self._client.salida_registrar(
            {
                "tipo_doc": "CC",
                "documento": documento,
                "observaciones": obs,
                "metodo_aut": metodo,
            }
        )
        if metodo == 5 and self._huella_scan is not None:
            self._huella_scan.set_exito(True)
            self._huella_scan.set_mensaje(
                f"Salida OK\n{nombre}", theme.SUCCESS
            )
        self._set_estado(f"Salida registrada: {nombre}.", theme.SUCCESS)

    def _cerrar(self) -> None:
        self._detener_captura()
        if self._on_close is not None:
            self._on_close()


class FacialRecognitionModal(tk.Toplevel):
    """Toplevel opcional que reutiliza FacialRecognitionPanel."""

    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        modo: Modo,
        on_registrado: Callable[[], None] | None = None,
    ) -> None:
        super().__init__(master)
        self.title("Identificar rostro — Portería (ingreso / salida)")
        self.configure(bg=theme.BG_CARD)
        self.geometry(f"{MODAL_ANCHO}x{MODAL_ALTO}")
        self.resizable(False, False)
        self.transient(master)
        self.grab_set()
        self.protocol("WM_DELETE_WINDOW", self._cerrar)

        self._panel = FacialRecognitionPanel(
            self,
            client,
            modo=modo,
            on_registrado=on_registrado,
            show_close_button=True,
            on_close=self._cerrar,
        )
        self._panel.pack(fill="both", expand=True)
        centrar_ventana_al_mostrar(self, MODAL_ANCHO, MODAL_ALTO)

    def _cerrar(self) -> None:
        try:
            self.grab_release()
        except tk.TclError:
            pass
        self.destroy()
