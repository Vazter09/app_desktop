"""
Panel / modal "Reconocimiento biométrico" — flujo único de portería.

`FacialRecognitionPanel` es el layout fijo (cámara izquierda + huella
derecha). `FacialRecognitionModal` es un Toplevel opcional que reutiliza
el mismo panel (p. ej. desde la página de salida).

Tras identificar un rostro, consulta `ingreso/consultar.php`:
  - si puede ingresar → registra ingreso
  - si hay ingreso abierto y aún no pasan 5 min → aviso (sin modal)
  - si hay ingreso abierto y ya pasaron 5 min → registra salida

Foto en confirmación: siempre la de enrolamiento (`identificar.php` →
`ruta_foto_facial`). Nunca el frame en vivo.

Documento escrito a mano (Enter/FocusOut): carga datos en el formulario.
Pistola QR/barras (teclas rápidas): persona registrada → modal; visitante → form.

ESTADO: flujo completo real (facial). Huella: UI + identificar.
1. Cámara en vivo (`ui/camera.py`, OpenCV).
2. Motor de embeddings (`motor/embeddings.py`, SFace + YuNet).
3. "Capturar Rostro": documento + frame → `biometria/enrolar.php`.
4. "Identificar": frame → `biometria/identificar.php` → panel
   «Persona encontrada» (~2.5 s) → ingreso / salida
   (`metodo_aut=4`) y vuelve al formulario vacío.
"""
from __future__ import annotations

import base64
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
from ui.scan_capture import CapturaEscaneo, parse_captura_escaneo
from ui.window_utils import centrar_ventana_al_mostrar

Modo = Literal["ingreso", "salida", "actualizar_captura", "espera_reingreso"]

