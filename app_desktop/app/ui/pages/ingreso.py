"""
Página "Registro de ingreso" — réplica funcional de
frontend/web/pages/modulos/porteria/ingreso/index.php: tabla de
"Ingresos de hoy" + diálogo "Nuevo ingreso" que reutiliza los mismos
endpoints reales que usa la web (consultar → registrar), método
manual (`metodo_aut=1`) — igual que el flujo de teclado/documento de
la web. La captura biométrica se agrega en una fase posterior.
"""
from __future__ import annotations

import tkinter as tk
from tkinter import messagebox, ttk
from typing import Any, Callable

from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError
from ui import theme
from ui.facial_modal import FacialRecognitionModal
from ui.format_utils import WITH_SECONDS_FORMAT, format_db_timestamp


class IngresoPage(ttk.Frame):
    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        usuario: dict[str, Any],
        on_navigate: Callable[[str], None],
    ) -> None:
        super().__init__(master, style="App.TFrame", padding=20)
        self._client = client
        self.columnconfigure(0, weight=1)
        self.rowconfigure(1, weight=1)

        head = ttk.Frame(self, style="App.TFrame")
        head.grid(row=0, column=0, sticky="ew", pady=(0, 10))
        head.columnconfigure(0, weight=1)
        ttk.Label(head, text="⏱ Ingresos de hoy", style="Title.TLabel").grid(
            row=0, column=0, sticky="w"
        )
        ttk.Button(
            head, text="⟳ Refrescar", style="Nav.TButton", command=self.refresh
        ).grid(row=0, column=1, sticky="e", padx=(0, 8))
        ttk.Button(
            head,
            text="📷 Reconocimiento facial",
            style="Nav.TButton",
            command=self._abrir_reconocimiento,
        ).grid(row=0, column=2, sticky="e", padx=(0, 8))
        ttk.Button(
            head, text="+ Nuevo ingreso", style="Primary.TButton", command=self._abrir_dialogo
        ).grid(row=0, column=3, sticky="e")

        columns = ("hora", "persona", "tipo", "ficha", "programa", "entrada")
        self._tree = ttk.Treeview(self, columns=columns, show="headings", height=16)
        for col, label, width in (
            ("hora", "Hora/Fecha", 160),
            ("persona", "Persona", 220),
            ("tipo", "Tipo", 100),
            ("ficha", "Ficha", 80),
            ("programa", "Carrera / Programa", 240),
            ("entrada", "Puerta", 130),
        ):
            self._tree.heading(col, text=label)
            self._tree.column(col, width=width, anchor="w")
        self._tree.grid(row=1, column=0, sticky="nsew")

        scroll = ttk.Scrollbar(self, orient="vertical", command=self._tree.yview)
        self._tree.configure(yscrollcommand=scroll.set)
        scroll.grid(row=1, column=1, sticky="ns")

        self._status_var = tk.StringVar(value="")
        self._status_label = ttk.Label(
            self, textvariable=self._status_var, style="Muted.TLabel", foreground=theme.ERROR
        )
        self._status_label.grid(row=2, column=0, columnspan=2, sticky="w", pady=(8, 0))

        self.after(10, self.refresh)
        # Flujo directo portería: al entrar desde el sidebar, la cámara
        # facial se abre sola (sin paso intermedio en "Reconocimiento facial").
        self.after(80, self._abrir_reconocimiento)

    def refresh(self) -> None:
        self._tree.delete(*self._tree.get_children())
        self._status_var.set("")
        try:
            items = self._client.ingresos_hoy()
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._status_var.set(str(exc))
            return

        for it in items:
            nombre = f"{it.get('nombres', '')} {it.get('apellidos', '')}".strip()
            hora = format_db_timestamp(it.get("fec_ingreso"), WITH_SECONDS_FORMAT)
            self._tree.insert(
                "",
                "end",
                values=(
                    hora,
                    nombre or "—",
                    it.get("nom_tipo_persona", ""),
                    it.get("id_ficha") or "—",
                    it.get("nom_programa") or "—",
                    it.get("nom_entrada", ""),
                ),
            )

    def _abrir_dialogo(self) -> None:
        NuevoIngresoDialog(self, self._client, on_registrado=self.refresh)

    def _abrir_reconocimiento(self) -> None:
        modal = getattr(self, "_facial_modal", None)
        if modal is not None and modal.winfo_exists():
            modal.lift()
            modal.focus_force()
            return
        self._facial_modal = FacialRecognitionModal(
            self, self._client, modo="ingreso", on_registrado=self.refresh
        )


