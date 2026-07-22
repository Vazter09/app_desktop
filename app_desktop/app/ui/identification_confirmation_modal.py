"""
Confirmación de identificación biométrica — panel embebido en la columna
central de portería (no tapa cámara ni huella).

Tras identificar, sustituye temporalmente el formulario "Nuevo ingreso".
Misma cáscara visual que ``IngresoFormPanel`` (tamaño, padding, fondo) para
que el cambio de panel no altere el ancho/alto de la columna central.
"""
from __future__ import annotations

import io
import tkinter as tk
from base64 import b64decode
from tkinter import ttk
from typing import Any, Callable

from PIL import Image, ImageTk

from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError
from ui import theme
from ui.format_utils import label_estado_formacion

AUTO_REGISTRO_MS = 2500
AUTO_CIERRE_ERROR_MS = 2500

# Foto cuadrada (2×2 visual), centrada encima de la rejilla de datos.
FOTO_SIZE = 168


class IdentificationConfirmationPanel(tk.Frame):
    """Confirmación embebida: mismo tamaño de caja que Nuevo ingreso."""

    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        persona_datos: dict[str, Any],
        modo: str = "ingreso",
        on_confirmar: Callable[[dict[str, Any]], None] | None = None,
        auto_registro: bool = True,
        *,
        persona_existente: bool = True,
        on_cerrado: Callable[[], None] | None = None,
    ) -> None:
        # Misma cáscara que IngresoFormPanel (bg + padding).
        super().__init__(master, bg=theme.BG_PANEL, padx=14, pady=12)
        self._client = client
        self._persona_datos = persona_datos
        self._modo = modo
        self._on_confirmar = on_confirmar
        self._auto_registro = auto_registro
        self._persona_existente = persona_existente
        self._on_cerrado = on_cerrado
        self._auto_after_id: str | None = None
        self._registro_en_curso = False
        self._cerrado = False
        self._foto_image: ImageTk.PhotoImage | None = None
        self._subtitulo_label: tk.Label | None = None

        self._build()
        if self._auto_registro:
            self._programar_auto_registro()

    def _build(self) -> None:
        # Pie anclado abajo (mismo patrón que Nuevo ingreso).
        footer = tk.Frame(self, bg=theme.BG_PANEL)
        footer.pack(side="bottom", fill="x")

        if self._modo == "ingreso":
            btn_text = "✓ Registrar ingreso"
        elif self._modo == "actualizar_captura":
            btn_text = "INGRESÓ"
        else:
            btn_text = "✓ Registrar salida"

        # Espacio del botón superior (ya no se muestra Cancelar arriba).
        # Deja INGRESÓ / confirmar en la posición que ocupaba Cancelar.
        tk.Frame(footer, bg=theme.BG_PANEL, height=36).pack(
            fill="x", pady=(0, 6)
        )

        ttk.Button(
            footer,
            text=btn_text,
            style="Primary.TButton",
            command=self._confirmar,
        ).pack(fill="x", ipady=4)

        body = tk.Frame(self, bg=theme.BG_PANEL)
        body.pack(side="top", fill="both", expand=True)

        head = tk.Frame(body, bg=theme.BG_PANEL)
        head.pack(fill="x")
        ttk.Label(
            head,
            text=(
                "✓  Persona encontrada"
                if self._persona_existente
                else "✓  Identificación confirmada"
            ),
            style="Card.TLabel",
            font=theme.FONT_BODY_BOLD,
        ).pack(anchor="w")

        if self._modo == "ingreso":
            subtitulo_base = "Registrando ingreso automáticamente"
        elif self._modo == "actualizar_captura":
            subtitulo_base = "Actualizando captura del ingreso"
        else:
            subtitulo_base = "Registrando salida automáticamente"
        self._subtitulo_var = tk.StringVar(
            value=f"{subtitulo_base} en {AUTO_REGISTRO_MS // 1000} s..."
        )
        self._subtitulo_label = tk.Label(
            head,
            textvariable=self._subtitulo_var,
            bg=theme.BG_PANEL,
            fg=theme.TEXT_MUTED,
            font=theme.FONT_LABEL_SMALL,
            anchor="w",
            justify="left",
            wraplength=280,
        )
        self._subtitulo_label.pack(anchor="w", pady=(4, 0))

        # Foto cuadrada centrada
        foto_frame = tk.Frame(body, bg=theme.BG_PANEL)
        foto_frame.pack(fill="x", pady=(16, 12))
        ttk.Label(foto_frame, text="FOTOGRAFÍA", style="Muted.TLabel").pack()
        self._foto_canvas = tk.Canvas(
            foto_frame,
            width=FOTO_SIZE,
            height=FOTO_SIZE,
            bg="#f0f0f0",
            highlightthickness=1,
            highlightbackground=theme.BORDER,
        )
        self._foto_canvas.pack(pady=(6, 0))
        self._cargar_foto()

        # Rejilla 2×2: Nombre | Tipo / Estado | Ficha
        d = self._persona_datos
        nombres = str(d.get("nombres") or "")
        apellidos = str(d.get("apellidos") or "")
        nombre_completo = f"{nombres} {apellidos}".strip() or "—"
        estado_txt = label_estado_formacion(
            d.get("estado_formacion")
            if d.get("estado_formacion") is not None
            else d.get("ind_etdo_formacion")
        )
        ficha = d.get("id_ficha")
        ficha_txt = str(ficha) if ficha not in (None, "", 0) else "—"

        campos = [
            ("Nombre", nombre_completo),
            ("Tipo", str(d.get("nom_tipo_persona") or "—")),
            ("Estado", estado_txt),
            ("Ficha", ficha_txt),
        ]

        grid = tk.Frame(body, bg=theme.BG_PANEL)
        grid.pack(fill="both", expand=True, pady=(4, 0))
        grid.columnconfigure(0, weight=1, uniform="info")
        grid.columnconfigure(1, weight=1, uniform="info")
        grid.rowconfigure(0, weight=1)
        grid.rowconfigure(1, weight=1)

        for idx, (label, valor) in enumerate(campos):
            row, col = divmod(idx, 2)
            cell = tk.Frame(grid, bg=theme.BG_PANEL)
            cell.grid(
                row=row,
                column=col,
                sticky="nsew",
                padx=(0 if col == 0 else 8, 0 if col == 1 else 8),
                pady=(0 if row == 0 else 12, 0),
            )
            ttk.Label(cell, text=label, style="Muted.TLabel").pack(anchor="w")
            ttk.Label(
                cell,
                text=valor,
                style="Card.TLabel",
                font=theme.FONT_BODY_BOLD,
                wraplength=160,
            ).pack(anchor="w", pady=(2, 0))

    def _programar_auto_registro(self) -> None:
        self._auto_after_id = self.after(AUTO_REGISTRO_MS, self._confirmar)

    def _programar_cierre(self, ms: int = AUTO_CIERRE_ERROR_MS) -> None:
        self._cancelar_auto_registro()
        self._auto_after_id = self.after(ms, self._cerrar)

    def _mostrar_error_y_cerrar(self, mensaje: str) -> None:
        segundos = AUTO_CIERRE_ERROR_MS // 1000
        self._subtitulo_var.set(f"❌ {mensaje}\nCerrando en {segundos} s...")
        if self._subtitulo_label is not None:
            self._subtitulo_label.configure(fg=theme.ERROR)
        self._programar_cierre()

    def _cancelar_auto_registro(self) -> None:
        if self._auto_after_id is not None:
            try:
                self.after_cancel(self._auto_after_id)
            except tk.TclError:
                pass
            self._auto_after_id = None

    def _cargar_foto(self) -> None:
        foto_b64 = self._persona_datos.get("foto_base64")
        if not foto_b64:
            self._foto_canvas.create_text(
                FOTO_SIZE // 2,
                FOTO_SIZE // 2,
                text="Sin foto",
                font=("Arial", 10),
                fill="#999999",
            )
            return
        try:
            foto_pil = Image.open(io.BytesIO(b64decode(foto_b64)))
            foto_pil = foto_pil.resize(
                (FOTO_SIZE, FOTO_SIZE), Image.Resampling.LANCZOS
            )
            self._foto_image = ImageTk.PhotoImage(foto_pil)
            self._foto_canvas.create_image(0, 0, image=self._foto_image, anchor="nw")
        except Exception as exc:
            self._foto_canvas.create_text(
                FOTO_SIZE // 2,
                FOTO_SIZE // 2,
                text=f"Error foto\n{str(exc)[:18]}",
                font=("Arial", 8),
                fill="#cc0000",
                justify="center",
            )

    def _confirmar(self) -> None:
        if self._registro_en_curso or self._cerrado:
            return
        self._registro_en_curso = True
        self._cancelar_auto_registro()
        if self._on_confirmar:
            try:
                self._on_confirmar(self._persona_datos)
                self._cerrar()
            except (SmartcsetApiError, SmartcsetConnectionError) as exc:
                self._registro_en_curso = False
                self._mostrar_error_y_cerrar(str(exc))
        else:
            self._cerrar()

    def _cancelar(self) -> None:
        self._cancelar_auto_registro()
        self._cerrar()

    def _cerrar(self) -> None:
        if self._cerrado:
            return
        self._cerrado = True
        self._cancelar_auto_registro()
        self._persona_datos = {}
        self._foto_image = None
        callback = self._on_cerrado
        try:
            if self.winfo_exists():
                self.destroy()
        except tk.TclError:
            pass
        if callback is not None:
            callback()


IdentificationConfirmationModal = IdentificationConfirmationPanel
