"""
Vista de login — réplica funcional del login real de SmartCSET
(frontend/web/public/index.php): usuario + contraseña, sin campo de
URL de servidor (viene preconfigurada en config.py / app_config.json).

Usuario prellenado con "porteria" (el mismo usuario real que ya opera
portería web), pero cualquier usuario registrado con permiso puede
iniciar sesión aquí.
"""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk
from typing import Callable

from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError
from ui import theme


class LoginView(ttk.Frame):
    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        on_success: Callable[[dict], None],
    ) -> None:
        super().__init__(master, style="App.TFrame")
        self._client = client
        self._on_success = on_success

        self.columnconfigure(0, weight=1)
        self.rowconfigure(0, weight=1)

        card = ttk.Frame(self, style="Card.TFrame", padding=30)
        card.grid(row=0, column=0)

        ttk.Label(card, text="SMARTCSET", style="Title.TLabel").grid(
            row=0, column=0, columnspan=2, sticky="w"
        )
        ttk.Label(
            card, text="Control de Acceso · App de Escritorio SGI", style="CardMuted.TLabel"
        ).grid(row=1, column=0, columnspan=2, sticky="w", pady=(0, 18))

        ttk.Label(card, text="Identificación", style="CardMuted.TLabel").grid(
            row=2, column=0, columnspan=2, sticky="w"
        )
        self._usuario_var = tk.StringVar(value="porteria")
        usuario_entry = ttk.Entry(card, textvariable=self._usuario_var, width=32)
        usuario_entry.grid(row=3, column=0, columnspan=2, sticky="ew", pady=(2, 12))

        ttk.Label(card, text="Contraseña", style="CardMuted.TLabel").grid(
            row=4, column=0, columnspan=2, sticky="w"
        )
        self._clave_var = tk.StringVar()
        clave_entry = ttk.Entry(
            card, textvariable=self._clave_var, show="•", width=32
        )
        clave_entry.grid(row=5, column=0, columnspan=2, sticky="ew", pady=(2, 6))
        clave_entry.bind("<Return>", lambda _e: self._do_login())

        self._error_var = tk.StringVar(value="")
        self._error_label = ttk.Label(
            card, textvariable=self._error_var, style="CardMuted.TLabel", foreground=theme.ERROR
        )
        self._error_label.grid(row=6, column=0, columnspan=2, sticky="w", pady=(0, 6))

        self._submit_btn = ttk.Button(
            card, text="INGRESAR AL SISTEMA", style="Primary.TButton", command=self._do_login
        )
        self._submit_btn.grid(row=7, column=0, columnspan=2, sticky="ew", pady=(8, 0))

        ttk.Label(
            card,
            text=f"Servidor: {client.base_url}",
            style="CardMuted.TLabel",
            font=theme.FONT_LABEL_SMALL,
        ).grid(row=8, column=0, columnspan=2, sticky="w", pady=(14, 0))

        usuario_entry.focus_set()

    def _do_login(self) -> None:
        usuario = self._usuario_var.get().strip()
        clave = self._clave_var.get()

        if not usuario or not clave:
            self._error_var.set("ID de usuario y contraseña son obligatorios.")
            return

        self._submit_btn.state(["disabled"])
        self._error_var.set("")
        self.update_idletasks()

        try:
            data = self._client.login(usuario, clave)
        except SmartcsetApiError as exc:
            self._error_var.set(str(exc))
        except SmartcsetConnectionError as exc:
            self._error_var.set(str(exc))
        else:
            self._on_success(data.get("usuario", {}))
        finally:
            self._submit_btn.state(["!disabled"])
