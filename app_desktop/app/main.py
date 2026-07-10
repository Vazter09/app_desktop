"""
Punto de entrada — App de Escritorio SGI (SmartCSET).

Sin frameworks. La única dependencia de terceros (opencv-python-headless,
para cámara y motor biométrico) vive en `.venv/`, y `bootstrap.py` la
activa automáticamente — así `python3 main.py` funciona siempre, sin
tener que acordarse de activar nada a mano.

Ejecutar (desde cualquier Python del sistema, 3.11+):
    cd app_desktop/app
    python3 main.py
"""
from __future__ import annotations

import sys

from bootstrap import ensure_venv

ensure_venv()  # re-ejecuta dentro de .venv/ antes de importar nada más

import tkinter as tk  # noqa: E402 (después de ensure_venv a propósito)
from tkinter import messagebox  # noqa: E402

from config import AppConfig  # noqa: E402
from smartcset_client import SmartcsetClient  # noqa: E402
from ui import theme  # noqa: E402
from ui.login_view import LoginView  # noqa: E402
from ui.shell import AppShell  # noqa: E402

MIN_WIDTH = 1024
MIN_HEIGHT = 680


class SmartcsetDesktopApp:
    def __init__(self) -> None:
        self.config = AppConfig.load()
        self.client = SmartcsetClient(
            self.config.base_url, verify_tls=self.config.verify_tls
        )

        self.root = tk.Tk()
        self.root.title("SmartCSET · App Escritorio SGI")
        self.root.geometry(f"{MIN_WIDTH}x{MIN_HEIGHT}")
        self.root.minsize(MIN_WIDTH, MIN_HEIGHT)

        theme.apply_theme(self.root)

        self._current_view: tk.Widget | None = None
        self._logged_in = False
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)
        self._show_login()

    def _on_close(self) -> None:
        if self._logged_in:
            try:
                self.client.logout()
            except Exception:
                pass
        self.root.destroy()

    def _clear(self) -> None:
        if self._current_view is not None:
            self._current_view.destroy()
            self._current_view = None

    def _show_login(self) -> None:
        self._logged_in = False
        self._clear()
        view = LoginView(self.root, self.client, on_success=self._show_dashboard)
        view.pack(fill="both", expand=True)
        self._current_view = view

    def _show_dashboard(self, usuario: dict) -> None:
        self._logged_in = True
        self._clear()
        view = AppShell(
            self.root, self.client, usuario, on_logout=self._show_login
        )
        view.pack(fill="both", expand=True)
        self._current_view = view

    def run(self) -> None:
        self.root.mainloop()


def main() -> int:
    try:
        app = SmartcsetDesktopApp()
        app.run()
    except Exception as exc:  # pragma: no cover - fallo visible al operador
        try:
            messagebox.showerror("SmartCSET — Error", str(exc))
        except tk.TclError:
            print(f"Error fatal: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
