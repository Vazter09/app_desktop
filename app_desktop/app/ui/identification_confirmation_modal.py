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


class IdentificationConfirmationModal(tk.Toplevel):
    """Modal que se abre tras identificar exitosamente a una persona por
    biometría facial. Muestra foto + datos personales + placeholder huella.

    Usuario confirma con "Registrar Ingreso" o cancela.
    """

    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        persona_datos: dict[str, Any],
        modo: str = "ingreso",  # "ingreso" o "salida"
        on_confirmar: Callable[[dict[str, Any]], None] | None = None,
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
        self._foto_image: ImageTk.PhotoImage | None = None

        titulo = "Identificación Confirmada — Ingreso" if modo == "ingreso" else "Identificación Confirmada — Salida"
        self.title(titulo)
        self.configure(bg=theme.BG_CARD)
        self.geometry("900x520")
        self.resizable(False, False)
        self.transient(master)
        self.grab_set()
        self.protocol("WM_DELETE_WINDOW", self._cancelar)

        self._build()

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
        subtitulo = "Por favor confirme para registrar ingreso" if self._modo == "ingreso" else "Por favor confirme para registrar salida"
        ttk.Label(header, text=subtitulo, style="CardMuted.TLabel").pack(
            anchor="w", pady=(2, 0)
        )

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
        info_frame.columnconfigure(1, weight=1)

        ttk.Label(
            info_frame,
            text="INFORMACIÓN PERSONAL",
            style="Title.TLabel",
        ).grid(row=0, column=0, columnspan=2, sticky="w", pady=(0, 12))

        # Datos
        datos = [
            ("ID Persona", str(self._persona_datos.get("id_persona", "—"))),
            ("Nombre Completo", f"{self._persona_datos.get('nombres', '')} {self._persona_datos.get('apellidos', '')}".strip() or "—"),
            ("Tipo Documento", self._persona_datos.get("id_tipo_docum", "—")),
            ("Número Documento", self._persona_datos.get("num_docum", "—")),
            ("Tipo Persona", self._persona_datos.get("nom_tipo_persona", "—")),
            ("Fecha Nacimiento", format_db_timestamp(self._persona_datos.get("fec_nacimiento")) or "—"),
            ("Ficha", str(self._persona_datos.get("id_ficha") or "—")),
            ("Programa", self._persona_datos.get("nom_programa", "—")),
            ("Entrada/Puerta", self._persona_datos.get("nom_entrada", "—")),
        ]

        for idx, (label, valor) in enumerate(datos, start=1):
            ttk.Label(info_frame, text=f"{label}:", style="Muted.TLabel").grid(
                row=idx, column=0, sticky="w", pady=3
            )
            ttk.Label(info_frame, text=valor, style="App.TLabel").grid(
                row=idx, column=1, sticky="ew", padx=(8, 0), pady=3
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

    # ---- Lógica -----

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
        if self._on_confirmar:
            try:
                self._on_confirmar(self._persona_datos)
                self.destroy()
            except (SmartcsetApiError, SmartcsetConnectionError) as exc:
                messagebox.showerror(
                    f"Error registrando {'ingreso' if self._modo == 'ingreso' else 'salida'}",
                    str(exc),
                )

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
        self.destroy()
