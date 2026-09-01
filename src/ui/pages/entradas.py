"""
Página "Entradas" — listado real de puertas del centro (vía
/routers/porteria/v1/catalogos.php, ahora accesible con sesión real —
antes solo aceptaba token de dispositivo, ver ajuste en
backend/routers/porteria/v1/catalogos.php).

Crear/eliminar reutiliza los endpoints reales
(/routers/entradas/v1/{guardar,eliminar}.php), que en el servidor exigen
`require_admin` — igual que en la web: un usuario no-admin (como
`porteria`) puede VER las entradas pero el servidor rechaza
crear/eliminar con un mensaje real de error, no una restricción
inventada en el cliente.
"""
from __future__ import annotations

import tkinter as tk
from tkinter import messagebox, simpledialog, ttk
from typing import Any, Callable

from app_log import flush_handlers, get_logger
from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError

log = get_logger("ui.pages.entradas")


class EntradasPage(ttk.Frame):
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
        ttk.Label(head, text="🚪 Entradas del centro", style="Title.TLabel").grid(
            row=0, column=0, sticky="w"
        )
        ttk.Button(
            head, text="+ Nueva entrada", style="Primary.TButton", command=self._nueva
        ).grid(row=0, column=1, sticky="e", padx=(0, 6))
        ttk.Button(
            head, text="Eliminar seleccionada", style="Nav.TButton", command=self._eliminar
        ).grid(row=0, column=2, sticky="e")

        columns = ("id", "nombre", "centro", "sede")
        self._tree = ttk.Treeview(self, columns=columns, show="headings", height=16)
        for col, label, width in (
            ("id", "#", 40),
            ("nombre", "Nombre", 260),
            ("centro", "Centro", 100),
            ("sede", "Sede", 80),
        ):
            self._tree.heading(col, text=label)
            self._tree.column(col, width=width, anchor="w")
        self._tree.grid(row=1, column=0, sticky="nsew")

        scroll = ttk.Scrollbar(self, orient="vertical", command=self._tree.yview)
        self._tree.configure(yscrollcommand=scroll.set)
        scroll.grid(row=1, column=1, sticky="ns")

        self.after(10, self.refresh)

    def refresh(self) -> None:
        self._tree.delete(*self._tree.get_children())
        try:
            data = self._client.catalogos()
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            log.error("Listar entradas: %s", exc)
            flush_handlers()
            messagebox.showerror("Entradas", str(exc))
            return

        for e in data.get("entradas", []):
            self._tree.insert(
                "", "end", iid=str(e["id"]),
                values=(e["id"], e["nombre"], e.get("id_centro", ""), e.get("id_sede", "")),
            )

    def _nueva(self) -> None:
        nombre = simpledialog.askstring("Nueva entrada", "Nombre de la entrada:", parent=self)
        if not nombre:
            return
        sede = simpledialog.askstring(
            "Nueva entrada",
            "Sede (formato centro|sede, ej. 9309|1):",
            parent=self,
        )
        if not sede:
            return

        try:
            self._client.entrada_guardar({"nombre": nombre, "sel_sede": sede})
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            log.error("Guardar entrada: %s", exc)
            flush_handlers()
            messagebox.showerror("Nueva entrada", str(exc))
            return

        messagebox.showinfo("Nueva entrada", "Entrada guardada correctamente.")
        self.refresh()

    def _eliminar(self) -> None:
        selection = self._tree.selection()
        if not selection:
            messagebox.showwarning("Eliminar entrada", "Seleccione una entrada de la tabla.")
            return

        id_entrada = int(selection[0])
        if not messagebox.askyesno(
            "Eliminar entrada", f"¿Eliminar la entrada #{id_entrada}? Esta acción no se puede deshacer."
        ):
            return

        try:
            self._client.entrada_eliminar(id_entrada)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            log.error("Eliminar entrada: %s", exc)
            flush_handlers()
            messagebox.showerror("Eliminar entrada", str(exc))
            return

        messagebox.showinfo("Eliminar entrada", "Entrada eliminada correctamente.")
        self.refresh()
