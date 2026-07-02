"""
Motor Biométrico - Modo Desktop
Este script inicia el motor biométrico con configuración para modo desktop
"""

import os
import sys
from pathlib import Path

# Agregar directorio actual y directorio padre al path
current_dir = Path(__file__).parent
parent_dir = current_dir.parent
sys.path.insert(0, str(current_dir))
sys.path.insert(0, str(parent_dir))

def main():
    """Función principal para iniciar el motor biométrico en modo desktop"""
    
    print("=" * 60)
    print("Motor Biométrico - Modo Desktop")
    print("Sistema de Reconocimiento Biométrico Multimodal")
    print("=" * 60)
    print()
    
    # Verificar dependencias
    try:
        import fastapi
        import uvicorn
        import cv2
        import numpy as np
        from deepface import DeepFace
        print("✓ Todas las dependencias Python están instaladas")
    except ImportError as e:
        print(f"✗ Falta dependencia: {e}")
        print("Por favor, instale las dependencias: pip install -r requirements.txt")
        return False
    
    # Importar configuración
    try:
        from config_motor_desktop import get_config
        config = get_config("desktop")
        print(f"✓ Configuración desktop cargada")
    except ImportError as e:
        print(f"✗ Error al cargar configuración: {e}")
        return False
    
    # Crear directorios necesarios
    try:
        if hasattr(config, 'create_directories'):
            config.create_directories()
            print(f"✓ Directorios creados")
    except Exception as e:
        print(f"✗ Error al crear directorios: {e}")
        return False
    
    # Configurar variables de entorno
    os.environ["BIOMETRIA_HOST"] = config.HOST
    os.environ["BIOMETRIA_PORT"] = str(config.PORT)
    os.environ["BIOMETRIA_API_KEY"] = config.API_KEY
    os.environ["BIOMETRIA_TEMP_DIR"] = config.TEMP_DIR
    os.environ["BIOMETRIA_LOG_LEVEL"] = config.LOG_LEVEL
    os.environ["BIOMETRIA_MODEL"] = config.MODEL_NAME
    os.environ["BIOMETRIA_CALIDAD_MINIMA"] = str(config.CALIDAD_MINIMA)
    
    print(f"✓ Variables de entorno configuradas")
    print()
    
    # Mostrar información de configuración
    print("Información de configuración:")
    print(f"  Host: {config.HOST}")
    print(f"  Puerto: {config.PORT}")
    print(f"  Modelo: {config.MODEL_NAME}")
    print(f"  Calidad mínima: {config.CALIDAD_MINIMA}%")
    print(f"  Directorio temporal: {config.TEMP_DIR}")
    print(f"  Directorio de logs: {config.LOG_DIR}")
    print()
    
    # Verificar si el puerto está disponible
    import socket
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    result = sock.connect_ex((config.HOST, config.PORT))
    sock.close()
    
    if result == 0:
        print(f"⚠ El puerto {config.PORT} ya está en uso")
        print("  El motor biométrico podría ya estar ejecutándose")
        print("  Otro proceso está usando ese puerto")
        print()
        respuesta = input("¿Desea continuar de todas formas? (s/n): ")
        if respuesta.lower() != 's':
            return False
    
    print("Iniciando motor biométrico...")
    print("Presione Ctrl+C para detener el motor")
    print()
    
    # Importar y ejecutar el motor principal
    try:
        # Configurar el directorio de trabajo
        os.chdir(current_dir)
        
        # Importar el módulo principal
        import motor_biometrico
        
        # Iniciar el servidor
        import uvicorn
        
        uvicorn.run(
            motor_biometrico.app,
            host=config.HOST,
            port=config.PORT,
            log_level=config.LOG_LEVEL.lower(),
            reload=config.DEBUG
        )
        
    except KeyboardInterrupt:
        print("\nMotor biométrico detenido por el usuario")
        return True
    except Exception as e:
        print(f"✗ Error al iniciar el motor biométrico: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\nOperación cancelada por el usuario")
        sys.exit(0)
