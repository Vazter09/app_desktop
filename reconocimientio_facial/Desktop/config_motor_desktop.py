"""
Configuración para el Motor Biométrico en modo Desktop
Este archivo contiene configuraciones específicas para la ejecución local del motor biométrico
"""

import os
import sys
from pathlib import Path

# =============================================================================
# CONFIGURACIÓN PRINCIPAL
# =============================================================================

class ConfigDesktop:
    """Configuración para modo desktop"""
    
    # Configuración del servidor
    HOST = os.getenv("BIOMETRIA_HOST", "0.0.0.0")
    PORT = int(os.getenv("BIOMETRIA_PORT", "5000"))
    API_KEY = os.getenv("BIOMETRIA_API_KEY", "cambiar-api-key-segura")
    
    # Configuración de directorios
    BASE_DIR = Path(__file__).parent
    TEMP_DIR = os.getenv("BIOMETRIA_TEMP_DIR", str(BASE_DIR / "temp"))
    LOG_DIR = os.getenv("BIOMETRIA_LOG_DIR", str(BASE_DIR / "logs"))
    DATA_DIR = os.getenv("BIOMETRIA_DATA_DIR", str(BASE_DIR / "data"))
    
    # Configuración del modelo
    MODEL_NAME = os.getenv("BIOMETRIA_MODEL", "Facenet512")
    CALIDAD_MINIMA = float(os.getenv("BIOMETRIA_CALIDAD_MINIMA", "50.0"))
    
    # Configuración de logging
    LOG_LEVEL = os.getenv("BIOMETRIA_LOG_LEVEL", "INFO")
    LOG_FILE = os.getenv("BIOMETRIA_LOG_FILE", str(BASE_DIR / "logs" / "motor_biometrico.log"))
    
    # Configuración de la aplicación
    APP_NAME = "Motor Biométrico - Modo Desktop"
    APP_VERSION = "2.0.0-desktop"
    DEBUG = os.getenv("BIOMETRIA_DEBUG", "false").lower() == "true"
    
    # Configuración de seguridad
    ALLOWED_ORIGINS = ["http://10.5.213.111:8080", "http://localhost:8080"]
    RATE_LIMIT_ENABLED = True
    
    # Configuración de base de datos
    DATABASE_TYPE = "postgresql"  # PostgreSQL para modo desktop
    DATABASE_PATH = str(BASE_DIR / "data" / "biometrico.db")  # Mantener por compatibilidad
    
    @classmethod
    def create_directories(cls):
        """Crear directorios necesarios"""
        dirs = [
            cls.TEMP_DIR,
            cls.LOG_DIR,
            cls.DATA_DIR,
            str(BASE_DIR / "storage" / "fotos"),
            str(BASE_DIR / "storage" / "huellas"),
        ]
        
        for dir_path in dirs:
            Path(dir_path).mkdir(parents=True, exist_ok=True)
    
    @classmethod
    def get_database_url(cls):
        """Obtener URL de conexión a base de datos"""
        # Siempre usar PostgreSQL para modo desktop
        return os.getenv(
            "DATABASE_URL",
            f"postgresql://{os.getenv('DB_USER', 'usuario_app')}:{os.getenv('DB_PASS', '')}@{os.getenv('DB_HOST', '10.5.213.111')}:{os.getenv('DB_PORT', '5432')}/{os.getenv('DB_NAME', 'db_smartcset')}"
        )
    
    @classmethod
    def get_config_dict(cls):
        """Obtener configuración como diccionario"""
        return {
            "host": cls.HOST,
            "port": cls.PORT,
            "api_key": cls.API_KEY,
            "temp_dir": cls.TEMP_DIR,
            "log_dir": cls.LOG_DIR,
            "data_dir": cls.DATA_DIR,
            "model_name": cls.MODEL_NAME,
            "calidad_minima": cls.CALIDAD_MINIMA,
            "log_level": cls.LOG_LEVEL,
            "app_name": cls.APP_NAME,
            "app_version": cls.APP_VERSION,
            "debug": cls.DEBUG,
            "database_type": cls.DATABASE_TYPE,
            "database_path": cls.DATABASE_PATH,
        }

# =============================================================================
# CONFIGURACIÓN PARA MODO WEB
# =============================================================================

class ConfigWeb:
    """Configuración para modo web"""
    
    HOST = os.getenv("BIOMETRIA_HOST", "0.0.0.0")
    PORT = int(os.getenv("BIOMETRIA_PORT", "5000"))
    API_KEY = os.getenv("BIOMETRIA_API_KEY", "cambiar-api-key-segura")
    
    TEMP_DIR = os.getenv("BIOMETRIA_TEMP_DIR", "/tmp/biometria_temp")
    MODEL_NAME = os.getenv("BIOMETRIA_MODEL", "Facenet512")
    CALIDAD_MINIMA = float(os.getenv("BIOMETRIA_CALIDAD_MINIMA", "50.0"))
    LOG_LEVEL = os.getenv("BIOMETRIA_LOG_LEVEL", "INFO")
    
    DATABASE_TYPE = "postgresql"
    
    @classmethod
    def get_database_url(cls):
        """Obtener URL de conexión a base de datos"""
        return os.getenv(
            "DATABASE_URL",
            f"postgresql://{os.getenv('DB_USER', 'usuario_app')}:{os.getenv('DB_PASS', '')}@{os.getenv('DB_HOST', '10.5.213.111')}:{os.getenv('DB_PORT', '5432')}/{os.getenv('DB_NAME', 'db_smartcset')}"
        )

# =============================================================================
# FUNCIÓN PARA OBTENER CONFIGURACIÓN
# =============================================================================

def get_config(mode=None):
    """
    Obtener configuración según el modo de operación
    
    Args:
        mode: 'desktop' o 'web'. Si es None, detecta automáticamente.
    
    Returns:
        Clase de configuración apropiada
    """
    # Siempre usar configuración desktop con PostgreSQL
    return ConfigDesktop

# =============================================================================
# FUNCIÓN PARA INICIALIZAR CONFIGURACIÓN
# =============================================================================

def init_config():
    """Inicializar configuración según el modo de operación"""
    config = get_config()
    
    # Crear directorios necesarios
    if hasattr(config, 'create_directories'):
        config.create_directories()
    
    # Configurar logging
    import logging
    
    log_format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    log_level = getattr(logging, config.LOG_LEVEL.upper(), logging.INFO)
    
    # Configurar handler de archivo si estamos en modo desktop
    if hasattr(config, 'LOG_FILE'):
        from logging.handlers import RotatingFileHandler
        
        file_handler = RotatingFileHandler(
            config.LOG_FILE,
            maxBytes=10*1024*1024,  # 10MB
            backupCount=5,
            encoding='utf-8'
        )
        file_handler.setFormatter(logging.Formatter(log_format))
        logging.getLogger().addHandler(file_handler)
    
    # Configurar handler de consola
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(logging.Formatter(log_format))
    logging.getLogger().addHandler(console_handler)
    
    logging.getLogger().setLevel(log_level)
    
    return config

# =============================================================================
# PUNTO DE ENTRADA
# =============================================================================

if __name__ == "__main__":
    # Mostrar configuración actual
    config = get_config()
    print(f"Modo: {'Desktop' if config == ConfigDesktop else 'Web'}")
    print(f"Configuración: {config.get_config_dict()}")
