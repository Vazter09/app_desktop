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
from pathlib import Path
from tkinter import ttk
from typing import Callable

from PIL import Image, ImageTk

from app_paths import resource_root
from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError
from ui import theme

LOGO_MAX_ANCHO = 110
CARD_PADDING = 28
ENTRY_WIDTH = 28
CARD_WIDTH = 380


def _ruta_logo_sena() -> Path | None:
    app_dir = resource_root()
    candidatos = (
        app_dir / "assets" / "img" / "logo-sena.png",
        Path(__file__).resolve().parents[1] / "assets" / "img" / "logo-sena.png",
        app_dir.parent.parent
        / "frontend"
        / "web"
        / "public"
        / "assets"
        / "img"
        / "logo-sena.png",
    )
    for ruta in candidatos:
        if ruta.is_file():
            return ruta
    return None


def _cargar_logo_sena() -> ImageTk.PhotoImage | None:
    ruta = _ruta_logo_sena()
    if ruta is None:
        return None
    imagen = Image.open(ruta)
    ancho, alto = imagen.size
    if ancho > LOGO_MAX_ANCHO:
        nuevo_alto = int(alto * LOGO_MAX_ANCHO / ancho)
        imagen = imagen.resize((LOGO_MAX_ANCHO, nuevo_alto), Image.Resampling.LANCZOS)
    return ImageTk.PhotoImage(imagen)


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
        self._logo_photo: ImageTk.PhotoImage | None = None

        self.columnconfigure(0, weight=1)
        self.rowconfigure(0, weight=1)

        # Card centrada (~login web 380px). Sin sticky=ew en la card para
        # que no se estire si la ventana es más ancha.
        card = ttk.Frame(self, style="Card.TFrame", padding=CARD_PADDING)
        card.grid(row=0, column=0)
        card.columnconfigure(0, minsize=CARD_WIDTH - (CARD_PADDING * 2))

        fila = 0
        self._logo_photo = _cargar_logo_sena()
        if self._logo_photo is not None:
            marco_logo = tk.Frame(card, bg=theme.BG_CARD, width=CARD_WIDTH - (CARD_PADDING * 2))
            marco_logo.grid(row=fila, column=0, sticky="ew", pady=(0, 16))
            tk.Label(
                marco_logo,
                image=self._logo_photo,
                bg=theme.BG_CARD,
            ).pack()
            fila += 1

        ttk.Label(
            card,
            text="SMARTCSET",
            style="LoginTitle.TLabel",
            anchor="center",
        ).grid(row=fila, column=0, sticky="ew", pady=(0, 20))
        fila += 1

        ttk.Label(card, text="Identificación", style="LoginField.TLabel").grid(
            row=fila, column=0, sticky="w", pady=(0, 4)
        )
        fila += 1
        self._usuario_var = tk.StringVar(value="porteria")
        usuario_entry = ttk.Entry(
            card, textvariable=self._usuario_var, width=ENTRY_WIDTH, style="Login.TEntry"
        )
        usuario_entry.grid(row=fila, column=0, sticky="ew", pady=(0, 14))
        fila += 1

        ttk.Label(card, text="Contraseña", style="LoginField.TLabel").grid(
            row=fila, column=0, sticky="w", pady=(0, 4)
        )
        fila += 1
        self._clave_var = tk.StringVar()
        clave_entry = ttk.Entry(
            card,
            textvariable=self._clave_var,
            show="•",
            width=ENTRY_WIDTH,
            style="Login.TEntry",
        )
        clave_entry.grid(row=fila, column=0, sticky="ew", pady=(0, 8))
        clave_entry.bind("<Return>", lambda _e: self._do_login())
        fila += 1

        self._error_var = tk.StringVar(value="")
        self._error_label = ttk.Label(
            card,
            textvariable=self._error_var,
            style="LoginError.TLabel",
            wraplength=CARD_WIDTH - (CARD_PADDING * 2),
        )
        self._error_label.grid(row=fila, column=0, sticky="ew", pady=(0, 8))
        fila += 1

        self._submit_btn = ttk.Button(
            card,
            text="INGRESAR AL SISTEMA",
            style="LoginPrimary.TButton",
            command=self._do_login,
        )
        self._submit_btn.grid(row=fila, column=0, sticky="ew", pady=(12, 0))

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

        # Descartar cookies locales previas (re-login en la misma ventana).
        self._client.logout()

        try:
            data = self._client.login(usuario, clave)
        except SmartcsetApiError as exc:
            mensaje = str(exc)
            if "sesión activa" in mensaje.lower():
                mensaje += (
                    " Si inició sesión en la web, cierre sesión allí primero "
                    "o pida al administrador que libere su usuario."
                )
            self._error_var.set(mensaje)
        except SmartcsetConnectionError as exc:
            self._error_var.set(str(exc))
        else:
            self._on_success(data.get("usuario", {}))
            return
        finally:
            if self.winfo_exists():
                self._submit_btn.state(["!disabled"])
