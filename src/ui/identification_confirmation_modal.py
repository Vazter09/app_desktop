"""
Confirmación de identificación biométrica — panel embebido en la columna
central de portería (no tapa cámara ni huella).

Tras identificar, sustituye temporalmente el formulario "Nuevo ingreso".
Misma cáscara visual que ``IngresoFormPanel`` (padding, fondo, pie con
mensaje + botón) para que el cambio de panel no altere el ancho/alto de
la columna central.
"""
from __future__ import annotations

import io
import tkinter as tk
from base64 import b64decode
from tkinter import ttk
from typing import Any, Callable

from PIL import Image, ImageTk

from app_log import flush_handlers, get_logger
from smartcset_client import (
    SmartcsetApiError,
    SmartcsetClient,
    SmartcsetConnectionError,
)
from ui import theme
from ui.field_validators import serial_equipo_desde_payload
from ui.format_utils import (
    es_tipo_instructor,
    label_estado_formacion,
    label_estado_instructor,
    label_tipo_contrato_instructor,
)
from ui.responsive import sfont, sx

log = get_logger("ui.identification_confirmation_modal")

AUTO_REGISTRO_MS = 2500

# Foto cuadrada centrada (cabe en la misma caja que Nuevo ingreso).
_FOTO_SIZE_BASE = 152

# Tipografía local: un poco mayor que el formulario, solo en este panel.
_FONT_TITULO_BASE = ("Segoe UI", 11, "bold")
_FONT_LABEL_BASE = ("Segoe UI", 9)
_FONT_VALOR_BASE = ("Segoe UI", 11, "bold")


