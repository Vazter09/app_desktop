"""
Modal "Reconocimiento Facial" — flujo único de portería.

Tras identificar un rostro, consulta `ingreso/consultar.php`:
  - si puede ingresar → registra ingreso
  - si ya tiene ingreso abierto → registra salida (sin mensaje de error)

No hace falta un botón aparte de "salida" en la UI: el segundo pase
por la cámara cierra el ciclo.

ESTADO: flujo completo real.
1. Cámara en vivo (`ui/camera.py`, OpenCV).
2. Motor de embeddings (`motor/embeddings.py`, SFace + YuNet).
3. "Enrolar": documento + frame → `biometria/enrolar.php`.
4. "Identificar": frame → `biometria/identificar.php` → modal de
   confirmación → ingreso o salida según estado en BD (`metodo_aut=4`).

CUMPLIMIENTO MSPI + FASE 0-1:
- E1: Validación visual de acceso (usuario confirma antes de registrar)
- E4: Hardening de sesión (confirmación explícita)
- E10: Auditoría (cada acción queda logueada)
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

MODAL_ANCHO = 540
MODAL_ALTO = 760
CAM_ANCHO = 480
CAM_ALTO = 360
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


class FacialRecognitionModal(tk.Toplevel):
    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        modo: Modo,
        on_registrado: Callable[[], None] | None = None,
    ) -> None:
        """
        `modo`: "ingreso" o "salida" — decide qué endpoint de
        consultar/registrar se usa al identificar (misma página que ya
        abre este modal, un botón por página, igual que en la web).

        `on_registrado`: callback para refrescar el listado de la
        página (ingresos/salidas de hoy) tras un registro exitoso.
        """
        super().__init__(master)
        self._client = client
        self._modo = modo
        self._on_registrado = on_registrado
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

        titulo = "Identificar rostro — Portería (ingreso / salida)"
        self.title(titulo)
        self.configure(bg=theme.BG_CARD)
        self.geometry(f"{MODAL_ANCHO}x{MODAL_ALTO}")
        self.resizable(False, False)
        self.transient(master)
        self.grab_set()
        self.protocol("WM_DELETE_WINDOW", self._cerrar)

        self._build()
        centrar_ventana_al_mostrar(self, MODAL_ANCHO, MODAL_ALTO)
        self.after(150, self._iniciar_captura)

    # ---- UI ---------------------------------------------------------

    def _build(self) -> None:
        header = ttk.Frame(self, style="Card.TFrame", padding=(20, 16, 20, 8))
        header.pack(fill="x")
        ttk.Label(
            header,
            text="📷  Reconocimiento facial",
            style="Card.TLabel",
            font=theme.FONT_TITLE,
        ).pack(anchor="w")
        subtitulo = (
            "Acérquese a la cámara — la identificación es automática al detectar el rostro"
        )
        ttk.Label(header, text=subtitulo, style="CardMuted.TLabel").pack(
            anchor="w", pady=(2, 0)
        )

        # ---- Documento a enrolar ----
        enrolar_row = ttk.Frame(self, style="App.TFrame", padding=(20, 12, 20, 0))
        enrolar_row.pack(fill="x")
        ttk.Label(enrolar_row, text="Número de documento (para enrolar)", style="App.TLabel").pack(
            anchor="w"
        )
        doc_row = ttk.Frame(enrolar_row, style="App.TFrame")
        doc_row.pack(fill="x", pady=(4, 0))
        doc_row.columnconfigure(0, weight=1)

        self._documento_var = tk.StringVar()
        self._documento_entry = ttk.Entry(doc_row, textvariable=self._documento_var)
        self._documento_entry.grid(row=0, column=0, sticky="ew", padx=(0, 8))

        self._enrolar_btn = ttk.Button(
            doc_row, text="Enrolar", style="Nav.TButton", command=self._enrolar
        )
        self._enrolar_btn.grid(row=0, column=1)

        # ---- Marco de cámara ----
        cam_wrap = tk.Frame(self, bg=theme.BG_PANEL, padx=16, pady=16)
        cam_wrap.pack(fill="x", padx=20, pady=10)

        # Fila superior: nombre de la cámara activa + botón para elegir
        # entre periféricos conectados (no solo la que trae el equipo
        # por defecto).
        cam_header = tk.Frame(cam_wrap, bg=theme.BG_PANEL)
        cam_header.pack(fill="x", pady=(0, 8))

        self._camara_activa_var = tk.StringVar(value="Cámara: conectando...")
        ttk.Label(
            cam_header, textvariable=self._camara_activa_var, style="Muted.TLabel"
        ).pack(side="left")

        ttk.Button(
            cam_header,
            text="🎥 Cambiar cámara",
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
        self._cam_canvas.pack()
        self._cam_image_id: int | None = None
        self._draw_placeholder()

        # ---- Estado ----
        self._estado_var = tk.StringVar(value="Iniciando cámara...")
        estado_row = ttk.Frame(self, style="App.TFrame", padding=(20, 0))
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
        actions = ttk.Frame(self, style="App.TFrame", padding=20)
        actions.pack(fill="x")
        actions.columnconfigure(0, weight=1)
        actions.columnconfigure(1, weight=1)

        self._toggle_btn = ttk.Button(
            actions, text="Iniciar captura", style="Primary.TButton", command=self._toggle_captura
        )
        self._toggle_btn.grid(row=0, column=0, sticky="ew", padx=(0, 4))

        ttk.Button(
            actions, text="Cerrar", style="Nav.TButton", command=self._cerrar
        ).grid(row=0, column=1, sticky="ew", padx=(4, 0))

    def _draw_placeholder(self, mensaje: str = "Sin señal de cámara") -> None:
        c = self._cam_canvas
        c.delete("all")
        self._cam_image_id = None
        cx, cy = CAM_ANCHO // 2, CAM_ALTO // 2
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
            photo = frame_a_photoimage(frame, CAM_ANCHO, CAM_ALTO)
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
        self.grab_release()
        self.destroy()
