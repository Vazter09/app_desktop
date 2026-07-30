"""
Logging de la app de escritorio SmartCSET.

Archivo de log (una sola ruta canónica):
  - Desarrollo:  app_desktop/app/logs/smartcset_desktop.log
  - Ejecutable:  <carpeta_del_exe>/logs/smartcset_desktop.log

Uso:
    from app_log import get_logger, log_path, setup_logging
    setup_logging()
    log = get_logger(__name__)
    log.info("mensaje")
    log.exception("fallo")
"""
from __future__ import annotations

import logging
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path

from app_paths import writable_root

_LOG_NAME = "smartcset_desktop"
_LOG_FILE = "smartcset_desktop.log"
_MAX_BYTES = 2 * 1024 * 1024  # 2 MiB
_BACKUP_COUNT = 5
_configured = False


def logs_dir() -> Path:
    """Carpeta de logs (se crea si no existe)."""
    path = writable_root() / "logs"
    path.mkdir(parents=True, exist_ok=True)
    return path


def log_path() -> Path:
    """Ruta absoluta del archivo de log activo."""
    return logs_dir() / _LOG_FILE


def setup_logging(level: int = logging.INFO) -> Path:
    """Inicializa logging a archivo + consola (stderr). Idempotente."""
    global _configured
    path = log_path()
    if _configured:
        return path

    root = logging.getLogger(_LOG_NAME)
    root.setLevel(level)
    root.handlers.clear()

    fmt = logging.Formatter(
        fmt="%(asctime)s | %(levelname)-7s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    file_handler = RotatingFileHandler(
        path,
        maxBytes=_MAX_BYTES,
        backupCount=_BACKUP_COUNT,
        encoding="utf-8",
    )
    file_handler.setFormatter(fmt)
    file_handler.setLevel(level)
    root.addHandler(file_handler)

    # Consola solo si no es ejecutable windowed (o si hay stderr real).
    if not getattr(sys, "frozen", False) or sys.stderr is not None:
        try:
            stream_handler = logging.StreamHandler(sys.stderr)
            stream_handler.setFormatter(fmt)
            stream_handler.setLevel(level)
            root.addHandler(stream_handler)
        except Exception:
            pass

    root.info("Logging iniciado → %s", path)
    _configured = True
    return path


def get_logger(name: str | None = None) -> logging.Logger:
    """Logger hijo bajo smartcset_desktop (asegura setup)."""
    if not _configured:
        setup_logging()
    if name:
        return logging.getLogger(f"{_LOG_NAME}.{name}")
    return logging.getLogger(_LOG_NAME)