class IdentificationConfirmationPanel(tk.Frame):
    """Confirmación embebida: misma cáscara y pie que Nuevo ingreso."""

    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        persona_datos: dict[str, Any],
        modo: str = "ingreso",
        on_confirmar: Callable[[dict[str, Any]], None] | None = None,
        *,
        persona_existente: bool = True,
        on_cerrado: Callable[[], None] | None = None,
        on_error: Callable[[str], None] | None = None,
    ) -> None:
        # Misma cáscara que IngresoFormPanel (bg + padding).
        super().__init__(master, bg=theme.BG_PANEL, padx=sx(14), pady=sx(12))
        self._client = client
        self._persona_datos = persona_datos
        self._modo = modo
        self._on_confirmar = on_confirmar
        self._persona_existente = persona_existente
        self._on_cerrado = on_cerrado
        self._on_error = on_error
        self._auto_after_id: str | None = None
        self._registro_en_curso = False
        self._cerrado = False
        self._foto_image: ImageTk.PhotoImage | None = None
        self._foto_size = sx(_FOTO_SIZE_BASE)
        self._font_titulo = sfont(_FONT_TITULO_BASE)
        self._font_label = sfont(_FONT_LABEL_BASE)
        self._font_valor = sfont(_FONT_VALOR_BASE)

        self._build()
        # Registro automático (~2.5 s) salvo que el operario pulse el botón.
        self._programar_auto_registro()

    def _build(self) -> None:
        # Pie: solo botón. Errores y avisos van a la barra de estado
        # inferior del panel de portería — nunca encima del botón.
        footer = tk.Frame(self, bg=theme.BG_PANEL)
        footer.pack(side="bottom", fill="x")

        if self._modo == "ingreso":
            btn_text = "✓ Registrar ingreso"
        elif self._modo == "actualizar_captura":
            btn_text = "Actualizar captura"
        elif self._modo in ("registrado", "enrolado"):
            btn_text = "✓ Continuar"
        else:
            btn_text = "✓ Registrar salida"

        self._footer_btn = ttk.Button(
            footer,
            text=btn_text,
            style="Primary.TButton",
            command=self._confirmar,
        )
        self._footer_btn.pack(fill="x", ipady=2)

        # Cuerpo: contenido compacto y centrado (evita huecos grandes).
        body = tk.Frame(self, bg=theme.BG_PANEL)
        body.pack(side="top", fill="both", expand=True)

        content = tk.Frame(body, bg=theme.BG_PANEL)
        content.place(relx=0.5, rely=0.48, anchor="center")

        if self._modo == "registrado":
            titulo = "✓  Ingreso registrado"
        elif self._modo == "enrolado":
            titulo = "✓  Rostro enrolado"
        elif self._modo == "salida":
            titulo = "⚠  Se registrará SALIDA"
        elif self._modo == "actualizar_captura":
            titulo = "✓  Persona encontrada"
        elif self._persona_existente:
            titulo = "✓  Persona encontrada — ingreso"
        else:
            titulo = "✓  Identificación confirmada"
        ttk.Label(
            content,
            text=titulo,
            style="Card.TLabel",
            font=self._font_titulo,
        ).pack(anchor="center")

        foto_frame = tk.Frame(content, bg=theme.BG_PANEL)
        foto_frame.pack(fill="x", pady=(sx(14), sx(10)))
        ttk.Label(
            foto_frame,
            text="FOTOGRAFÍA",
            style="Muted.TLabel",
            font=self._font_label,
        ).pack()
        self._foto_canvas = tk.Canvas(
            foto_frame,
            width=self._foto_size,
            height=self._foto_size,
            bg=theme.BG_DEEP,
            highlightthickness=1,
            highlightbackground=theme.BORDER,
        )
        self._foto_canvas.pack(pady=(6, 0))
        self._cargar_foto()

        d = self._persona_datos
        nombres = str(d.get("nombres") or "")
        apellidos = str(d.get("apellidos") or "")
        nombre_completo = f"{nombres} {apellidos}".strip() or "—"

        equipo_txt = serial_equipo_desde_payload(d) or "—"

        if es_tipo_instructor(d.get("tipo_persona")):
            campos = [
                ("Nombre", nombre_completo),
                ("Tipo", str(d.get("nom_tipo_persona") or "Instructor")),
                (
                    "Estado",
                    label_estado_instructor(d.get("ind_estado_instructor")),
                ),
                (
                    "Tipo contrato",
                    label_tipo_contrato_instructor(d.get("ind_tipo_contrato")),
                ),
                ("Equipo (serial)", equipo_txt),
            ]
        else:
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
                ("Equipo (serial)", equipo_txt),
            ]

        grid = tk.Frame(content, bg=theme.BG_PANEL)
        grid.pack(fill="x", pady=(4, 0))
        grid.columnconfigure(0, weight=1, uniform="info")
        grid.columnconfigure(1, weight=1, uniform="info")

        for idx, (label, valor) in enumerate(campos):
            row, col = divmod(idx, 2)
            cell = tk.Frame(grid, bg=theme.BG_PANEL)
            cell.grid(
                row=row,
                column=col,
                sticky="nw",
                padx=(0 if col == 0 else sx(18), 0 if col == 1 else sx(18)),
                pady=(0 if row == 0 else sx(12), 0),
            )
            tk.Label(
                cell,
                text=label,
                bg=theme.BG_PANEL,
                fg=theme.TEXT_MUTED,
                font=self._font_label,
                anchor="w",
            ).pack(anchor="w")
            tk.Label(
                cell,
                text=valor,
                bg=theme.BG_PANEL,
                fg=theme.TEXT_PRIMARY,
                font=self._font_valor,
                anchor="w",
                justify="left",
                wraplength=sx(170),
            ).pack(anchor="w", pady=(2, 0))

    def _programar_auto_registro(self) -> None:
        self._auto_after_id = self.after(AUTO_REGISTRO_MS, self._confirmar)

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
            # Sin rostro enrolado: caja oscura vacía (sin inventar imagen).
            self._foto_canvas.configure(bg=theme.BG_DEEP)
            return
        try:
            foto_pil = Image.open(io.BytesIO(b64decode(foto_b64)))
            foto_pil = foto_pil.resize(
                (self._foto_size, self._foto_size), Image.Resampling.LANCZOS
            )
            self._foto_image = ImageTk.PhotoImage(foto_pil)
            self._foto_canvas.create_image(0, 0, image=self._foto_image, anchor="nw")
        except Exception as exc:
            log.warning("Error al mostrar foto de confirmación: %s", exc)
            flush_handlers()
            self._foto_canvas.configure(bg=theme.BG_DEEP)
            self._foto_canvas.create_text(
                self._foto_size // 2,
                self._foto_size // 2,
                text=f"Error foto\n{str(exc)[:18]}",
                font=("Arial", 8),
                fill=theme.ERROR,
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
                log.error("Registro automático (confirmación): %s", exc)
                flush_handlers()
                self._registro_en_curso = False
                # No pintar el error en este panel: barra de estado + cierre.
                if self._on_error is not None:
                    self._on_error(str(exc))
                self._cerrar()
        else:
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
