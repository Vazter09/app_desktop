"""
Modal "Reconocimiento Facial" — compartido entre Registro de ingreso y
Registro de salida (mismo componente, la página que lo abre decide el
`modo`; la decisión real de si corresponde ingreso o salida la hacen
los endpoints reales `ingreso/consultar.php` / `salida/consultar.php`,
igual que con captura manual — no se reinventa esa lógica aquí).

ESTADO: flujo completo real.
1. Cámara en vivo (`ui/camera.py`, OpenCV — única dependencia de
   terceros de la app principal).
2. Motor de embeddings (`motor/embeddings.py`, SFace + YuNet,
   vendorizados, mismo OpenCV) — calcula el vector de 128 dims del
   rostro capturado.
3. "Enrolar": documento + último frame → vector → `biometria/enrolar.php`.
4. "Identificar": último frame → vector → `biometria/identificar.php` →
   si hay match, ABRE MODAL DE CONFIRMACIÓN (2026-07-09) que muestra foto
   + datos personales para que el usuario confirme antes de registrar
   ingreso/salida con `id_metodo_aut=4` ("Biométrico facial").

CUMPLIMIENTO MSPI + FASE 0-1:
- E1: Validación visual de acceso (usuario confirma antes de registrar)
- E4: Hardening de sesión (confirmación explícita)
- E10: Auditoría (cada acción queda logueda)
"""
from __future__ import annotations

import base64
import io
import tkinter as tk
from tkinter import ttk
from typing import Callable, Literal

import cv2
import numpy as np
from PIL import Image

from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError
from ui import theme
from ui.camera import CameraSource, detectar_camara_disponible, frame_a_photoimage
from ui.identification_confirmation_modal import IdentificationConfirmationModal

Modo = Literal["ingreso", "salida"]

