"""
Configuración para el Motor Biométrico en modo Desktop.
Usado por motor_biometrico_desktop.py (launcher del motor en Windows).
"""

import os
from pathlib import Path

BASE_DIR = Path(__file__).parent


class ConfigDesktop:
    HOST = os.getenv("BIOMETRIA_HOST", "0.0.0.0")
    PORT = int(os.getenv("BIOMETRIA_PORT", "5000"))
    API_KEY = os.getenv("BIOMETRIA_API_KEY", "cambiar-api-key-segura")

    TEMP_DIR = os.getenv("BIOMETRIA_TEMP_DIR", str(BASE_DIR / "temp"))
    LOG_DIR = os.getenv("BIOMETRIA_LOG_DIR", str(BASE_DIR / "logs"))

    MODEL_NAME = os.getenv("BIOMETRIA_MODEL", "Facenet512")
    CALIDAD_MINIMA = float(os.getenv("BIOMETRIA_CALIDAD_MINIMA", "50.0"))
    LOG_LEVEL = os.getenv("BIOMETRIA_LOG_LEVEL", "INFO")
    DEBUG = os.getenv("BIOMETRIA_DEBUG", "false").lower() == "true"

    @classmethod
    def create_directories(cls):
        for dir_path in (cls.TEMP_DIR, cls.LOG_DIR):
            Path(dir_path).mkdir(parents=True, exist_ok=True)


def get_config(mode=None):
    return ConfigDesktop
