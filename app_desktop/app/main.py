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

import atexit
import signal
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

# Login compacto (como antes del layout biométrico). Tras autenticar se
# amplía para las 3 columnas de portería.
LOGIN_WIDTH = 1024
LOGIN_HEIGHT = 680
APP_WIDTH = 1280
APP_HEIGHT = 860


class SmartcsetDesktopApp:
    def __init__(self) -> None:
        self.config = AppConfig.load()
        self.client = SmartcsetClient(
            self.config.base_url, verify_tls=self.config.verify_tls
        )

        self.root = tk.Tk()
        self.root.title("SmartCSET · App Escritorio SGI")
        self._apply_login_geometry()

        theme.apply_theme(self.root)

        self._current_view: tk.Widget | None = None
        self._logged_in = False
        self._logout_done = False
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)
        atexit.register(self._logout_if_needed)
        self._install_signal_handlers()
        self._show_login()

    def _apply_login_geometry(self) -> None:
        self.root.geometry(f"{LOGIN_WIDTH}x{LOGIN_HEIGHT}")
        self.root.minsize(LOGIN_WIDTH, LOGIN_HEIGHT)

    def _apply_app_geometry(self) -> None:
        self.root.geometry(f"{APP_WIDTH}x{APP_HEIGHT}")
        self.root.minsize(APP_WIDTH, APP_HEIGHT)

    def _install_signal_handlers(self) -> None:
        # Ctrl+C / cierre del proceso: liberar sesión BD (WM_DELETE no corre).
        def _handle(_signum, _frame) -> None:
            self._logout_if_needed()
            raise SystemExit(0)

        for sig in (getattr(signal, "SIGINT", None), getattr(signal, "SIGTERM", None)):
            if sig is None:
                continue
            try:
                signal.signal(sig, _handle)
            except (ValueError, OSError):
                pass

    def _logout_if_needed(self) -> None:
        if self._logout_done or not self._logged_in:
            return
        self._logout_done = True
        try:
            self.client.logout()
        except Exception:
            pass
        self._logged_in = False

    def _on_close(self) -> None:
        self._logout_if_needed()
        self.root.destroy()

    def _clear(self) -> None:
        if self._current_view is not None:
            self._current_view.destroy()
            self._current_view = None

    def _show_login(self) -> None:
        self._logged_in = False
        self._logout_done = False
        self._apply_login_geometry()
        self._clear()
        view = LoginView(self.root, self.client, on_success=self._show_dashboard)
        view.pack(fill="both", expand=True)
        self._current_view = view

    def _show_dashboard(self, usuario: dict) -> None:
        self._logged_in = True
        self._logout_done = False
        self._apply_app_geometry()
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
