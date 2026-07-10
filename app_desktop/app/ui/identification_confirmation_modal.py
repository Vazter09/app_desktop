"""
Modal "Confirmación de Identificación" — Se abre automáticamente cuando se
identifica a una persona por biometría facial. Muestra:

LAYOUT:
┌─────────────────────────────────────────────────────────┐
│       IDENTIFICACIÓN CONFIRMADA — Ingreso/Salida        │
├────────────────┬──────────────────┬────────────────────┤
│   FOTO         │  INFORMACIÓN     │  HUELLA DACTILAR   │
│   (izquierda)  │  (centro)        │  (derecha - TODO)  │
│                │                  │                    │
│   [IMG         │  ID: 1234567890  │  [PLACEHOLDER      │
│    150x180]    │  NOMBRE: Juan P. │   Feature en       │
│                │  APELLIDO: García│   desarrollo]      │
│                │  DOCUMENTO: CC   │                    │
│                │  TIPO: Aprendiz  │                    │
│                │  ENTRADA: P-1    │                    │
│                │  FICHA: 1234     │                    │
│                │  PROGRAMA: TI    │                    │
│                │                  │                    │
├────────────────┴──────────────────┴────────────────────┤
│  [REGISTRAR INGRESO]  [CANCELAR]  [VER DETALLES]      │
└─────────────────────────────────────────────────────────┘

CUMPLIMIENTO MSPI + FASE 0-1:
- MSPI Eje 5: Control de acceso (confirmación visual antes de registrar)
- E1: Validación de quién puede registrar (sesión + menú)
- E4: Hardening de sesión (mostrar usuario activo)
- E10: Auditoría (cada acción loguea quién hizo qué)

DATOS SENSIBLES:
- Foto: Mostrada solo en este modal transitorio (no se guarda en caché)
- Datos personales: No se loguean en texto plano
- Biometría: Vector ya procesado, no se guarda localmente
"""
from __future__ import annotations

import io
import tkinter as tk
from base64 import b64decode
from tkinter import messagebox, ttk
from typing import Any, Callable

from PIL import Image, ImageTk

from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError
from ui import theme
from ui.format_utils import format_db_timestamp
from ui.window_utils import centrar_ventana_al_mostrar

# Catálogos alineados con los mismos códigos usados en
# frontend/web/pages/modulos/registro/forms/*.php (Pilar 1: Coherencia,
# no inventar una numeración nueva para lo mismo).
GENERO_LABELS = {
    1: "Femenino",
    2: "Masculino",
    3: "No Binario",
    4: "Trans",
    99: "No Definido",
}

# database/schema/script-BD-SMARTCSET V.1.10.sql, columna
# tab_aprendices.ind_etdo_formacion.
ESTADO_FORMACION_LABELS = {
    1: "En formación",
    2: "Aplazado",
    3: "Retiro Voluntario",
    4: "Cancelado",
    5: "Condicionado",
    6: "Por certificar",
    7: "Certificado",
    8: "Trasladado",
    9: "Sin información",
}

JORNADA_LABELS = {1: "Mañana", 2: "Tarde", 3: "Noche", 4: "Mixta"}
MODALIDAD_LABELS = {1: "Presencial", 2: "Virtual", 3: "A Distancia"}

# Tiempo visible con los datos antes de registrar sin intervención humana.
AUTO_REGISTRO_MS = 2500
AUTO_CIERRE_ERROR_MS = 2500

MODAL_ANCHO = 1080
MODAL_ALTO = 640


