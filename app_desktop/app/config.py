"""
Configuración local de la app de escritorio SGI.

Persiste SOLO la URL base del servidor SmartCSET (app_config.json, no
versionado, se crea/edita una sola vez en la instalación de cada PC).
No hay campo de usuario/token — el login es siempre con usuario y
contraseña reales de SmartCSET, tecleados en cada sesión (ver login_view).

Sigue la regla del proyecto: nada de configuración hardcodeada en el
código fuente, todo en un archivo de configuración explícito.
"""
from __future__ import annotations

import json
import os
from dataclasses import dataclass
from urllib.parse import urlparse

CONFIG_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(CONFIG_DIR, "app_config.json")

# Fase actual (dev/laboratorio): código PHP corriendo LOCAL vía Apache
# (https://localhost/smartcset), BD remota en el servidor de laboratorio
# (192.168.1.71) — ver acuerdo de esta sesión. En despliegue institucional
# real este valor cambia al host real (ver HANDOFF.md) y deja de ser
# "localhost", por lo que el certificado autofirmado ya no aplica
# (verify_tls se activa solo automáticamente).
DEFAULT_BASE_URL = "https://localhost/smartcset"

_LOCAL_HOSTS = {"localhost", "127.0.0.1", "::1"}


@dataclass
class AppConfig:
    base_url: str = DEFAULT_BASE_URL
    # None = automático (False solo en localhost). False explícito = lab
    # con certificado autofirmado (ej. 10.5.213.111).
    verify_tls_override: bool | None = None

    @classmethod
    def load(cls) -> "AppConfig":
        if not os.path.isfile(CONFIG_PATH):
            cfg = cls()
            cfg.save()
            return cfg

        with open(CONFIG_PATH, "r", encoding="utf-8") as fh:
            data = json.load(fh)

        override = data.get("verify_tls", None)
        if override is not None:
            override = bool(override)

        return cls(
            base_url=str(data.get("base_url", DEFAULT_BASE_URL)),
            verify_tls_override=override,
        )

    def save(self) -> None:
        payload = {"base_url": self.base_url}
        if self.verify_tls_override is not None:
            payload["verify_tls"] = self.verify_tls_override
        with open(CONFIG_PATH, "w", encoding="utf-8") as fh:
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