class NuevoIngresoDialog(tk.Toplevel):
    """Diálogo modal: documento → consultar persona → elegir puerta → registrar."""

    def __init__(
        self, master: tk.Misc, client: SmartcsetClient, on_registrado: Callable[[], None]
    ) -> None:
        super().__init__(master)
        self.title("Nuevo ingreso")
        self.configure(bg=theme.BG_CARD)
        self.geometry("420x520")
        self.transient(master)
        self.grab_set()

        self._client = client
        self._on_registrado = on_registrado
        self._persona: dict[str, Any] | None = None
        self._puede_ingresar = False

        try:
            self._catalogos = client.catalogos()
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            messagebox.showerror("Nuevo ingreso", str(exc))
            self.destroy()
            return

        self._build()

    def _build(self) -> None:
        pad = dict(padx=16, pady=(10, 0))

        ttk.Label(self, text="Tipo de documento", style="Card.TLabel").pack(
            anchor="w", **pad
        )
        tipos_doc = self._catalogos.get("tipos_doc", [])
        self._tipo_doc_var = tk.StringVar(value=(tipos_doc[0]["id"] if tipos_doc else "CC"))
        self._tipo_doc_map = {t["nombre"]: t["id"] for t in tipos_doc}
        tipo_doc_combo = ttk.Combobox(
            self, values=list(self._tipo_doc_map.keys()), state="readonly"
        )
        if tipos_doc:
            tipo_doc_combo.current(0)
        tipo_doc_combo.pack(fill="x", padx=16)
        self._tipo_doc_combo = tipo_doc_combo

        ttk.Label(self, text="Número de documento", style="Card.TLabel").pack(anchor="w", **pad)
        self._documento_var = tk.StringVar()
        doc_entry = ttk.Entry(self, textvariable=self._documento_var)
        doc_entry.pack(fill="x", padx=16)
        doc_entry.bind("<Return>", lambda _e: self._consultar())
        doc_entry.focus_set()

        ttk.Button(
            self, text="Buscar persona", style="Nav.TButton", command=self._consultar
        ).pack(fill="x", padx=16, pady=(8, 0))

        self._resultado_frame = ttk.Frame(self, style="App.TFrame", padding=(16, 12))
        self._resultado_frame.pack(fill="both", expand=True)

        self._submit_btn = ttk.Button(
            self,
            text="Registrar ingreso",
            style="Primary.TButton",
            command=self._registrar,
            state="disabled",
        )
        self._submit_btn.pack(fill="x", padx=16, pady=(0, 16))

    def _consultar(self) -> None:
        documento = self._documento_var.get().strip()
        if not documento:
            messagebox.showwarning("Nuevo ingreso", "Ingrese un número de documento.")
            return

        tipo_doc = self._tipo_doc_map.get(
            self._tipo_doc_combo.get(), self._tipo_doc_var.get()
        )

        try:
            resultado = self._client.ingreso_consultar(documento, tipo_doc)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            messagebox.showerror("Nuevo ingreso", str(exc))
            return

        self._persona = resultado.get("persona")
        self._puede_ingresar = bool(resultado.get("puede_ingresar"))
        self._tipo_doc_actual = tipo_doc
        self._documento_actual = documento
        self._render_resultado(resultado)

    def _render_resultado(self, resultado: dict[str, Any]) -> None:
        for child in self._resultado_frame.winfo_children():
            child.destroy()
        self._tipo_persona_combo = None
        self._tipo_persona_map = {}
        self._tipo_persona_existente = 0

        persona = resultado.get("persona")
        ingreso_abierto = resultado.get("ingreso_abierto")

        if ingreso_abierto is not None:
            ttk.Label(
                self._resultado_frame,
                text="Esta persona ya tiene un ingreso abierto — no se puede "
                "registrar otro ingreso hasta que registre salida.",
                style="App.TLabel",
                foreground=theme.ERROR,
                wraplength=360,
                justify="left",
            ).pack(anchor="w")
            self._submit_btn.state(["disabled"])
            return

        if persona is None:
            ttk.Label(
                self._resultado_frame,
                text="Persona no registrada — se creará al confirmar el ingreso.",
                style="App.TLabel",
                foreground=theme.CYAN,
            ).pack(anchor="w", pady=(0, 8))

            ttk.Label(self._resultado_frame, text="Nombres", style="App.TLabel").pack(anchor="w")
            self._nombres_var = tk.StringVar()
            ttk.Entry(self._resultado_frame, textvariable=self._nombres_var).pack(fill="x")

            ttk.Label(self._resultado_frame, text="Apellidos", style="App.TLabel").pack(
                anchor="w", pady=(6, 0)
            )
            self._apellidos_var = tk.StringVar()
            ttk.Entry(self._resultado_frame, textvariable=self._apellidos_var).pack(fill="x")

            ttk.Label(self._resultado_frame, text="Tipo de persona", style="App.TLabel").pack(
                anchor="w", pady=(6, 0)
            )
            tipos_persona = self._catalogos.get("tipos_persona", [])
            self._tipo_persona_map = {t["nombre"]: t["id"] for t in tipos_persona}
            self._tipo_persona_combo = ttk.Combobox(
                self._resultado_frame,
                values=list(self._tipo_persona_map.keys()),
                state="readonly",
            )
            if tipos_persona:
                self._tipo_persona_combo.current(0)
            self._tipo_persona_combo.pack(fill="x")
        else:
            nombre = f"{persona.get('nombres', '')} {persona.get('apellidos', '')}".strip()
            ttk.Label(
                self._resultado_frame, text=nombre, style="App.TLabel", font=theme.FONT_BODY_BOLD
            ).pack(anchor="w")
            ttk.Label(
                self._resultado_frame,
                text=persona.get("nom_tipo_persona", ""),
                style="Muted.TLabel",
            ).pack(anchor="w")
            self._nombres_var = tk.StringVar(value=persona.get("nombres", ""))
            self._apellidos_var = tk.StringVar(value=persona.get("apellidos", ""))
            self._tipo_persona_existente = int(persona.get("tipo_persona") or 0)

        ttk.Label(self._resultado_frame, text="Puerta de ingreso", style="App.TLabel").pack(
            anchor="w", pady=(10, 0)
        )
        entradas = self._catalogos.get("entradas", [])
        self._entrada_map = {e["nombre"]: e["id"] for e in entradas}
        self._entrada_combo = ttk.Combobox(
            self._resultado_frame, values=list(self._entrada_map.keys()), state="readonly"
        )
        if entradas:
            self._entrada_combo.current(0)
        self._entrada_combo.pack(fill="x")

        ttk.Label(self._resultado_frame, text="Observaciones (opcional)", style="App.TLabel").pack(
            anchor="w", pady=(8, 0)
        )
        self._obs_var = tk.StringVar()
        ttk.Entry(self._resultado_frame, textvariable=self._obs_var).pack(fill="x")

        self._submit_btn.state(["!disabled"])

    def _registrar(self) -> None:
        if self._tipo_persona_combo is not None:
            tipo_persona = self._tipo_persona_map.get(self._tipo_persona_combo.get(), 0)
        else:
            tipo_persona = self._tipo_persona_existente

        payload = {
            "tipo_doc": self._tipo_doc_actual,
            "documento": self._documento_actual,
            "nombres": self._nombres_var.get().strip(),
            "apellidos": self._apellidos_var.get().strip(),
            "tipo_persona": tipo_persona,
            "id_entrada": self._entrada_map.get(self._entrada_combo.get(), 0),
            "observaciones": self._obs_var.get().strip(),
            "metodo_aut": 1,
        }

        self._submit_btn.state(["disabled"])
        try:
            self._client.ingreso_registrar(payload)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            messagebox.showerror("Nuevo ingreso", str(exc))
            self._submit_btn.state(["!disabled"])
            return

        messagebox.showinfo("Nuevo ingreso", "Ingreso registrado correctamente.")
        self._on_registrado()
        self.destroy()
