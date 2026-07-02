"""
Configuración local del PC de portería (URL del servidor SmartCSET + token de
dispositivo). Se guarda fuera del repo (.device_config.json, en .gitignore) —
mismo criterio que .env: nunca credenciales en el código fuente.
"""
import json
from pathlib import Path

CONFIG_PATH = Path(__file__).parent / ".device_config.json"


def cargar_config():
    if not CONFIG_PATH.exists():
        return None
    try:
        data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
        if data.get("base_url") and data.get("device_token"):
            return data
    except (json.JSONDecodeError, OSError):
        pass
    return None


def guardar_config(base_url, device_token, nom_dispositivo=""):
    data = {
        "base_url": base_url.rstrip("/"),
        "device_token": device_token,
        "nom_dispositivo": nom_dispositivo,
    }
    CONFIG_PATH.write_text(json.dumps(data, indent=2), encoding="utf-8")


def borrar_config():
    if CONFIG_PATH.exists():
        CONFIG_PATH.unlink()