class IdentificationConfirmationModal(tk.Toplevel):
    """Modal que se abre tras identificar exitosamente a una persona por
    biometría facial. Muestra foto + datos personales + placeholder huella.

    Usuario puede cancelar; si no interviene, el registro ocurre solo
    tras ``AUTO_REGISTRO_MS`` (confirmación visual breve).
    """

    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        persona_datos: dict[str, Any],
        modo: str = "ingreso",  # "ingreso" o "salida"
        on_confirmar: Callable[[dict[str, Any]], None] | None = None,
        auto_registro: bool = True,
    ) -> None:
        """
        `persona_datos`: dict con datos del resultado de `biometria/identificar.php`
            - id_persona: ID
            - nombres: Nombres
            - apellidos: Apellidos
            - id_tipo_docum: Tipo documento
            - num_docum: Número documento
            - id_tipo_persona: Tipo persona
            - nom_tipo_persona: Nombre tipo ("Aprendiz", etc.)
            - id_ficha: Ficha (si aplica)
            - nom_programa: Programa
            - id_entrada_centro: Entrada
            - nom_entrada: Nombre entrada (ej. "P-1")
            - foto_base64: Foto en base64 (opcional)
            - fec_nacimiento: Fecha nacimiento (opcional)

        `modo`: "ingreso" o "salida" para personalizar botones

        `on_confirmar`: callback(persona_datos) al presionar "Registrar Ingreso"
        """
        super().__init__(master)
        self._client = client
        self._persona_datos = persona_datos
        self._modo = modo
        self._on_confirmar = on_confirmar
        self._auto_registro = auto_registro
        self._auto_after_id: str | None = None
        self._registro_en_curso = False
        self._foto_image: ImageTk.PhotoImage | None = None
        self._subtitulo_label: tk.Label | None = None

        titulo = "Identificación Confirmada — Ingreso" if modo == "ingreso" else "Identificación Confirmada — Salida"
        self.title(titulo)
        self.configure(bg=theme.BG_CARD)
        self.geometry(f"{MODAL_ANCHO}x{MODAL_ALTO}")
        self.resizable(True, True)
        self.transient(master)
        self.grab_set()
        self.protocol("WM_DELETE_WINDOW", self._cancelar)

        self._build()
        centrar_ventana_al_mostrar(self, MODAL_ANCHO, MODAL_ALTO)
        if self._auto_registro:
            self._programar_auto_registro()

    # ---- UI ---------------------------------------------------------

    def _build(self) -> None:
        """Construye el layout: header + 3 columnas (foto, info, huella) + botones."""

        # Header
        header = ttk.Frame(self, style="Card.TFrame", padding=(20, 16, 20, 8))
        header.pack(fill="x")
        ttk.Label(
            header,
            text="✓ Identificación Confirmada",
            style="Card.TLabel",
            font=theme.FONT_TITLE,
        ).pack(anchor="w")
        subtitulo_base = (
            "Registrando ingreso automáticamente"
            if self._modo == "ingreso"
            else "Registrando salida automáticamente"
        )
        self._subtitulo_var = tk.StringVar(
            value=f"{subtitulo_base} en {AUTO_REGISTRO_MS // 1000} s..."
        )
        self._subtitulo_label = tk.Label(
            header,
            textvariable=self._subtitulo_var,
            bg=theme.BG_CARD,
            fg=theme.TEXT_MUTED,
            font=theme.FONT_BODY,
            anchor="w",
            justify="left",
            wraplength=900,
        )
        self._subtitulo_label.pack(anchor="w", pady=(2, 0))

        # Contenedor principal (3 columnas)
        content = ttk.Frame(self, style="App.TFrame", padding=(20, 12, 20, 12))
        content.pack(fill="both", expand=True)
        content.columnconfigure(0, weight=0)
        content.columnconfigure(1, weight=1)
        content.columnconfigure(2, weight=0)

        # ---- COLUMNA 1: FOTO (Izquierda) ----
        foto_frame = tk.Frame(content, bg=theme.BG_PANEL, padx=10, pady=10)
        foto_frame.grid(row=0, column=0, sticky="nsew", padx=(0, 15))

        ttk.Label(foto_frame, text="FOTOGRAFÍA", style="Muted.TLabel").pack()

        self._foto_canvas = tk.Canvas(
            foto_frame,
            width=150,
            height=180,
            bg="#f0f0f0",
            highlightthickness=2,
            highlightbackground=theme.BORDER,
        )
        self._foto_canvas.pack(pady=(8, 0))

        # Cargar y mostrar foto
        self._cargar_foto()

        # ---- COLUMNA 2: INFORMACIÓN (Centro) ----
        info_frame = ttk.Frame(content, style="App.TFrame")
        info_frame.grid(row=0, column=1, sticky="nsew", padx=15)
        info_frame.columnconfigure(0, weight=1)

        d = self._persona_datos
        nombres = d.get("nombres", "")
        apellidos = d.get("apellidos", "")
        nombre_completo = f"{nombres} {apellidos}".strip() or "—"
        genero = GENERO_LABELS.get(d.get("genero"), "—")
        activo = "Activo" if d.get("activo", True) else "Inactivo"
        tipo_doc = d.get("nom_tipo_docum") or d.get("tipo_doc", "—")
        ciudad = d.get("ciudad") or "—"
        depto = d.get("departamento") or "—"
        fec_nac = format_db_timestamp(d.get("fec_nacimiento")) or "—"
        fec_entrada = format_db_timestamp(d.get("fec_ultima_entrada"))
        fec_salida = format_db_timestamp(d.get("fec_ultima_salida"))

        datos_personales = [
            ("Documento", f"{tipo_doc} {d.get('documento', '—')}"),
            ("Nombre completo", nombre_completo),
            ("Tipo de persona", d.get("nom_tipo_persona") or "—"),
            ("Estado", activo),
            ("Correo", d.get("correo") or "—"),
            ("Fecha nacimiento", fec_nac),
            ("Género", genero),
            ("Teléfono fijo", d.get("tel_fijo") or "—"),
            ("Teléfono móvil", d.get("tel_movil") or "—"),
            ("Dirección", d.get("direccion") or "—"),
            ("Ciudad / Depto.", f"{ciudad} / {depto}"),
            ("Contacto emergencia", d.get("contacto_emergencia") or "—"),
            ("Tel. emergencia", d.get("tel_contacto_emergencia") or "—"),
            ("N.° visitas", str(d.get("num_visitas", 0))),
            ("Última entrada", fec_entrada or "—"),
            ("Última salida", fec_salida or "—"),
        ]

        self._agregar_seccion(
            info_frame, 0, "DATOS PERSONALES", datos_personales
        )

        # Datos de aprendiz/ficha — solo si la persona tiene ficha asignada
        # (LEFT JOIN en el backend: NULL para instructores/funcionarios/
        # contratistas/visitantes, que no tienen tab_aprendices).
        if d.get("id_ficha") is not None:
            estado_form = ESTADO_FORMACION_LABELS.get(
                d.get("estado_formacion"), "—"
            )
            jornada = JORNADA_LABELS.get(d.get("id_jornada"), "—")
            modalidad = MODALIDAD_LABELS.get(d.get("ind_modalidad"), "—")
            datos_institucionales = [
                ("Ficha", str(d.get("id_ficha"))),
                ("Programa", d.get("nom_programa") or "—"),
                ("Estado formación", estado_form),
                ("Jornada", jornada),
                ("Modalidad", modalidad),
                ("N.° llamados atención", str(d.get("num_llamados", 0))),
            ]
            self._agregar_seccion(
                info_frame, 1, "DATOS INSTITUCIONALES", datos_institucionales
            )

        # ---- COLUMNA 3: HUELLA DACTILAR (Derecha) ----
        huella_frame = tk.Frame(content, bg=theme.BG_PANEL, padx=10, pady=10)
        huella_frame.grid(row=0, column=2, sticky="nsew", padx=(15, 0))

        ttk.Label(huella_frame, text="HUELLA DACTILAR", style="Muted.TLabel").pack()

        huella_canvas = tk.Canvas(
            huella_frame,
            width=120,
            height=150,
            bg="#e8e8e8",
            highlightthickness=2,
            highlightbackground=theme.BORDER,
        )
        huella_canvas.pack(pady=(8, 0))

        # Placeholder texto
        huella_canvas.create_text(
            60, 75,
            text="🔒\n\nFEATURE EN\nDESARROLLO",
            font=("Arial", 9),
            fill="#999999",
            justify="center",
        )

        # ---- FOOTER: BOTONES ----
        footer = ttk.Frame(self, style="App.TFrame", padding=(20, 0, 20, 12))
        footer.pack(fill="x", side="bottom")
        footer.columnconfigure(0, weight=1)

        ttk.Button(
            footer,
            text="✓ Registrar Ingreso" if self._modo == "ingreso" else "✓ Registrar Salida",
            style="Primary.TButton",
            command=self._confirmar,
        ).pack(side="left", padx=(0, 8))

        ttk.Button(
            footer,
            text="Ver Detalles",
            style="Nav.TButton",
            command=self._ver_detalles,
        ).pack(side="left", padx=(0, 8))

        ttk.Button(
            footer,
            text="✗ Cancelar",
            style="Danger.TButton",
            command=self._cancelar,
        ).pack(side="left")

    def _agregar_seccion(
        self,
        parent: ttk.Frame,
        orden: int,
        titulo: str,
        campos: list[tuple[str, str]],
    ) -> None:
        """Renderiza una sección con título + campos en 2 pares
        label:valor por fila (compacta ~20 campos en el alto disponible
        sin necesitar scroll)."""
        seccion = ttk.Frame(parent, style="App.TFrame")
        seccion.grid(row=orden, column=0, sticky="ew", pady=(0, 14))
        seccion.columnconfigure(1, weight=1)
        seccion.columnconfigure(3, weight=1)

        ttk.Label(seccion, text=titulo, style="Title.TLabel").grid(
            row=0, column=0, columnspan=4, sticky="w", pady=(0, 8)
        )

        for idx, (label, valor) in enumerate(campos):
            fila = idx // 2 + 1
            col_base = 0 if idx % 2 == 0 else 2
            ttk.Label(seccion, text=f"{label}:", style="Muted.TLabel").grid(
                row=fila, column=col_base, sticky="w", pady=2,
                padx=(0, 4) if col_base == 2 else 0,
            )
            ttk.Label(
                seccion, text=valor, style="App.TLabel", wraplength=180,
            ).grid(
                row=fila, column=col_base + 1, sticky="w",
                padx=(6, 14), pady=2,
            )

    # ---- Lógica -----

    def _programar_auto_registro(self) -> None:
        self._auto_after_id = self.after(AUTO_REGISTRO_MS, self._confirmar)

    def _programar_cierre(self, ms: int = AUTO_CIERRE_ERROR_MS) -> None:
        self._cancelar_auto_registro()
        self._auto_after_id = self.after(ms, self._cerrar_automatico)

    def _cerrar_automatico(self) -> None:
        self._auto_after_id = None
        if self.winfo_exists():
            self.grab_release()
            self.destroy()

    def _mostrar_error_y_cerrar(self, mensaje: str) -> None:
        segundos = AUTO_CIERRE_ERROR_MS // 1000
        self._subtitulo_var.set(
            f"❌ {mensaje}\nCerrando en {segundos} s para la siguiente persona..."
        )
        if self._subtitulo_label is not None:
            self._subtitulo_label.configure(fg=theme.ERROR)
        self._programar_cierre()

    def _cancelar_auto_registro(self) -> None:
        if self._auto_after_id is not None:
            self.after_cancel(self._auto_after_id)
            self._auto_after_id = None

    def _cargar_foto(self) -> None:
        """Carga la foto en base64 y la muestra en el canvas."""
        foto_b64 = self._persona_datos.get("foto_base64")
        if not foto_b64:
            # No hay foto, mostrar placeholder
            self._foto_canvas.create_text(
                75, 90,
                text="Sin foto",
                font=("Arial", 10),
                fill="#999999",
            )
            return

        try:
            # Decodificar base64 → imagen PIL
            foto_bytes = b64decode(foto_b64)
            foto_pil = Image.open(io.BytesIO(foto_bytes))

            # Redimensionar a 150x180
            foto_pil = foto_pil.resize((150, 180), Image.Resampling.LANCZOS)

            # Convertir a PhotoImage de Tkinter
            self._foto_image = ImageTk.PhotoImage(foto_pil)
            self._foto_canvas.create_image(0, 0, image=self._foto_image, anchor="nw")
        except Exception as e:
            # Si falla la carga de foto, mostrar error pero no bloquear
            self._foto_canvas.create_text(
                75, 90,
                text=f"Error cargando\nfoto: {str(e)[:20]}",
                font=("Arial", 9),
                fill="#cc0000",
            )

    def _confirmar(self) -> None:
        """Registra el ingreso/salida."""
        if self._registro_en_curso:
            return
        self._registro_en_curso = True
        self._cancelar_auto_registro()
        if self._on_confirmar:
            try:
                self._on_confirmar(self._persona_datos)
                self.destroy()
            except (SmartcsetApiError, SmartcsetConnectionError) as exc:
                self._registro_en_curso = False
                self._mostrar_error_y_cerrar(str(exc))

    def _ver_detalles(self) -> None:
        """Abre una ventana con detalles completos de la persona (TODO)."""
        messagebox.showinfo(
            "Ver Detalles",
            "Feature en desarrollo: aquí irá ficha completa de la persona.\n\n"
            f"ID: {self._persona_datos.get('id_persona')}\n"
            f"Nombre: {self._persona_datos.get('nombres')} {self._persona_datos.get('apellidos')}\n"
            f"Programa: {self._persona_datos.get('nom_programa')}"
        )

    def _cancelar(self) -> None:
        """Cierra el modal sin registrar."""
        self._cancelar_auto_registro()
        self.destroy()
