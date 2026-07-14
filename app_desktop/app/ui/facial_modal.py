"""
Panel / modal "Reconocimiento biométrico" — flujo único de portería.

`FacialRecognitionPanel` es el layout fijo (cámara izquierda + huella
derecha). `FacialRecognitionModal` es un Toplevel opcional que reutiliza
el mismo panel (p. ej. desde la página de salida).

Tras identificar un rostro, consulta `ingreso/consultar.php`:
  - si puede ingresar → registra ingreso
  - si ya tiene ingreso abierto → registra salida (sin mensaje de error)

ESTADO: flujo completo real (facial). Huella: solo UI por ahora.
1. Cámara en vivo (`ui/camera.py`, OpenCV).
2. Motor de embeddings (`motor/embeddings.py`, SFace + YuNet).
3. "Enrolar": documento + frame → `biometria/enrolar.php`.
4. "Identificar": frame → `biometria/identificar.php` → modal de
   confirmación → ingreso o salida según estado en BD (`metodo_aut=4`).
"""
from __future__ import annotations

import base64
import io
import threading
import time
import tkinter as tk
from tkinter import ttk
from typing import Callable, Literal

import cv2
import numpy as np
from PIL import Image

from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError
from tkinter import messagebox
from ui import theme
from ui.camera import (
    CameraSource,
    detectar_camara_disponible,
    frame_a_photoimage,
    listar_camaras_disponibles,
)
from ui.identification_confirmation_modal import IdentificationConfirmationModal
from ui.window_utils import centrar_ventana_al_mostrar

Modo = Literal["ingreso", "salida"]

# Tres secciones: cámara | formulario | huella.
# Alto base generoso para emparejar el formulario central.
MODAL_ANCHO = 1280
MODAL_ALTO = 820
CAM_ANCHO = 360
CAM_ALTO = 560
HUELLA_ANCHO = 360
HUELLA_ALTO = 560
CAM_INTERVALO_MS = 33  # ~30 fps

