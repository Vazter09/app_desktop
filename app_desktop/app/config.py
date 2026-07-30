"""
Configuración local de la app de escritorio SGI.

Persiste SOLO la URL base del servidor SmartCSET (app_config.json, no
versionado, se crea/edita una sola vez en la instalación de cada PC).
No hay campo de usuario/token — el login es siempre con usuario y
contraseña reales de SmartCSET, tecleados en cada sesión (ver login_view).

En ejecutable (PyInstaller) el default es el servidor institucional;
en desarrollo desde fuentes sigue siendo localhost.
"""
from __future__ import annotations

import json
import os
from dataclasses import dataclass
from urllib.parse import urlparse

from app_paths import is_frozen, writable_root

# Servidor institucional SENA (PC de portería / .exe empaquetado).
PRODUCTION_BASE_URL = "https://10.5.213.103/smartcset"
# Desarrollo local vía Apache.
DEV_BASE_URL = "https://localhost/smartcset"

_LOCAL_HOSTS = {"localhost", "127.0.0.1", "::1"}


def default_base_url() -> str:
    return PRODUCTION_BASE_URL if is_frozen() else DEV_BASE_URL


def config_path() -> str:
    return str(writable_root() / "app_config.json")


@dataclass
class AppConfig:
    base_url: str = DEV_BASE_URL
    # None = automático (False solo en localhost). False explícito = lab
    # con certificado autofirmado (ej. 10.5.213.111).
    verify_tls_override: bool | None = None

    @classmethod
    def load(cls) -> "AppConfig":
        path = config_path()
        default_url = default_base_url()
        if not os.path.isfile(path):
            cfg = cls(base_url=default_url)
            cfg.save()
            return cfg

        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)

        override = data.get("verify_tls", None)
        if override is not None:
            override = bool(override)

        return cls(
            base_url=str(data.get("base_url", default_url)),
            verify_tls_override=override,
        )

    def save(self) -> None:
        path = config_path()
        payload = {"base_url": self.base_url}
        if self.verify_tls_override is not None:
            payload["verify_tls"] = self.verify_tls_override
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(payload, fh, indent=2, ensure_ascii=False)

    @property
    def verify_tls(self) -> bool:
        """
        Verificación de certificado activa por defecto, salvo localhost
        de desarrollo o override explícito en app_config.json
        (`"verify_tls": false`) para laboratorio con cert autofirmado.
        """
        if self.verify_tls_override is not None:
            return self.verify_tls_override
        host = urlparse(self.base_url).hostname or ""
        return host not in _LOCAL_HOSTS