# Tres secciones: cámara | formulario | huella.
# Pistola (wedge): teclas rápidas + Enter → buffer de escaneo.
SCAN_INTER_CHAR_MS = 50
SCAN_RESET_MS = 140
SCAN_MIN_LEN = 4
SCAN_SWALLOW_AFTER = 3
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
        # Cooldown corto global (fallos / anti-spam de frames).
        self._cooldown_hasta_ms = 0.0
        # Espera post-salida por documento: no bloquea a otras personas.
        self._cooldown_espera_docs: dict[str, float] = {}
        self._confirmacion_modal: IdentificationConfirmationPanel | None = None
        self._motor_listo = False
        self._ultimo_embedding: list[float] | None = None
        self._ultima_foto_enrol_b64: str | None = None
        self._ultima_calidad_facial: float | None = None
        self._ultimo_huella_b64: str | None = None
        self._huella_scan: HuellaScanCanvas | None = None
        self._huella_header_icon: ImageTk.PhotoImage | None = None
        self._form_panel: IngresoFormPanel | None = None
        self._centro_wrap: tk.Frame | None = None
        self._syncing_centro = False
        # 2=QR, 3=barras, 4=facial, 5=huella (tab_metodos_aut)
        self._ultimo_metodo_biometrico: int = 4
        self._scan_buf: list[str] = []
        self._scan_last_ms: float = 0.0
        self._scan_fast: bool = True
        self._scan_swallow: bool = False
        self._scan_bindings_activos = True

        self.columnconfigure(0, weight=1)
        # Solo la fila biométrica crece; estado y acciones quedan fijas abajo.
        self.rowconfigure(0, weight=1)
        self.rowconfigure(1, weight=0)
        self.rowconfigure(2, weight=0)
        self._build()
        self.bind("<Destroy>", self._on_destroy, add="+")
        # Intercepta pistola/QR en toda la ventana del panel (no solo el Entry).
        self.bind_all("<KeyPress>", self._on_scan_keypress, add="+")
        self.after(150, self._iniciar_captura)

    def _on_destroy(self, event: tk.Event) -> None:
        if event.widget is not self:
            return
        # Solo liberar hardware: los widgets ya se están destruyendo.
        self._abriendo_camara = False
        self._capturando = False
        self._scan_bindings_activos = False
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
            on_enriquecer_payload=self._enriquecer_payload_ingreso_manual,
        )
        self._form_panel.grid(row=0, column=0, sticky="nsew")
        # Tras el primer layout, fija el tamaño de la columna central para que
        # «Persona encontrada» ocupe exactamente la misma caja.
        self.after_idle(self._fijar_tamano_columna_central)

    def _fijar_tamano_columna_central(self) -> tuple[int, int]:
        """Congela ancho/alto de `_centro_wrap` al del formulario Nuevo ingreso.

        Debe llamarse **antes** de `grid_remove()` del formulario; si el tamaño
        aún no está listo, usa un fallback para no dejar la columna en 0×0
        (panel de confirmación invisible).
        """
        fallback = (340, 480)
        if self._centro_wrap is None:
            return fallback
        w, h = fallback
        try:
            if self._form_panel is not None and self._form_panel.winfo_exists():
                self._form_panel.update_idletasks()
                fw = int(self._form_panel.winfo_width())
                fh = int(self._form_panel.winfo_height())
                if fw >= 50 and fh >= 50:
                    w, h = fw, fh
            self._centro_wrap.grid_propagate(False)
            self._centro_wrap.configure(width=w, height=h)
        except tk.TclError:
            pass
        return (w, h)

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
            # Persistir en el formulario: el estado inferior lo sobrescribe
            # el mensaje de cámara y el fallo quedaba invisible.
            msg = f"No se pudieron cargar catálogos: {exc}"
            self._set_estado(msg, theme.ERROR)
            self._form_panel.mostrar_error_catalogos(msg)
            return
        self._form_panel.cargar_catalogos(catalogos)

    def _documento_formulario(self) -> str:
        if self._form_panel is not None:
            return self._form_panel.documento()
        return ""

    def _tipo_doc_efectivo(
        self, persona_datos: dict[str, Any] | None = None
    ) -> str:
        """Tipo de documento para consultas/registros biométricos.

        Prioridad: datos de persona identificada → formulario → CC.
        (La persona gana porque el combo del form siempre tiene un valor
        por defecto — p. ej. CC — que no debe enmascarar TI/CE/PA.)
        """
        if persona_datos:
            tipo = str(
                persona_datos.get("tipo_doc")
                or persona_datos.get("id_tipo_docum")
                or ""
            ).strip()
            if tipo:
                return tipo
        if self._form_panel is not None:
            try:
                tipo_form = self._form_panel.tipo_doc_actual()
                if tipo_form:
                    return tipo_form
            except tk.TclError:
                pass
        return "CC"

    def _sincronizar_tipo_doc_formulario(
        self, persona_datos: dict[str, Any]
    ) -> None:
        """Ajusta el combo del formulario al tipo que trajo la identificación."""
        if self._form_panel is None:
            return
        tipo = str(
            persona_datos.get("tipo_doc")
            or persona_datos.get("id_tipo_docum")
            or ""
        ).strip()
        if tipo:
            self._form_panel.set_tipo_doc(tipo)

    def _reset_scan_buf(self) -> None:
        self._scan_buf = []
        self._scan_fast = True
        self._scan_swallow = False
        self._scan_last_ms = 0.0

    def _on_scan_keypress(self, event: tk.Event) -> str | None:
        """Buffer de pistola/QR: teclas rápidas + Enter → identificación."""
        if not self._scan_bindings_activos:
            return None
        try:
            if not self.winfo_exists():
                return None
        except tk.TclError:
            return None
        if self._confirmacion_abierta:
            return None

        keysym = getattr(event, "keysym", "") or ""
        if keysym in ("Return", "KP_Enter"):
            return self._flush_scan_buffer()

        char = getattr(event, "char", "") or ""
        if not char or not char.isprintable():
            return None

        now = time.monotonic() * 1000
        if self._scan_last_ms and (now - self._scan_last_ms) > SCAN_RESET_MS:
            self._reset_scan_buf()
        elif self._scan_last_ms and (now - self._scan_last_ms) > SCAN_INTER_CHAR_MS:
            # Mecanografía humana: no es pistola.
            self._scan_fast = False
            self._scan_swallow = False

        self._scan_buf.append(char)
        self._scan_last_ms = now

        if (
            self._scan_fast
            and len(self._scan_buf) >= SCAN_SWALLOW_AFTER
        ):
            self._scan_swallow = True

        if self._scan_swallow:
            return "break"
        return None

    def _flush_scan_buffer(self) -> str | None:
        raw = "".join(self._scan_buf)
        was_fast = self._scan_fast and len(raw) >= SCAN_MIN_LEN
        swallow = self._scan_swallow
        self._reset_scan_buf()
        if not was_fast or not raw.strip():
            return None

        cap = parse_captura_escaneo(raw)
        if not cap.documento:
            self._set_estado(
                "Escaneo sin documento válido — reintente.",
                theme.ERROR,
            )
            return "break"

        registrada = self._procesar_persona_por_documento(cap)
        if not registrada and self._form_panel is not None:
            # Visitante: pegar en el form (flujo manual).
            self._form_panel.aplicar_visitante_escaneado(
                cap.documento,
                tipo_doc=cap.tipo_doc,
                nombres=cap.nombres,
                apellidos=cap.apellidos,
            )
        return "break" if (swallow or was_fast) else None

    def _procesar_persona_por_documento(self, cap: CapturaEscaneo) -> bool:
        """Persona registrada → modal (como facial). Visitante → False.

        Returns:
            True si se manejó (modal o aviso) — no rellenar el form.
            False si no está en el sistema — el form completa visitante.
        """
        if self._confirmacion_abierta or self._identificando:
            return True
        documento = (cap.documento or "").strip()
        if not documento:
            return False
        tipo_doc = (cap.tipo_doc or "CC").strip() or "CC"

        try:
            consulta = self._client.ingreso_consultar(documento, tipo_doc)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._set_estado(f"Error al consultar documento: {exc}", theme.ERROR)
            return True

        persona = consulta.get("persona")
        if persona is None:
            return False

        # Registrada: no dejar datos estáticos en el formulario.
        if self._form_panel is not None and self._form_panel.winfo_exists():
            self._form_panel.limpiar()

        persona_datos = dict(persona)
        persona_datos["documento"] = documento
        persona_datos.setdefault(
            "tipo_doc",
            str(persona.get("tipo_doc") or persona.get("id_tipo_docum") or tipo_doc),
        )
        if cap.nombres and not persona_datos.get("nombres"):
            persona_datos["nombres"] = cap.nombres
        if cap.apellidos and not persona_datos.get("apellidos"):
            persona_datos["apellidos"] = cap.apellidos
        self._sincronizar_tipo_doc_formulario(persona_datos)
        self._ultimo_metodo_biometrico = int(cap.metodo_aut)

        try:
            modo_efectivo = self._resolver_modo_acceso(
                documento, persona_datos=persona_datos
            )
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._set_estado(f"Error al consultar acceso: {exc}", theme.ERROR)
            return True

        persona_datos["_modo_acceso"] = modo_efectivo

        if modo_efectivo == "espera_reingreso":
            self._avisar_espera_reingreso(
                documento, persona_datos=persona_datos
            )
            return True

        if modo_efectivo == "actualizar_captura":
            # Ya ingresó: solo aviso en barra de estado (sin modal).
            if int(cap.metodo_aut) in (2, 3):
                self._avisar_ventana_recaptura_barras(
                    documento, persona_datos=persona_datos
                )
            else:
                etiqueta = {
                    5: "Huella",
                }.get(int(cap.metodo_aut), "Documento")
                self._avisar_identificado_sin_modal(
                    documento,
                    f"✅ Identificado — {etiqueta.lower()} · "
                    f"{self._etiqueta_accion(modo_efectivo)}...",
                    desde_huella=int(cap.metodo_aut) == 5,
                )
            return True

        self._limpiar_espera_reingreso_doc(documento)
        accion = self._etiqueta_accion(modo_efectivo)
        etiqueta = {
            2: "QR",
            3: "código de barras",
            5: "huella",
        }.get(int(cap.metodo_aut), "documento")
        self._set_estado(
            f"✅ {etiqueta.capitalize()} — {accion}...",
            theme.SUCCESS,
        )
        self._asegurar_foto_persona(persona_datos)
        self._mostrar_confirmacion_centro(persona_datos, modo_efectivo)
        return True

    def _asegurar_foto_persona(self, persona_datos: dict[str, Any]) -> None:
        """Adjunta la foto de enrolamiento al modal (solo lectura).

        La foto/vector de referencia NO se reescribe aquí: ingreso/salida/
        identificar deben comparar siempre contra el mismo enrolamiento.
        Alta o cambio de rostro: botón «Capturar Rostro» (o primer enrol
        post-registro si aún no hay foto).
        """
        if persona_datos.get("foto_base64"):
            return
        documento = str(
            persona_datos.get("documento")
            or persona_datos.get("num_docum")
            or persona_datos.get("id_persona")
            or ""
        ).strip()
        if not documento:
            return
        tipo_doc = self._tipo_doc_efectivo(persona_datos)
        try:
            resp = self._client.ingreso_consultar(
                documento, tipo_doc, incluir_foto=True
            )
            foto = resp.get("foto_base64")
            if foto:
                persona_datos["foto_base64"] = foto
        except (SmartcsetApiError, SmartcsetConnectionError):
            pass

    def _persona_tiene_foto_enrolada(
        self, documento: str, tipo_doc: str
    ) -> bool:
        """True si ya hay patrón o foto de referencia (no re-enrolar)."""
        try:
            resp = self._client.ingreso_consultar(
                documento, tipo_doc, incluir_foto=True
            )
            return bool(
                resp.get("tiene_patron_facial") or resp.get("foto_base64")
            )
        except (SmartcsetApiError, SmartcsetConnectionError):
            return False

    def _avisar_ventana_recaptura_barras(
        self,
        documento: str,
        *,
        persona_datos: dict[str, Any] | None = None,
    ) -> None:
        """Dentro de 5 min: QR/barras no actualizan captura; aviso sin modal."""
        tipo_doc = self._tipo_doc_efectivo(persona_datos)
        try:
            consulta = self._client.ingreso_consultar(documento, tipo_doc)
            rest = int(consulta.get("segundos_restantes_salida") or 0)
        except (SmartcsetApiError, SmartcsetConnectionError):
            rest = 0
        if rest > 0:
            min_rest = max(1, (rest + 59) // 60)
            msg = (
                f"Ingreso reciente: salida disponible en ~{min_rest} min "
                "(QR/barras no actualizan captura)."
            )
        else:
            msg = (
                "Aún dentro de la ventana de 5 min tras el ingreso "
                "(QR/barras no actualizan captura)."
            )
        self._set_estado(f"⏳ {msg}", theme.CYAN)
        self._identificando = False
        self._confirmacion_abierta = False
        if self._form_panel is not None and self._form_panel.winfo_exists():
            self._form_panel.grid()

    @staticmethod
    def _obs_metodo(metodo: int, *, recaptura: bool = False) -> str:
        if metodo == 5:
            base = "huella dactilar"
        elif metodo == 3:
            base = "código de barras"
        elif metodo == 2:
            base = "código QR"
        else:
            base = "reconocimiento facial"
        if recaptura:
            return f"Re-captura por {base}."
        return f"Identificado por {base}."

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
            self._set_estado(
                "No se detectó ningún rostro en la imagen — acérquese a la cámara.",
                theme.ERROR,
            )
            return None

        return resultado

    def _extraer_embedding_y_recorte(
        self,
    ) -> tuple[list[float], float, np.ndarray] | None:
        """Embedding + recorte facial alineado (para foto de enrolamiento)."""
        if self._ultimo_frame is None:
            self._set_estado("Inicie la captura de cámara primero.", theme.ERROR)
            return None

        try:
            embedder = _get_embedder()
        except FileNotFoundError as exc:
            self._set_estado(str(exc), theme.ERROR)
            return None

        resultado = embedder.extraer_con_recorte(self._ultimo_frame)
        if resultado is None:
            self._set_estado(
                "No se detectó ningún rostro en la imagen — acérquese a la cámara.",
                theme.ERROR,
            )
            return None

        return resultado

    def _captura_facial_opcional(
        self,
    ) -> tuple[list[float], float, str] | None:
        """Si hay cámara + rostro: (embedding, calidad, foto_b64). Sin alarmar si no."""
        if self._ultimo_frame is None:
            return None
        try:
            embedder = _get_embedder()
        except FileNotFoundError:
            return None
        resultado = embedder.extraer_con_recorte(self._ultimo_frame)
        if resultado is None:
            return None
        embedding, calidad, recorte = resultado
        foto = self._frame_a_base64(recorte)
        if not foto:
            foto = self._frame_a_base64(self._ultimo_frame)
        if not foto:
            return None
        emb = list(embedding)
        self._ultimo_embedding = emb
        self._ultima_calidad_facial = float(calidad)
        self._ultima_foto_enrol_b64 = foto
        self._ultimo_metodo_biometrico = 4
        return emb, float(calidad), foto

    def _preparar_captura_para_enrol(self) -> bool:
        """True si hay embedding + foto listos (reusa o captura ahora)."""
        if self._ultimo_embedding is not None and self._ultima_foto_enrol_b64:
            return True
        return self._captura_facial_opcional() is not None

    def _enriquecer_payload_ingreso_manual(self, payload: dict[str, Any]) -> None:
        """Pre-captura rostro para enrol *después* del ingreso.

        No altera el payload: si se manda ``embedding`` en el alta del
        formulario, el backend deriva a ``tab_novedades_ingreso`` cuando la
        persona aún no existe (no crea ingreso real).
        """
        del payload  # el alta manual sigue con metodo_aut=1 sin embedding
        self._captura_facial_opcional()

    def _enrolar_tras_registro_manual(self, persona_datos: dict[str, Any]) -> None:
        """Enrol solo si aún no hay foto de referencia; audita el log del ingreso."""
        documento = str(
            persona_datos.get("documento")
            or persona_datos.get("num_docum")
            or persona_datos.get("id_persona")
            or ""
        ).strip()
        if not documento:
            return
        tipo_doc = self._tipo_doc_efectivo(persona_datos)

        # Ya enrolado: no pisar vector/foto; solo leer para el modal.
        if self._persona_tiene_foto_enrolada(documento, tipo_doc):
            self._asegurar_foto_persona(persona_datos)
            if self._preparar_captura_para_enrol() and self._ultimo_embedding:
                try:
                    self._client.ingreso_actualizar_captura(
                        {
                            "tipo_doc": tipo_doc,
                            "documento": documento,
                            "metodo_aut": 4,
                            "embedding": self._ultimo_embedding,
                            "observaciones": (
                                "Captura facial del evento (sin re-enrolar)"
                            ),
                        }
                    )
                except (SmartcsetApiError, SmartcsetConnectionError):
                    pass
            return

        if not self._preparar_captura_para_enrol():
            return
        embedding = self._ultimo_embedding
        if embedding is None or not self._ultima_foto_enrol_b64:
            return
        try:
            enrol = self._client.biometria_enrolar(
                documento,
                embedding,
                self._ultima_calidad_facial,
                self._ultima_foto_enrol_b64,
                tipo_doc=tipo_doc,
            )
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._set_estado(
                f"Ingreso OK; no se pudo enrolar el rostro: {exc}",
                theme.ERROR,
            )
            return
        foto = enrol.get("foto_base64")
        if foto:
            persona_datos["foto_base64"] = foto

        try:
            self._client.ingreso_actualizar_captura(
                {
                    "tipo_doc": tipo_doc,
                    "documento": documento,
                    "metodo_aut": 4,
                    "embedding": embedding,
                    "observaciones": "Captura facial post-registro (formulario)",
                }
            )
        except (SmartcsetApiError, SmartcsetConnectionError):
            pass

        self._set_estado(
            f"✅ Rostro enrolado para {documento}.",
            theme.SUCCESS,
        )

    # ---- Enrolar (con foto — 2026-07-09) --------------------------------

    def _frame_a_base64(self, frame: np.ndarray) -> str:
        """Convierte frame OpenCV (BGR) a base64 JPG vía cv2.imencode.

        Evita Pillow aquí: algunos frames de webcam no son contiguos /
        tipados como espera ``Image.fromarray`` y provocaban
        «Error capturando foto» sin llegar a guardar en id_persona.
        """
        try:
            if frame is None or getattr(frame, "size", 0) == 0:
                return ""
            bgr = np.ascontiguousarray(frame)
            if bgr.dtype != np.uint8:
                bgr = np.clip(bgr, 0, 255).astype(np.uint8)
            # Limitar lado mayor ~640 px para no saturar post_max_size.
            h, w = bgr.shape[:2]
            max_lado = max(h, w)
            if max_lado > 640:
                escala = 640.0 / max_lado
                bgr = cv2.resize(
                    bgr,
                    (int(w * escala), int(h * escala)),
                    interpolation=cv2.INTER_AREA,
                )
            ok, buf = cv2.imencode(
                ".jpg", bgr, [int(cv2.IMWRITE_JPEG_QUALITY), 85]
            )
            if not ok or buf is None:
                return ""
            return base64.b64encode(buf.tobytes()).decode("ascii")
        except Exception as e:
            self._set_estado(f"Error capturando foto: {e}", theme.ERROR)
            return ""

    def _enrolar(self) -> None:
        documento = self._documento_formulario()
        if not documento:
            self._set_estado(
                "Ingrese un número de documento antes de enrolar.", theme.ERROR
            )
            if self._form_panel is not None:
                self._form_panel.focus_documento()
            return

        extraido = self._extraer_embedding_y_recorte()
        if extraido is None:
            return
        embedding, calidad, recorte = extraido

        self._set_estado("📸 Capturando foto y enrolando...", theme.CYAN)
        self.update()

        # La foto enrolada es el recorte alineado (mismo que el vector).
        foto_base64 = self._frame_a_base64(recorte)
        if not foto_base64 and self._ultimo_frame is not None:
            foto_base64 = self._frame_a_base64(self._ultimo_frame)
        if not foto_base64:
            self._set_estado(
                "No se pudo capturar la imagen del rostro — reintente.",
                theme.ERROR,
            )
            return

        self._enrolar_btn.state(["disabled"])
        tipo_doc = "CC"
        if self._form_panel is not None:
            tipo_doc = self._form_panel._tipo_doc_actual()
        try:
            resultado = self._client.biometria_enrolar(
                documento,
                embedding,
                calidad,
                foto_base64,
                tipo_doc=tipo_doc,
                forzar=True,
            )
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._set_estado(f"Error al enrolar: {exc}", theme.ERROR)
            return
        finally:
            self._enrolar_btn.state(["!disabled"])

        self._ultimo_embedding = list(embedding)
        self._ultima_calidad_facial = float(calidad)
        self._ultima_foto_enrol_b64 = foto_base64
        id_persona = resultado.get("id_persona") or documento
        self._set_estado(
            f"✅ Rostro y foto enrolados para {id_persona} "
            f"(calidad {calidad}%).",
            theme.SUCCESS,
        )

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
        if self._doc_en_espera_reingreso(documento):
            self._identificando = False
            return
        self._sincronizar_tipo_doc_formulario(persona_datos)
        try:
            modo_efectivo = self._resolver_modo_acceso(
                documento, persona_datos=persona_datos
            )
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            if self._huella_scan is not None:
                self._huella_scan.set_exito(False)
            self._set_estado(f"Error al consultar acceso: {exc}", theme.ERROR)
            self._identificando = False
            return

        if resultado.get("foto_base64"):
            persona_datos["foto_base64"] = resultado.get("foto_base64")
        persona_datos["_modo_acceso"] = modo_efectivo
        self._asegurar_foto_persona(persona_datos)

        if modo_efectivo == "espera_reingreso":
            self._avisar_espera_reingreso(
                documento, desde_huella=True, persona_datos=persona_datos
            )
            return

        accion = self._etiqueta_accion(modo_efectivo)
        if modo_efectivo == "actualizar_captura":
            self._avisar_identificado_sin_modal(
                documento,
                f"✅ Identificado — {accion} (no es salida)...",
                desde_huella=True,
            )
            return

        self._limpiar_espera_reingreso_doc(documento)
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
        # Congelar tamaño con el formulario aún visible (evita panel 0×0).
        self._fijar_tamano_columna_central()
        if self._confirmacion_modal is not None:
            try:
                self._confirmacion_modal.destroy()
            except tk.TclError:
                pass
            self._confirmacion_modal = None

        if self._form_panel is not None:
            self._form_panel.limpiar()
            self._form_panel.grid_remove()

        self._confirmacion_abierta = True
        self._identificando = False
        try:
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
            self._centro_wrap.update_idletasks()
            self._centro_wrap.lift()
        except Exception as exc:
            self._confirmacion_abierta = False
            if self._form_panel is not None and self._form_panel.winfo_exists():
                self._form_panel.grid()
            self._set_estado(
                f"No se pudo mostrar confirmación: {exc}", theme.ERROR
            )

    def _mostrar_confirmacion_post_registro(
        self, persona_datos: dict[str, Any]
    ) -> None:
        """Tras Registrar ingreso (manual): mismo panel, sin volver a registrar."""
        if self._centro_wrap is None:
            return
        # Enrolar rostro + foto si la cámara capturó cara (rellena modal).
        self._enrolar_tras_registro_manual(persona_datos)
        if not persona_datos.get("foto_base64"):
            self._asegurar_foto_persona(persona_datos)
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
        try:
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
            self._centro_wrap.update_idletasks()
            self._centro_wrap.lift()
        except Exception as exc:
            self._confirmacion_abierta = False
            if self._form_panel is not None and self._form_panel.winfo_exists():
                self._form_panel.grid()
            self._set_estado(
                f"No se pudo mostrar confirmación: {exc}", theme.ERROR
            )

    def _restaurar_formulario_central(self) -> None:
        """Vuelve al formulario vacío tras el panel de confirmación."""
        self._confirmacion_modal = None
        self._confirmacion_abierta = False
        self._rostro_consecutivos = 0
        self._ultimo_embedding = None
        self._ultima_foto_enrol_b64 = None
        self._ultima_calidad_facial = None
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

    def _doc_en_espera_reingreso(self, documento: str) -> bool:
        """True si ese documento aún está en ventana de 5 min post-salida."""
        doc = (documento or "").strip()
        if not doc:
            return False
        ahora = time.monotonic() * 1000
        hasta = self._cooldown_espera_docs.get(doc, 0.0)
        if hasta <= ahora:
            self._cooldown_espera_docs.pop(doc, None)
            return False
        return True

    def _marcar_espera_reingreso_doc(self, documento: str, pausa_ms: int) -> None:
        doc = (documento or "").strip()
        if not doc:
            return
        self._cooldown_espera_docs[doc] = time.monotonic() * 1000 + max(0, pausa_ms)

    def _limpiar_espera_reingreso_doc(self, documento: str) -> None:
        doc = (documento or "").strip()
        if doc:
            self._cooldown_espera_docs.pop(doc, None)

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
        self._ultima_calidad_facial = float(_calidad) if _calidad is not None else None
        if self._ultimo_frame is not None:
            self._ultima_foto_enrol_b64 = self._frame_a_base64(self._ultimo_frame) or None
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
        # Misma persona en espera 5 min: no martillar API/estado ni bloquear a otros.
        if self._doc_en_espera_reingreso(documento):
            self._identificando = False
            self._cooldown_hasta_ms = (
                time.monotonic() * 1000 + COOLDOWN_TRAS_FALLO_MS
            )
            return

        self._sincronizar_tipo_doc_formulario(persona_datos)

        try:
            modo_efectivo = self._resolver_modo_acceso(
                documento, persona_datos=persona_datos
            )
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._set_estado(f"Error al consultar acceso: {exc}", theme.ERROR)
            self._identificando = False
            self._cooldown_hasta_ms = time.monotonic() * 1000 + COOLDOWN_TRAS_FALLO_MS
            return

        # Foto de enrolamiento del servidor; si falta el archivo, reparar.
        foto_guardada = resultado.get("foto_base64")
        if foto_guardada:
            persona_datos["foto_base64"] = foto_guardada
        persona_datos["_modo_acceso"] = modo_efectivo
        self._asegurar_foto_persona(persona_datos)

        if modo_efectivo == "espera_reingreso":
            self._avisar_espera_reingreso(
                documento, desde_huella=False, persona_datos=persona_datos
            )
            return

        accion = self._etiqueta_accion(modo_efectivo)
        if modo_efectivo == "actualizar_captura":
            self._avisar_identificado_sin_modal(
                documento,
                f"✅ Identificado — {accion} (no es salida)...",
            )
            return

        self._limpiar_espera_reingreso_doc(documento)
        self._set_estado(
            f"✅ Identificado — {accion}...",
            theme.SUCCESS,
        )
        self._mostrar_confirmacion_centro(persona_datos, modo_efectivo)

    def _avisar_identificado_sin_modal(
        self,
        documento: str,
        mensaje: str,
        *,
        desde_huella: bool = False,
    ) -> None:
        """Ya hay ingreso abierto (<5 min): solo barra de estado, sin modal."""
        self._limpiar_espera_reingreso_doc(documento)
        if desde_huella and self._huella_scan is not None:
            self._huella_scan.set_exito(True)
            self._huella_scan.set_mensaje("Identificado", theme.SUCCESS)
        self._set_estado(mensaje, theme.SUCCESS)
        self._identificando = False
        self._confirmacion_abierta = False
        self._rostro_consecutivos = 0
        self._ultimo_embedding = None
        # Anti-spam corto: no reabrir flujo con el mismo frame.
        self._cooldown_hasta_ms = time.monotonic() * 1000 + COOLDOWN_TRAS_FALLO_MS
        if self._form_panel is not None and self._form_panel.winfo_exists():
            self._form_panel.grid()

    def _avisar_espera_reingreso(
        self,
        documento: str,
        *,
        desde_huella: bool = False,
        persona_datos: dict[str, Any] | None = None,
    ) -> None:
        """Cooldown post-salida: aviso sin modal; no bloquea a otras personas.

        El cooldown largo es por documento. Solo un anti-spam corto global
        evita re-identificar el mismo rostro en el frame siguiente.
        """
        tipo_doc = self._tipo_doc_efectivo(persona_datos)
        consulta = self._client.ingreso_consultar(documento, tipo_doc)
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
        pausa_ms = max(10_000, min(rest, 60) * 1000) if rest > 0 else 15_000
        self._marcar_espera_reingreso_doc(documento, pausa_ms)
        # Anti-spam corto: la cámara sigue identificando a OTRAS personas.
        self._cooldown_hasta_ms = time.monotonic() * 1000 + COOLDOWN_TRAS_FALLO_MS
        if self._form_panel is not None and self._form_panel.winfo_exists():
            self._form_panel.grid()

    @staticmethod
    def _etiqueta_accion(modo: Modo) -> str:
        if modo == "ingreso":
            return "se registrará ingreso"
        if modo == "salida":
            return "se registrará salida"
        if modo == "espera_reingreso":
            return "espere 5 min para un nuevo ingreso"
        return "aún dentro de 5 min: se actualizará la captura"

    def _resolver_modo_acceso(
        self,
        documento: str,
        *,
        persona_datos: dict[str, Any] | None = None,
    ) -> Modo:
        """Ingreso / actualizar captura / salida / espera post-salida."""
        if not documento:
            raise SmartcsetApiError("Documento vacío tras la identificación.")
        tipo_doc = self._tipo_doc_efectivo(persona_datos)
        consulta = self._client.ingreso_consultar(documento, tipo_doc)
        if consulta.get("en_ventana_recaptura") or consulta.get(
            "puede_actualizar_captura"
        ):
            return "actualizar_captura"
        if consulta.get("puede_salir"):
            return "salida"
        if consulta.get("en_espera_reingreso"):
            return "espera_reingreso"
        if consulta.get("puede_ingresar"):
            return "ingreso"
        # Compat backend: ingreso/consultar sin flags de ventana pero con
        # ingreso abierto → decidir con salida/consultar (fuente de puede_salir).
        if consulta.get("ingreso_abierto"):
            salida = self._client.salida_consultar(documento, tipo_doc)
            if salida.get("puede_salir"):
                return "salida"
            rest = int(salida.get("segundos_restantes_salida") or 0)
            if rest > 0:
                return "actualizar_captura"
            return "salida"
        return "espera_reingreso"

    def _on_confirmacion_modal(self, persona_datos: dict) -> None:
        """Acción al confirmar el panel (auto ~2.5 s o botón).

        Usa el modo con el que se abrió el panel (`_modo_acceso`). Si el
        estado en BD cambió (p. ej. de ingreso a salida), aborta con error
        visible — nunca registra salida presentándola como ingreso.
        """
        documento = str(
            persona_datos.get("documento") or persona_datos.get("num_docum") or ""
        )
        nombre = (
            f"{persona_datos.get('nombres', '')} {persona_datos.get('apellidos', '')}"
        ).strip()

        modo_panel = persona_datos.get("_modo_acceso")
        modo = self._resolver_modo_acceso(
            documento, persona_datos=persona_datos
        )
        if (
            modo_panel in ("ingreso", "salida", "actualizar_captura")
            and modo != modo_panel
        ):
            raise SmartcsetApiError(
                f"El estado de acceso cambió ({modo_panel} → {modo}). "
                "Vuelva a identificar e intente de nuevo."
            )
        if modo_panel in ("ingreso", "salida", "actualizar_captura"):
            modo = modo_panel  # type: ignore[assignment]

        if modo == "espera_reingreso":
            self._avisar_espera_reingreso(
                documento, persona_datos=persona_datos
            )
            raise SmartcsetApiError(
                "Debe esperar 5 minutos tras la salida para un nuevo ingreso."
            )

        if modo == "ingreso":
            self._registrar_ingreso_identificado(
                documento, nombre, persona_datos
            )
        elif modo == "actualizar_captura":
            self._actualizar_captura_identificada(
                documento, nombre, persona_datos=persona_datos
            )
        else:
            self._registrar_salida_identificada(
                documento, nombre, persona_datos=persona_datos
            )

    def _payload_biometrico_basico(
        self,
        documento: str,
        nombre: str = "",
        *,
        persona_datos: dict[str, Any] | None = None,
    ) -> dict:
        metodo = self._ultimo_metodo_biometrico
        payload: dict = {
            "tipo_doc": self._tipo_doc_efectivo(persona_datos),
            "documento": documento,
            "observaciones": self._obs_metodo(metodo, recaptura=True),
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
        tipo_doc = self._tipo_doc_efectivo(persona_datos)
        consulta = self._client.ingreso_consultar(documento, tipo_doc)
        if consulta.get("puede_actualizar_captura"):
            raise SmartcsetApiError(
                "Ya tiene ingreso abierto: aún no puede registrar otro ni "
                "cerrar salida (ventana de 5 min). No se registró ingreso."
            )
        if not consulta.get("puede_ingresar"):
            if consulta.get("puede_salir"):
                raise SmartcsetApiError(
                    "Ya tiene ingreso abierto listo para salida. "
                    "No se registró un ingreso nuevo — use el flujo de salida."
                )
            if consulta.get("en_espera_reingreso"):
                rest = int(consulta.get("segundos_restantes_reingreso") or 0)
                min_rest = max(1, (rest + 59) // 60)
                msg = (
                    f"Debe esperar ~{min_rest} min tras la salida "
                    "para un nuevo ingreso."
                )
                self._set_estado(f"⏳ {msg}", theme.CYAN)
                raise SmartcsetApiError(msg)
            msg = f"{nombre}: no se puede registrar ingreso en este momento."
            self._set_estado(msg, theme.CYAN)
            raise SmartcsetApiError(msg)

        # Puerta: preferir la del formulario; si no, primera del catálogo.
        entrada_id = 0
        if self._form_panel is not None:
            entrada_id = int(
                getattr(self._form_panel, "_entrada_seleccionada", 0) or 0
            )
        if not entrada_id:
            entradas = self._client.catalogos().get("entradas", [])
            if not entradas:
                self._set_estado(
                    "No hay puertas configuradas en el catálogo.", theme.ERROR
                )
                raise SmartcsetApiError(
                    "No hay puertas configuradas en el catálogo."
                )
            entrada_id = entradas[0]["id"]

        persona = persona_datos or consulta.get("persona") or {}
        metodo = self._ultimo_metodo_biometrico
        payload: dict = {
            "tipo_doc": tipo_doc,
            "documento": documento,
            "nombres": persona.get("nombres", ""),
            "apellidos": persona.get("apellidos", ""),
            "tipo_persona": persona.get("tipo_persona", 0),
            "id_entrada": entrada_id,
            "observaciones": self._obs_metodo(metodo),
            "metodo_aut": metodo,
        }
        if metodo == 4 and self._ultimo_embedding is not None:
            payload["embedding"] = self._ultimo_embedding
        if metodo == 5 and self._ultimo_huella_b64:
            payload["huella_template_b64"] = self._ultimo_huella_b64

        resultado = self._client.ingreso_registrar(payload)
        self._limpiar_espera_reingreso_doc(documento)
        id_ingreso = (
            resultado.get("id_ingreso") if isinstance(resultado, dict) else None
        )
        if metodo == 5 and self._huella_scan is not None:
            self._huella_scan.set_exito(True)
            self._huella_scan.set_mensaje(
                f"Ingreso OK\n{nombre}", theme.SUCCESS
            )
        if id_ingreso:
            self._set_estado(
                f"Ingreso #{id_ingreso} registrado: {nombre}.",
                theme.SUCCESS,
            )
        else:
            self._set_estado(f"Ingreso registrado: {nombre}.", theme.SUCCESS)

    def _actualizar_captura_identificada(
        self,
        documento: str,
        nombre: str,
        *,
        persona_datos: dict[str, Any] | None = None,
    ) -> None:
        metodo = self._ultimo_metodo_biometrico
        if metodo == 2 or metodo == 3:
            # QR / código de barras no aportan vector/huella para re-captura.
            self._avisar_ventana_recaptura_barras(
                documento, persona_datos=persona_datos
            )
            raise SmartcsetApiError(
                "QR/barras no actualizan captura en la ventana de 5 min."
            )

        payload = self._payload_biometrico_basico(
            documento, nombre, persona_datos=persona_datos
        )
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

        rest_txt = ""
        try:
            tipo_doc = self._tipo_doc_efectivo(persona_datos)
            q = self._client.ingreso_consultar(documento, tipo_doc)
            rest = int(q.get("segundos_restantes_salida") or 0)
            if rest > 0:
                min_rest = max(1, (rest + 59) // 60)
                rest_txt = f" — salida disponible en ~{min_rest} min"
        except (SmartcsetApiError, SmartcsetConnectionError):
            rest_txt = " — aún dentro de la ventana de 5 min (no es salida)"

        self._set_estado(
            f"Captura actualizada: {nombre}{rest_txt}.",
            theme.CYAN,
        )

    def _registrar_salida_identificada(
        self,
        documento: str,
        nombre: str,
        *,
        persona_datos: dict[str, Any] | None = None,
    ) -> None:
        tipo_doc = self._tipo_doc_efectivo(persona_datos)
        consulta = self._client.salida_consultar(documento, tipo_doc)
        if not consulta.get("puede_salir"):
            rest = int(consulta.get("segundos_restantes_salida") or 0)
            if rest > 0 or consulta.get("ingreso_abierto"):
                # Aún dentro de la ventana mínima → actualizar captura, no error.
                self._actualizar_captura_identificada(
                    documento, nombre, persona_datos=persona_datos
                )
                return
            self._set_estado(
                f"{nombre}: no tiene un ingreso abierto para registrar salida.",
                theme.ERROR,
            )
            raise SmartcsetApiError(
                f"{nombre}: no tiene un ingreso abierto para registrar salida."
            )

        metodo = self._ultimo_metodo_biometrico
        self._client.salida_registrar(
            {
                "tipo_doc": tipo_doc,
                "documento": documento,
                "observaciones": self._obs_metodo(metodo),
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