CAM_ANCHO = 400
CAM_ALTO = 300
CAM_INTERVALO_MS = 33  # ~30 fps

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

        titulo = "Identificar rostro — Ingreso" if modo == "ingreso" else "Identificar rostro — Salida"
        self.title(titulo)
        self.configure(bg=theme.BG_CARD)
        self.geometry("460x660")
        self.resizable(False, False)
        self.transient(master)
        self.grab_set()
        self.protocol("WM_DELETE_WINDOW", self._cerrar)

        self._build()

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
            "Identifica a la persona para registrar su ingreso"
            if self._modo == "ingreso"
            else "Identifica a la persona para registrar su salida"
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
        cam_wrap.pack(fill="both", expand=True, padx=20, pady=10)

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
        self._estado_var = tk.StringVar(value="En espera — inicie la captura.")
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
        actions.columnconfigure(2, weight=1)

        self._toggle_btn = ttk.Button(
            actions, text="Iniciar captura", style="Primary.TButton", command=self._toggle_captura
        )
        self._toggle_btn.grid(row=0, column=0, sticky="ew", padx=(0, 4))

        self._identificar_btn = ttk.Button(
            actions,
            text="Identificar",
            style="Nav.TButton",
            command=self._identificar,
            state="disabled",
        )
        self._identificar_btn.grid(row=0, column=1, sticky="ew", padx=4)

        ttk.Button(
            actions, text="Cerrar", style="Nav.TButton", command=self._cerrar
        ).grid(row=0, column=2, sticky="ew", padx=(4, 0))

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
        indice = detectar_camara_disponible()
        if indice is None:
            self._set_estado("No se detectó ninguna cámara en este equipo.", theme.ERROR)
            self._draw_placeholder("Cámara no disponible")
            return

        self._camara = CameraSource(indice)
        if not self._camara.abrir():
            self._set_estado(f"No se pudo abrir la cámara (índice {indice}).", theme.ERROR)
            self._camara = None
            return

        self._capturando = True
        self._toggle_btn.configure(text="Detener")
        self._identificar_btn.state(["!disabled"])
        self._set_estado(f"Cámara activa (índice {indice}).", theme.CYAN)
        self._tick_camara()

    def _tick_camara(self) -> None:
        if not self._capturando or self._camara is None:
            return

        frame = self._camara.leer_frame()
        if frame is not None:
            self._ultimo_frame = frame
            photo = frame_a_photoimage(frame, CAM_ANCHO, CAM_ALTO)
            self._cam_photo_ref = photo  # evita garbage collection
            if self._cam_image_id is None:
                self._cam_image_id = self._cam_canvas.create_image(0, 0, anchor="nw", image=photo)
            else:
                self._cam_canvas.itemconfig(self._cam_image_id, image=photo)

        self._after_id = self.after(CAM_INTERVALO_MS, self._tick_camara)

    def _detener_captura(self) -> None:
        self._capturando = False
        if self._after_id is not None:
            self.after_cancel(self._after_id)
            self._after_id = None
        if self._camara is not None:
            self._camara.liberar()
            self._camara = None
        self._ultimo_frame = None
        self._toggle_btn.configure(text="Iniciar captura")
        self._identificar_btn.state(["disabled"])
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

    def _identificar(self) -> None:
        extraido = self._extraer_embedding()
        if extraido is None:
            return
        embedding, _calidad = extraido

        self._set_estado("🔍 Buscando en base de datos...", theme.CYAN)
        self.update()  # Refrescar UI

        self._identificar_btn.state(["disabled"])
        try:
            resultado = self._client.biometria_identificar(embedding)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._set_estado(f"Error al identificar: {exc}", theme.ERROR)
            self._identificar_btn.state(["!disabled"])
            return

        if not resultado.get("match"):
            self._set_estado("❌ Rostro no reconocido — no está enrolado.", theme.ERROR)
            self._identificar_btn.state(["!disabled"])
            return

        # ✅ CAMBIO (2026-07-09): En lugar de registrar directamente, abre modal
        # de confirmación que muestra foto + datos personales. Usuario confirma.
        persona_datos = resultado.get("persona", {})

        # PRIORIDAD: Foto guardada del servidor (de enrolamiento original)
        # Fallback: frame local actual si no viene foto del servidor
        if resultado.get("foto_base64"):
            # ✅ Foto original de enrolamiento (guardada en servidor)
            persona_datos["foto_base64"] = resultado.get("foto_base64")
        elif self._ultimo_frame is not None:
            # Fallback: si no vino foto del servidor, usa frame actual (shouldn't happen)
            persona_datos["foto_base64"] = self._frame_a_base64(self._ultimo_frame)

        self._set_estado("✅ Identificación confirmada — abriendo detalles...", theme.SUCCESS)

        # Abre modal de confirmación
        IdentificationConfirmationModal(
            self,
            self._client,
            persona_datos,
            modo=self._modo,
            on_confirmar=self._on_confirmacion_modal,
        )

        self._identificar_btn.state(["!disabled"])

    def _on_confirmacion_modal(self, persona_datos: dict) -> None:
        """Callback del modal de confirmación cuando usuario presiona
        'Registrar Ingreso' o 'Registrar Salida'."""
        documento = persona_datos.get("documento") or persona_datos.get("num_docum", "")
        nombre = f"{persona_datos.get('nombres', '')} {persona_datos.get('apellidos', '')}".strip()

        try:
            if self._modo == "ingreso":
                self._registrar_ingreso_identificado(documento, nombre, persona_datos)
            else:
                self._registrar_salida_identificada(documento, nombre)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._set_estado(f"{nombre}: {exc}", theme.ERROR)
            return

        if self._on_registrado is not None:
            self._on_registrado()

    def _registrar_ingreso_identificado(self, documento: str, nombre: str, persona_datos: dict | None = None) -> None:
        consulta = self._client.ingreso_consultar(documento, "CC")
        if not consulta.get("puede_ingresar"):
            self._set_estado(f"{nombre}: ya tiene un ingreso abierto.", theme.ERROR)
            return

        # La puerta física no la elige el operador aquí (a diferencia del
        # diálogo manual) — se usa la primera entrada real del catálogo.
        # Pendiente real: cuando cada PC quede fijo en una puerta, esto
        # debe leerse de configuración local, no de "la primera de la
        # lista" (ver REGLAS_APP_ESCRITORIO_SGI.md, pendiente de diseño).
        entradas = self._client.catalogos().get("entradas", [])
        if not entradas:
            self._set_estado("No hay puertas configuradas en el catálogo.", theme.ERROR)
            return

        persona = consulta["persona"]
        # Usar datos del modal si están disponibles (con confirmación visual)
        if persona_datos:
            persona = persona_datos

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
            }
        )
        self._set_estado(f"Ingreso registrado: {nombre}.", theme.SUCCESS)

    def _registrar_salida_identificada(self, documento: str, nombre: str) -> None:
        consulta = self._client.salida_consultar(documento, "CC")
        if not consulta.get("puede_salir"):
            self._set_estado(f"{nombre}: no tiene un ingreso abierto para registrar salida.", theme.ERROR)
            return

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
