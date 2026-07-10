"""
Página "Registro de salida" — réplica funcional de
frontend/web/pages/modulos/porteria/salida/index.php: tabla de
"Salidas de hoy" + diálogo "Nueva salida" (documento → confirmar
ingreso abierto → registrar salida), método manual (`metodo_aut=1`).
"""
from __future__ import annotations

import tkinter as tk
from tkinter import messagebox, ttk
from typing import Any, Callable

from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError
from ui import theme
from ui.facial_modal import FacialRecognitionModal
from ui.format_utils import WITH_SECONDS_FORMAT, format_db_timestamp


class SalidaPage(ttk.Frame):
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
        ttk.Label(head, text="⏱ Salidas de hoy", style="Title.TLabel").grid(row=0, column=0, sticky="w")
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
            head, text="+ Nueva salida", style="Primary.TButton", command=self._abrir_dialogo
        ).grid(row=0, column=3, sticky="e")

        columns = ("h_ing", "h_sal", "persona", "tipo", "entrada")
        self._tree = ttk.Treeview(self, columns=columns, show="headings", height=16)
        for col, label, width in (
            ("h_ing", "Hora/Fecha ingreso", 165),
            ("h_sal", "Hora/Fecha salida", 165),
            ("persona", "Persona", 220),
            ("tipo", "Tipo", 100),
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
        self.after(80, self._abrir_reconocimiento)

    def refresh(self) -> None:
        self._tree.delete(*self._tree.get_children())
        self._status_var.set("")
        try:
            items = self._client.salidas_hoy()
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._status_var.set(str(exc))
            return

        for it in items:
            nombre = f"{it.get('nombres', '')} {it.get('apellidos', '')}".strip()
            h_ing = format_db_timestamp(it.get("fec_ingreso"), WITH_SECONDS_FORMAT)
            h_sal = format_db_timestamp(it.get("fec_salida"), WITH_SECONDS_FORMAT)
            self._tree.insert(
                "",
                "end",
                values=(
                    h_ing,
                    h_sal,
                    nombre or "—",
                    it.get("nom_tipo_persona", ""),
                    it.get("nom_entrada", ""),
                ),
            )

    def _abrir_dialogo(self) -> None:
        NuevaSalidaDialog(self, self._client, on_registrado=self.refresh)

    def _abrir_reconocimiento(self) -> None:
        modal = getattr(self, "_facial_modal", None)
        if modal is not None and modal.winfo_exists():
            modal.lift()
            modal.focus_force()
            return
        self._facial_modal = FacialRecognitionModal(
            self, self._client, modo="salida", on_registrado=self.refresh
        )


class NuevaSalidaDialog(tk.Toplevel):
    def __init__(
        self, master: tk.Misc, client: SmartcsetClient, on_registrado: Callable[[], None]
    ) -> None:
        super().__init__(master)
        self.title("Nueva salida")
        self.configure(bg=theme.BG_CARD)
        self.geometry("380x380")
        self.transient(master)
        self.grab_set()

        self._client = client
        self._on_registrado = on_registrado

        try:
            self._catalogos = client.catalogos()
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            messagebox.showerror("Nueva salida", str(exc))
            self.destroy()
            return

        self._build()

    def _build(self) -> None:
        pad = dict(padx=16, pady=(10, 0))

        ttk.Label(self, text="Tipo de documento", style="Card.TLabel").pack(anchor="w", **pad)
        tipos_doc = self._catalogos.get("tipos_doc", [])
        self._tipo_doc_map = {t["nombre"]: t["id"] for t in tipos_doc}
        self._tipo_doc_combo = ttk.Combobox(
            self, values=list(self._tipo_doc_map.keys()), state="readonly"
        )
        if tipos_doc:
            self._tipo_doc_combo.current(0)
        self._tipo_doc_combo.pack(fill="x", padx=16)

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
            text="Registrar salida",
            style="Primary.TButton",
            command=self._registrar,
            state="disabled",
        )
        self._submit_btn.pack(fill="x", padx=16, pady=(0, 16))

    def _consultar(self) -> None:
        documento = self._documento_var.get().strip()
        if not documento:
            messagebox.showwarning("Nueva salida", "Ingrese un número de documento.")
            return

        tipo_doc = self._tipo_doc_map.get(self._tipo_doc_combo.get(), "CC")

        try:
            resultado = self._client.salida_consultar(documento, tipo_doc)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            messagebox.showerror("Nueva salida", str(exc))
            return

        self._tipo_doc_actual = tipo_doc
        self._documento_actual = documento
        self._render_resultado(resultado)

    def _render_resultado(self, resultado: dict[str, Any]) -> None:
        for child in self._resultado_frame.winfo_children():
            child.destroy()

        persona = resultado.get("persona")
        ingreso_abierto = resultado.get("ingreso_abierto")
        puede_salir = bool(resultado.get("puede_salir"))

        if persona is None or ingreso_abierto is None or not puede_salir:
            ttk.Label(
                self._resultado_frame,
                text="Esta persona no tiene un ingreso abierto — no se puede "
                "registrar salida.",
                style="App.TLabel",
                foreground=theme.ERROR,
                wraplength=330,
                justify="left",
            ).pack(anchor="w")
            self._submit_btn.state(["disabled"])
            return

        nombre = f"{persona.get('nombres', '')} {persona.get('apellidos', '')}".strip()
        ttk.Label(
            self._resultado_frame, text=nombre, style="App.TLabel", font=theme.FONT_BODY_BOLD
        ).pack(anchor="w")
        ttk.Label(
            self._resultado_frame, text=persona.get("nom_tipo_persona", ""), style="Muted.TLabel"
        ).pack(anchor="w")

        ttk.Label(
            self._resultado_frame,
            text=f"Ingresó por {ingreso_abierto.get('nom_entrada', '')} a las "
            f"{str(ingreso_abierto.get('fec_ingreso', ''))[-8:]}",
            style="CardMuted.TLabel",
        ).pack(anchor="w", pady=(6, 10))

        ttk.Label(self._resultado_frame, text="Observaciones (opcional)", style="App.TLabel").pack(
            anchor="w"
        )
        self._obs_var = tk.StringVar()
        ttk.Entry(self._resultado_frame, textvariable=self._obs_var).pack(fill="x")

        self._submit_btn.state(["!disabled"])

    def _registrar(self) -> None:
        payload = {
            "tipo_doc": self._tipo_doc_actual,
            "documento": self._documento_actual,
            "observaciones": self._obs_var.get().strip(),
            "metodo_aut": 1,
        }

        self._submit_btn.state(["disabled"])
        try:
            self._client.salida_registrar(payload)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            messagebox.showerror("Nueva salida", str(exc))
            self._submit_btn.state(["!disabled"])
            return

        messagebox.showinfo("Nueva salida", "Salida registrada correctamente.")
        self._on_registrado()
        self.destroy()
