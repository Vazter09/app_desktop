"""
Confirmación de identificación biométrica — panel embebido en la columna
central de portería (no tapa cámara ni huella).

Tras identificar, sustituye temporalmente el formulario "Nuevo ingreso".
Si no hay intervención, registra solo tras ``AUTO_REGISTRO_MS`` y vuelve
al formulario.
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

AUTO_REGISTRO_MS = 2500
AUTO_CIERRE_ERROR_MS = 2500

FOTO_W = 160
FOTO_H = 192


class IdentificationConfirmationPanel(ttk.Frame):
    """Confirmación embebida (columna central): foto + datos + auto-registro."""

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
        super().__init__(master, style="Card.TFrame", padding=(12, 10))
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

        self.columnconfigure(0, weight=1)
        self.rowconfigure(1, weight=1)
        self._build()
        if self._auto_registro:
            self._programar_auto_registro()

    def _build(self) -> None:
        header = ttk.Frame(self, style="Card.TFrame")
        header.grid(row=0, column=0, sticky="ew", pady=(0, 10))

        ttk.Label(
            header,
            text=(
                "✓ Persona encontrada"
                if self._persona_existente
                else "✓ Identificación confirmada"
            ),
            style="Card.TLabel",
            font=theme.FONT_BODY_BOLD,
        ).pack(anchor="w")

        if self._persona_existente:
            subtitulo_base = (
                "Registrando ingreso automáticamente"
                if self._modo == "ingreso"
                else "Registrando salida automáticamente"
            )
        else:
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
            bg=theme.BG_PANEL,
            fg=theme.TEXT_MUTED,
            font=theme.FONT_LABEL_SMALL,
            anchor="w",
            justify="left",
            wraplength=300,
        )
        self._subtitulo_label.pack(anchor="w", pady=(4, 0))

        body = tk.Frame(self, bg=theme.BG_PANEL)
        body.grid(row=1, column=0, sticky="nsew")
        body.columnconfigure(0, weight=1)
        body.rowconfigure(1, weight=1)

        # Foto más grande y centrada
        foto_frame = tk.Frame(body, bg=theme.BG_PANEL)
        foto_frame.grid(row=0, column=0, sticky="ew", pady=(0, 16))
        ttk.Label(foto_frame, text="FOTOGRAFÍA", style="Muted.TLabel").pack()
        self._foto_canvas = tk.Canvas(
            foto_frame,
            width=FOTO_W,
            height=FOTO_H,
            bg="#f0f0f0",
            highlightthickness=1,
            highlightbackground=theme.BORDER,
        )
        self._foto_canvas.pack(pady=(8, 0))
        self._cargar_foto()

        # Solo Nombre / Tipo / Estado / Ficha
        d = self._persona_datos
        nombres = d.get("nombres", "")
        apellidos = d.get("apellidos", "")
        nombre_completo = f"{nombres} {apellidos}".strip() or "—"
        activo = "Activo" if d.get("activo", True) else "Inactivo"
        ficha = d.get("id_ficha")
        ficha_txt = str(ficha) if ficha is not None else "—"

        campos = [
            ("Nombre", nombre_completo),
            ("Tipo", d.get("nom_tipo_persona") or "—"),
            ("Estado", activo),
            ("Ficha", ficha_txt),
        ]

        info = ttk.Frame(body, style="Card.TFrame")
        info.grid(row=1, column=0, sticky="nsew")
        info.columnconfigure(1, weight=1)

        for idx, (label, valor) in enumerate(campos):
            ttk.Label(info, text=f"{label}", style="Muted.TLabel").grid(
                row=idx * 2,
                column=0,
                columnspan=2,
                sticky="w",
                pady=(12 if idx else 0, 2),
            )
            ttk.Label(
                info,
                text=valor,
                style="Card.TLabel",
                font=theme.FONT_BODY_BOLD,
                wraplength=280,
            ).grid(row=idx * 2 + 1, column=0, columnspan=2, sticky="w")

        footer = ttk.Frame(self, style="Card.TFrame")
        footer.grid(row=2, column=0, sticky="ew", pady=(16, 0))
        footer.columnconfigure(0, weight=1)

        ttk.Button(
            footer,
            text=(
                "✓ Registrar ingreso"
                if self._modo == "ingreso"
                else "✓ Registrar salida"
            ),
            style="Primary.TButton",
            command=self._confirmar,
        ).pack(fill="x", pady=(0, 6))

        row_btns = ttk.Frame(footer, style="Card.TFrame")
        row_btns.pack(fill="x")
        row_btns.columnconfigure(0, weight=1)
        row_btns.columnconfigure(1, weight=1)
        ttk.Button(
            row_btns,
            text="Ver detalles",
            style="Nav.TButton",
            command=self._ver_detalles,
        ).grid(row=0, column=0, sticky="ew", padx=(0, 4))
        ttk.Button(
            row_btns,
            text="Cancelar",
            style="Danger.TButton",
            command=self._cancelar,
        ).grid(row=0, column=1, sticky="ew", padx=(4, 0))

    def _programar_auto_registro(self) -> None:
        self._auto_after_id = self.after(AUTO_REGISTRO_MS, self._confirmar)

    def _programar_cierre(self, ms: int = AUTO_CIERRE_ERROR_MS) -> None:
        self._cancelar_auto_registro()
        self._auto_after_id = self.after(ms, self._cerrar)

    def _mostrar_error_y_cerrar(self, mensaje: str) -> None:
        segundos = AUTO_CIERRE_ERROR_MS // 1000
        self._subtitulo_var.set(
            f"❌ {mensaje}\nCerrando en {segundos} s..."
        )
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
                FOTO_W // 2,
                FOTO_H // 2,
                text="Sin foto",
                font=("Arial", 10),
                fill="#999999",
            )
            return
        try:
            foto_pil = Image.open(io.BytesIO(b64decode(foto_b64)))
            foto_pil = foto_pil.resize((FOTO_W, FOTO_H), Image.Resampling.LANCZOS)
            self._foto_image = ImageTk.PhotoImage(foto_pil)
            self._foto_canvas.create_image(0, 0, image=self._foto_image, anchor="nw")
        except Exception as exc:
            self._foto_canvas.create_text(
                FOTO_W // 2,
                FOTO_H // 2,
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

    def _ver_detalles(self) -> None:
        messagebox.showinfo(
            "Ver Detalles",
            "Feature en desarrollo: aquí irá ficha completa de la persona.\n\n"
            f"ID: {self._persona_datos.get('id_persona')}\n"
            f"Nombre: {self._persona_datos.get('nombres')} "
            f"{self._persona_datos.get('apellidos')}\n"
            f"Programa: {self._persona_datos.get('nom_programa')}",
        )

    def _cancelar(self) -> None:
        self._cancelar_auto_registro()
        self._cerrar()

    def _cerrar(self) -> None:
        if self._cerrado:
            return
        self._cerrado = True
        self._cancelar_auto_registro()
        callback = self._on_cerrado
        try:
            if self.winfo_exists():
                self.destroy()
        except tk.TclError:
            pass
        if callback is not None:
            callback()


# Alias por compatibilidad con imports/documentación previos.
IdentificationConfirmationModal = IdentificationConfirmationPanel
