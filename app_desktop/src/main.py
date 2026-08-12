"""
Punto de entrada — App de Escritorio SGI (SmartCSET).

Sin frameworks. La única dependencia de terceros (opencv-python-headless,
para cámara y motor biométrico) vive en `.venv/`, y `bootstrap.py` la
activa automáticamente — así `python3 main.py` funciona siempre, sin
tener que acordarse de activar nada a mano.

Ejecutar (desde cualquier Python del sistema, 3.11+):
    cd app_desktop/src
    python main.py
"""
from __future__ import annotations

import atexit
import signal
import sys
import traceback
import types

from bootstrap import ensure_venv

ensure_venv()  # re-ejecuta dentro de .venv/ antes de importar nada más

import tkinter as tk  # noqa: E402 (después de ensure_venv a propósito)
from tkinter import messagebox  # noqa: E402

from config import AppConfig  # noqa: E402
from app_log import (  # noqa: E402
    flush_handlers,
    get_logger,
    log_exception,
    setup_logging,
)
from smartcset_client import SmartcsetClient  # noqa: E402
from ui import theme  # noqa: E402
from ui.login_view import LoginView  # noqa: E402
from ui.shell import AppShell  # noqa: E402

# Ventana maximizada desde el arranque (login y portería).
APP_MIN_WIDTH = 1280
APP_MIN_HEIGHT = 860
log = get_logger("main")


def _install_global_exception_hooks() -> None:
    """Captura excepciones no manejadas (hilos principales y callbacks Tk)."""

    def _excepthook(
        exc_type: type[BaseException],
        exc: BaseException,
        tb: types.TracebackType | None,
    ) -> None:
        if issubclass(exc_type, KeyboardInterrupt):
            sys.__excepthook__(exc_type, exc, tb)
            return
        log.error(
            "Excepción no capturada: %s",
            exc,
            exc_info=(exc_type, exc, tb),
        )
        flush_handlers()

    sys.excepthook = _excepthook


class SmartcsetDesktopApp:
    def __init__(self) -> None:
        self.config = AppConfig.load()
        log.warning(
            "Arranque app | base_url=%s verify_tls=%s",
            self.config.base_url,
            self.config.verify_tls,
        )
        self.client = SmartcsetClient(
            self.config.base_url, verify_tls=self.config.verify_tls
        )

        self.root = tk.Tk()
        self.root.report_callback_exception = self._on_tk_callback_exception
        self.root.title("SmartCSET · App Escritorio SGI")
        self._aplicar_pantalla_completa()

        theme.apply_theme(self.root)

        self._current_view: tk.Widget | None = None
        self._logged_in = False
        self._logout_done = False
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)
        atexit.register(self._logout_if_needed)
        self._install_signal_handlers()
        self._show_login()

    def _on_tk_callback_exception(
        self,
        exc_type: type[BaseException],
        exc: BaseException,
        tb: types.TracebackType | None,
    ) -> None:
        """Errores dentro de mainloop (botones, after, bindings)."""
        log.error(
            "Error en callback Tkinter: %s",
            exc,
            exc_info=(exc_type, exc, tb),
        )
        flush_handlers()
        # También a stderr crudo por si el handler de logging falló.
        traceback.print_exception(exc_type, exc, tb, file=sys.stderr)

    def _aplicar_pantalla_completa(self) -> None:
        """Abre maximizada (barra de título visible; no fullscreen sin bordes)."""
        self.root.minsize(APP_MIN_WIDTH, APP_MIN_HEIGHT)
        try:
            # Windows / varios gestores: maximizada.
            self.root.state("zoomed")
        except tk.TclError:
            # Fallback: ocupar casi toda el área usable.
            self.root.update_idletasks()
            ancho = max(APP_MIN_WIDTH, self.root.winfo_screenwidth())
            alto = max(APP_MIN_HEIGHT, self.root.winfo_screenheight() - 40)
            self.root.geometry(f"{ancho}x{alto}+0+0")

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
        except Exception as exc:
            log.warning("Logout al cerrar falló: %s", exc)
            flush_handlers()
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
        self._aplicar_pantalla_completa()
        self._clear()
        view = LoginView(self.root, self.client, on_success=self._show_dashboard)
        view.pack(fill="both", expand=True)
        self._current_view = view

    def _show_dashboard(self, usuario: dict) -> None:
        self._logged_in = True
        self._logout_done = False
        self._aplicar_pantalla_completa()
        self._clear()
        view = AppShell(
            self.root, self.client, usuario, on_logout=self._show_login
        )
        view.pack(fill="both", expand=True)
        self._current_view = view

    def run(self) -> None:
        try:
            self.root.mainloop()
        finally:
            # Red de seguridad: si mainloop terminó sin WM_DELETE (crash
            # parcial / destroy externo), aún intentar liberar la sesión BD.
            self._logout_if_needed()


def main() -> int:
    path = setup_logging()
    _install_global_exception_hooks()
    # setup_logging ya emitió INFO con la ruta; refuerzo visible en consola.
    print(f"SmartCSET desktop — log: {path}", file=sys.stderr)
    app: SmartcsetDesktopApp | None = None
    try:
        app = SmartcsetDesktopApp()
        app.run()
    except Exception as exc:  # pragma: no cover - fallo visible al operador
        log_exception(log, "Error fatal de la aplicación", exc)
        if app is not None:
            try:
                app._logout_if_needed()
            except Exception:
                pass
        try:
            messagebox.showerror("SmartCSET — Error", str(exc))
        except tk.TclError:
            print(f"Error fatal: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