# Auto-identificación: revisar rostro cada N ticks (~165 ms) en el hilo
# principal (Tkinter no es thread-safe con OpenCV). Dos detecciones
# seguidas bastan tras bajar el umbral interno de YuNet (ver embeddings).
AUTO_DETECT_CADA_TICKS = 5
MIN_ROSTRO_CONSECUTIVOS = 2
MIN_CONFIANZA_ROSTRO = 0.45
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
        self._confirmacion_modal: IdentificationConfirmationModal | None = None
        self._motor_listo = False
        self._ultimo_embedding: list[float] | None = None

        self.columnconfigure(0, weight=1)
        self.rowconfigure(0, weight=1)
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

    # ---- UI ---------------------------------------------------------

    def _build(self) -> None:
        header = ttk.Frame(self, style="Card.TFrame", padding=(16, 12, 16, 8))
        header.pack(fill="x")
        ttk.Label(
            header,
            text="📷  Reconocimiento biométrico",
            style="Card.TLabel",
            font=theme.FONT_TITLE,
        ).pack(anchor="w")
        ttk.Label(
            header,
            text=(
                "Izquierda: cámara · Centro: formulario de ingreso nuevo · "
                "Derecha: huella (solo visual)"
            ),
            style="CardMuted.TLabel",
        ).pack(anchor="w", pady=(2, 0))

        # ---- Tres secciones fijas: cámara | formulario | huella ----
        bio_row = tk.Frame(self, bg=theme.BG_DEEP)
        bio_row.pack(fill="both", expand=True, padx=12, pady=8)
        bio_row.columnconfigure(0, weight=1, minsize=CAM_ANCHO + 40)
        bio_row.columnconfigure(1, weight=1, minsize=300)
        bio_row.columnconfigure(2, weight=1, minsize=HUELLA_ANCHO + 40)
        bio_row.rowconfigure(0, weight=1)

        self._build_columna_camara(bio_row)
        self._build_columna_formulario(bio_row)
        self._build_columna_huella(bio_row)

        # ---- Estado ----
        self._estado_var = tk.StringVar(value="Iniciando cámara...")
        estado_row = ttk.Frame(self, style="App.TFrame", padding=(16, 0))
        estado_row.pack(fill="x")
        self._estado_dot = tk.Canvas(
            estado_row, width=10, height=10, bg=theme.BG_DEEP, highlightthickness=0
        )
        self._estado_dot.pack(side="left", padx=(0, 8))
        self._estado_dot.create_oval(1, 1, 9, 9, fill=theme.TEXT_MUTED, outline="")
        ttk.Label(estado_row, textvariable=self._estado_var, style="Muted.TLabel").pack(
            side="left"
        )

        # ---- Acciones ----
        actions = ttk.Frame(self, style="App.TFrame", padding=(16, 12))
        actions.pack(fill="x")
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
            text="🎥 Cambiar",
            style="Nav.TButton",
            command=self._seleccionar_camara,
        ).pack(side="right")

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
        form_wrap = tk.Frame(parent, bg=theme.BG_PANEL, padx=14, pady=12)
        form_wrap.grid(row=0, column=1, sticky="nsew", padx=6)

        ttk.Label(
            form_wrap,
            text="Ingreso de persona nueva",
            style="Card.TLabel",
            font=theme.FONT_BODY_BOLD,
        ).pack(anchor="w")
        ttk.Label(
            form_wrap,
            text="Complete los datos y registre o enrolar el rostro.",
            style="CardMuted.TLabel",
        ).pack(anchor="w", pady=(2, 10))

        self._catalogos: dict = {
            "tipos_doc": [],
            "tipos_persona": [],
            "entradas": [],
        }
        self._tipo_doc_map: dict[str, str] = {}
        self._tipo_persona_map: dict[str, int] = {}
        self._entrada_map: dict[str, int] = {}
        self._form_msg_var = tk.StringVar(value="")

        def _campo(lbl: str) -> None:
            ttk.Label(form_wrap, text=lbl, style="Card.TLabel").pack(anchor="w", pady=(6, 2))

        _campo("Tipo de documento")
        self._tipo_doc_combo = ttk.Combobox(form_wrap, state="readonly")
        self._tipo_doc_combo.pack(fill="x")

        _campo("Número de documento")
        self._documento_var = tk.StringVar()
        self._documento_entry = ttk.Entry(form_wrap, textvariable=self._documento_var)
        self._documento_entry.pack(fill="x")

        _campo("Nombres")
        self._nombres_var = tk.StringVar()
        ttk.Entry(form_wrap, textvariable=self._nombres_var).pack(fill="x")

        _campo("Apellidos")
        self._apellidos_var = tk.StringVar()
        ttk.Entry(form_wrap, textvariable=self._apellidos_var).pack(fill="x")

        _campo("Tipo de persona")
        self._tipo_persona_combo = ttk.Combobox(form_wrap, state="readonly")
        self._tipo_persona_combo.pack(fill="x")

        _campo("Puerta de ingreso")
        self._entrada_combo = ttk.Combobox(form_wrap, state="readonly")
        self._entrada_combo.pack(fill="x")

        _campo("Observaciones (opcional)")
        self._obs_var = tk.StringVar()
        ttk.Entry(form_wrap, textvariable=self._obs_var).pack(fill="x")

        ttk.Label(
            form_wrap,
            textvariable=self._form_msg_var,
            style="CardMuted.TLabel",
            wraplength=260,
        ).pack(anchor="w", pady=(8, 0))

        btns = ttk.Frame(form_wrap, style="Card.TFrame")
        btns.pack(fill="x", pady=(12, 0))
        btns.columnconfigure(0, weight=1)
        btns.columnconfigure(1, weight=1)

        self._enrolar_btn = ttk.Button(
            btns, text="Enrolar rostro", style="Nav.TButton", command=self._enrolar
        )
        self._enrolar_btn.grid(row=0, column=0, sticky="ew", padx=(0, 4))

        ttk.Button(
            btns,
            text="Registrar ingreso",
            style="Primary.TButton",
            command=self._registrar_persona_nueva,
        ).grid(row=0, column=1, sticky="ew", padx=(4, 0))

    def _build_columna_huella(self, parent: tk.Frame) -> None:
        huella_wrap = tk.Frame(parent, bg=theme.BG_PANEL, padx=12, pady=12)
        huella_wrap.grid(row=0, column=2, sticky="nsew", padx=(6, 0))

        huella_header = tk.Frame(huella_wrap, bg=theme.BG_PANEL)
        huella_header.pack(fill="x", pady=(0, 8))

        ttk.Label(huella_header, text="Huella dactilar", style="Muted.TLabel").pack(
            side="left"
        )
        ttk.Label(huella_header, text="Próximamente", style="Muted.TLabel").pack(
            side="right"
        )

        self._huella_canvas = tk.Canvas(
            huella_wrap,
            width=HUELLA_ANCHO,
            height=HUELLA_ALTO,
            bg="#000000",
            highlightthickness=1,
            highlightbackground=theme.BORDER,
        )
        self._huella_canvas.pack(fill="both", expand=True)
        self._draw_huella_placeholder()
        self._huella_canvas.bind("<Configure>", self._on_huella_resize, add="+")

    def _cargar_catalogos_formulario(self) -> None:
        try:
            self._catalogos = self._client.catalogos()
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._form_msg_var.set(f"No se pudieron cargar catálogos: {exc}")
            return

        tipos_doc = self._catalogos.get("tipos_doc", [])
        self._tipo_doc_map = {t["nombre"]: t["id"] for t in tipos_doc}
        self._tipo_doc_combo.configure(values=list(self._tipo_doc_map.keys()))
        if tipos_doc:
            self._tipo_doc_combo.current(0)

        tipos_persona = self._catalogos.get("tipos_persona", [])
        self._tipo_persona_map = {t["nombre"]: t["id"] for t in tipos_persona}
        self._tipo_persona_combo.configure(values=list(self._tipo_persona_map.keys()))
        if tipos_persona:
            self._tipo_persona_combo.current(0)

        entradas = self._catalogos.get("entradas", [])
        self._entrada_map = {e["nombre"]: e["id"] for e in entradas}
        self._entrada_combo.configure(values=list(self._entrada_map.keys()))
        if entradas:
            self._entrada_combo.current(0)

    def _registrar_persona_nueva(self) -> None:
        documento = self._documento_var.get().strip()
        nombres = self._nombres_var.get().strip()
        apellidos = self._apellidos_var.get().strip()
        if not documento:
            self._form_msg_var.set("Ingrese el número de documento.")
            self._documento_entry.focus_set()
            return
        if not nombres or not apellidos:
            self._form_msg_var.set("Complete nombres y apellidos.")
            return

        tipo_doc = self._tipo_doc_map.get(self._tipo_doc_combo.get(), "CC")
        tipo_persona = self._tipo_persona_map.get(self._tipo_persona_combo.get(), 0)
        id_entrada = self._entrada_map.get(self._entrada_combo.get(), 0)
        if not id_entrada:
            self._form_msg_var.set("Seleccione una puerta de ingreso.")
            return

        payload = {
            "tipo_doc": tipo_doc,
            "documento": documento,
            "nombres": nombres,
            "apellidos": apellidos,
            "tipo_persona": tipo_persona,
            "id_entrada": id_entrada,
            "observaciones": self._obs_var.get().strip(),
            "metodo_aut": 1,
        }
        try:
            self._client.ingreso_registrar(payload)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._form_msg_var.set(str(exc))
            self._set_estado(str(exc), theme.ERROR)
            return

        self._form_msg_var.set(f"Ingreso registrado: {nombres} {apellidos}.")
        self._set_estado(
            f"Ingreso registrado: {nombres} {apellidos}.", theme.SUCCESS
        )
        if self._on_registrado is not None:
            self._on_registrado()

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

    def _on_huella_resize(self, _event: tk.Event | None = None) -> None:
        self._draw_huella_placeholder()

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

    def _draw_huella_placeholder(self) -> None:
        """Dibuja la caja de huella (solo front — sin lector ni matching)."""
        c = self._huella_canvas
        c.delete("all")
        w, h = self._tamano_canvas(c, HUELLA_ANCHO, HUELLA_ALTO)
        cx, cy = w // 2, h // 2
        c.create_oval(
            cx - 55,
            cy - 85,
            cx + 55,
            cy + 85,
            outline=theme.CYAN,
            dash=(5, 4),
            width=2,
        )
        c.create_oval(
            cx - 28,
            cy - 50,
            cx + 28,
            cy + 40,
            outline=theme.V_OLIVA,
            dash=(3, 3),
            width=1,
        )
        c.create_text(
            cx,
            cy + 120,
            text="Coloque el dedo en el lector\n(feature en desarrollo)",
            fill=theme.TEXT_MUTED,
            font=theme.FONT_LABEL_SMALL,
            justify="center",
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
                self._cam_image_id = self._cam_canvas.create_image(0, 0, anchor="nw", image=photo)
            else:
                self._cam_canvas.itemconfig(self._cam_image_id, image=photo)
            self._tick_contador += 1
            self._evaluar_auto_identificacion(frame)
        else:
            self._frames_sin_senal += 1
            if self._frames_sin_senal >= 45:
                self._set_estado(
                    "La cámara dejó de entregar imagen — pruebe otra con 🎥 Cambiar cámara.",
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
        documento = self._documento_var.get().strip()
        if not documento:
            self._set_estado("Ingrese un número de documento antes de enrolar.", theme.ERROR)
            self._documento_entry.focus_set()
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

    # ---- Identificar + abrir confirmación (2026-07-09) ------------------

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

        self._set_estado("🔍 Buscando en base de datos...", theme.CYAN)
        self.update()  # Refrescar UI

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

        # Modal de confirmación: foto + datos. El modo (ingreso/salida)
        # se decide con el estado real en BD, no con el botón del sidebar.
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
        accion = "ingreso" if modo_efectivo == "ingreso" else "salida"
        self._set_estado(
            f"✅ Identificado — se registrará {accion}...",
            theme.SUCCESS,
        )

        self._confirmacion_abierta = True
        self._identificando = False
        modal = IdentificationConfirmationModal(
            self,
            self._client,
            persona_datos,
            modo=modo_efectivo,
            on_confirmar=self._on_confirmacion_modal,
        )
        self._confirmacion_modal = modal
        modal.bind("<Destroy>", self._on_confirmacion_cerrada, add="+")

    def _on_confirmacion_cerrada(self, event: tk.Event) -> None:
        if self._confirmacion_modal is None or event.widget is not self._confirmacion_modal:
            return
        self._confirmacion_modal = None
        if not self.winfo_exists():
            return
        self._confirmacion_abierta = False
        self._rostro_consecutivos = 0
        self._cooldown_hasta_ms = time.monotonic() * 1000 + 1500
        indice = self._camara_indice_seleccionado
        if indice is None:
            indice = 0
        if self._capturando:
            self._set_estado(
                f"Cámara activa (índice {indice}). Acérquese al lente.",
                theme.CYAN,
            )

    def _resolver_modo_acceso(self, documento: str) -> Modo:
        """Ingreso si no hay abierto; salida si ya está dentro."""
        if not documento:
            raise SmartcsetApiError("Documento vacío tras la identificación.")
        consulta = self._client.ingreso_consultar(documento, "CC")
        if consulta.get("puede_ingresar"):
            return "ingreso"
        return "salida"

    def _on_confirmacion_modal(self, persona_datos: dict) -> None:
        """Registra ingreso o salida según el estado actual en BD."""
        documento = str(
            persona_datos.get("documento") or persona_datos.get("num_docum") or ""
        )
        nombre = (
            f"{persona_datos.get('nombres', '')} {persona_datos.get('apellidos', '')}"
        ).strip()

        # Reconsultar al confirmar (evita carrera si el estado cambió).
        modo = self._resolver_modo_acceso(documento)
        if modo == "ingreso":
            self._registrar_ingreso_identificado(documento, nombre, persona_datos)
        else:
            self._registrar_salida_identificada(documento, nombre)

        if self._on_registrado is not None:
            self._on_registrado()

    def _registrar_ingreso_identificado(
        self, documento: str, nombre: str, persona_datos: dict | None = None
    ) -> None:
        consulta = self._client.ingreso_consultar(documento, "CC")
        if not consulta.get("puede_ingresar"):
            # Ya dentro → salida (no mostrar "ya tiene ingreso abierto").
            self._registrar_salida_identificada(documento, nombre)
            return

        # Puerta: primera del catálogo hasta config local por PC.
        entradas = self._client.catalogos().get("entradas", [])
        if not entradas:
            self._set_estado("No hay puertas configuradas en el catálogo.", theme.ERROR)
            raise SmartcsetApiError("No hay puertas configuradas en el catálogo.")

        persona = persona_datos or consulta.get("persona") or {}

        self._client.ingreso_registrar(
            {
                "tipo_doc": "CC",
                "documento": documento,
                "nombres": persona.get("nombres", ""),
                "apellidos": persona.get("apellidos", ""),
                "tipo_persona": persona.get("tipo_persona", 0),
                "id_entrada": entradas[0]["id"],
                "observaciones": "Identificado por reconocimiento facial.",
                "metodo_aut": 4,
                "embedding": self._ultimo_embedding,
            }
        )
        self._set_estado(f"Ingreso registrado: {nombre}.", theme.SUCCESS)

    def _registrar_salida_identificada(self, documento: str, nombre: str) -> None:
        consulta = self._client.salida_consultar(documento, "CC")
        if not consulta.get("puede_salir"):
            self._set_estado(
                f"{nombre}: no tiene un ingreso abierto para registrar salida.",
                theme.ERROR,
            )
            raise SmartcsetApiError(
                f"{nombre}: no tiene un ingreso abierto para registrar salida."
            )

        self._client.salida_registrar(
            {
                "tipo_doc": "CC",
                "documento": documento,
                "observaciones": "Identificado por reconocimiento facial.",
                "metodo_aut": 4,
            }
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
