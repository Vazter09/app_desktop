
import base64
import json
import logging
import os
import sys
import uuid
from contextlib import asynccontextmanager

import cv2
import numpy as np
from deepface import DeepFace
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field, field_validator

# -----------------------------------------------------------------------------
# Configuración vía variables de entorno
# -----------------------------------------------------------------------------
HOST = os.getenv("BIOMETRIA_HOST", "0.0.0.0")
PORT = int(os.getenv("BIOMETRIA_PORT", "5000"))
API_KEY = os.getenv("BIOMETRIA_API_KEY", "cambiar-api-key-segura")
TEMP_DIR = os.getenv("BIOMETRIA_TEMP_DIR", "/tmp/biometria_temp")
LOG_LEVEL = os.getenv("BIOMETRIA_LOG_LEVEL", "INFO")
MODEL_NAME = os.getenv("BIOMETRIA_MODEL", "Facenet512")
CALIDAD_MINIMA = float(os.getenv("BIOMETRIA_CALIDAD_MINIMA", "50.0"))
# El backend "opencv" (default de DeepFace) depende del haarcascade que trae
# el paquete opencv-python; en algunos entornos ese archivo no se resuelve y
# la detección falla siempre. "retinaface" es más preciso y no tiene ese
# problema — verificado contra cámara real en esta sesión.
DETECTOR_BACKEND = os.getenv("BIOMETRIA_DETECTOR_BACKEND", "retinaface")

os.makedirs(TEMP_DIR, exist_ok=True)

# -----------------------------------------------------------------------------
# Logging estructurado (JSON)
# -----------------------------------------------------------------------------
class JsonFormatter(logging.Formatter):
    def format(self, record):
        log = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        if hasattr(record, "extra"):
            log.update(record.extra)
        if record.exc_info and record.exc_info[0]:
            log["exception"] = self.formatException(record.exc_info)
        return json.dumps(log)

_handler = logging.StreamHandler(sys.stdout)
_handler.setFormatter(JsonFormatter())
logger = logging.getLogger("motor_biometrico")
logger.setLevel(getattr(logging, LOG_LEVEL.upper(), logging.INFO))
logger.addHandler(_handler)
logger.propagate = False

# -----------------------------------------------------------------------------
# FastAPI con lifespan en vez de eventos (>= 0.99)
# -----------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Motor biométrico iniciado", extra={"modelo": MODEL_NAME, "temp_dir": TEMP_DIR})
    yield
    logger.info("Motor biométrico detenido")

app = FastAPI(title="Motor Biométrico Facial", version="2.0.0", lifespan=lifespan)


# -----------------------------------------------------------------------------
# Esquemas Pydantic
# -----------------------------------------------------------------------------
class ExtraerVectorRequest(BaseModel):
    imagen_base64: str = Field(..., min_length=100)


class InfoResponse(BaseModel):
    modelo: str
    dimensiones: int
    estado: str
    version: str
    huella_sdk: bool = False


class CalidadMetricas(BaseModel):
    nitidez: float
    brillo: float
    contraste: float
    rostro_detectado: bool


class ExtraerVectorResponse(BaseModel):
    exito: bool
    dimensiones: int
    vector_facial: list[float]
    calidad_facial: float
    metricas_calidad: CalidadMetricas


class ErrorResponse(BaseModel):
    exito: bool
    mensaje: str


# -----------------------------------------------------------------------------
# Seguridad: API Key via header X-API-Key
# -----------------------------------------------------------------------------
def verificar_api_key(request: Request):
    key = request.headers.get("X-API-Key", "")
    if key != API_KEY:
        logger.warning("Intento de acceso con API key inválida")
        raise HTTPException(status_code=401, detail="API Key inválida")


# -----------------------------------------------------------------------------
# Middleware de logging
# -----------------------------------------------------------------------------
@app.middleware("http")
async def log_requests(request: Request, call_next):
    import time
    inicio = time.time()
    try:
        response = await call_next(request)
        duracion = time.time() - inicio
        logger.info("", extra={
            "method": request.method,
            "path": request.url.path,
            "status": response.status_code,
            "duracion_ms": round(duracion * 1000, 1),
        })
        return response
    except HTTPException:
        raise
    except Exception as e:
        duracion = time.time() - inicio
        logger.error("", extra={
            "method": request.method,
            "path": request.url.path,
            "error": str(e),
            "duracion_ms": round(duracion * 1000, 1),
        })
        raise


# -----------------------------------------------------------------------------
# Endpoint: Health Check
# -----------------------------------------------------------------------------
@app.get("/health", response_model=InfoResponse)
def health():
    huella_disponible = False
    try:
        from huella_sdk import sdk as _hs
        huella_disponible = True
    except ImportError:
        pass

    return InfoResponse(
        modelo=MODEL_NAME,
        dimensiones=512,
        estado="ok",
        version="2.0.0",
        huella_sdk=huella_disponible,
    )


# -----------------------------------------------------------------------------
# Análisis de calidad de imagen con OpenCV
# -----------------------------------------------------------------------------
def analizar_calidad_imagen(ruta_imagen: str) -> dict:
    img = cv2.imread(ruta_imagen)
    if img is None:
        return {"nitidez": 0.0, "brillo": 0.0, "contraste": 0.0}

    gris = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    var_laplacian = cv2.Laplacian(gris, cv2.CV_64F).var()
    nitidez = min(var_laplacian / 500.0, 1.0)

    brillo = float(np.mean(gris)) / 255.0

    contraste = float(np.std(gris)) / 128.0
    contraste = min(contraste, 1.0)

    return {
        "nitidez": round(nitidez, 4),
        "brillo": round(brillo, 4),
        "contraste": round(contraste, 4),
    }


def calcular_calidad_facial(metricas: dict) -> float:
    peso_nitidez = 0.5
    peso_brillo = 0.2
    peso_contraste = 0.3
    puntaje = (
        metricas["nitidez"] * peso_nitidez
        + (1.0 - abs(metricas["brillo"] - 0.5) * 2) * peso_brillo
        + metricas["contraste"] * peso_contraste
    )
    return round(max(0.0, min(100.0, puntaje * 100.0)), 2)


# -----------------------------------------------------------------------------
# Endpoint: Extraer Vector Facial
# -----------------------------------------------------------------------------
@app.post(
    "/extraer_vector",
    response_model=ExtraerVectorResponse | ErrorResponse,
    dependencies=[],
)
def extraer_vector(request: Request, datos: ExtraerVectorRequest):
    if API_KEY and API_KEY != "cambiar-api-key-segura":
        verificar_api_key(request)

    nombre_temp = f"{uuid.uuid4().hex}.jpg"
    ruta_temp = os.path.join(TEMP_DIR, nombre_temp)

    try:
        imagen_data = base64.b64decode(datos.imagen_base64)
        with open(ruta_temp, "wb") as f:
            f.write(imagen_data)

        metricas_opencv = analizar_calidad_imagen(ruta_temp)
        calidad_temp = calcular_calidad_facial(metricas_opencv)

        if calidad_temp < CALIDAD_MINIMA:
            os.remove(ruta_temp)
            logger.warning("Imagen rechazada por baja calidad",
                           extra={"calidad": calidad_temp, "metricas": metricas_opencv})
            return ErrorResponse(
                exito=False,
                mensaje=f"Calidad de imagen insuficiente ({calidad_temp}%). Brillo, contraste o nitidez fuera de rango."
            )

        representacion = DeepFace.represent(
            img_path=ruta_temp,
            model_name=MODEL_NAME,
            detector_backend=DETECTOR_BACKEND,
            enforce_detection=True,
        )

        vector_facial = representacion[0]["embedding"]
        facial_area = representacion[0].get("facial_area", {})
        rostro_detectado = facial_area is not None and facial_area.get("w", 0) > 0

        os.remove(ruta_temp)

        logger.info("Vector extraído correctamente",
                    extra={"dimensiones": len(vector_facial), "calidad": calidad_temp})

        return ExtraerVectorResponse(
            exito=True,
            dimensiones=len(vector_facial),
            vector_facial=vector_facial,
            calidad_facial=calidad_temp,
            metricas_calidad=CalidadMetricas(
                nitidez=metricas_opencv["nitidez"],
                brillo=metricas_opencv["brillo"],
                contraste=metricas_opencv["contraste"],
                rostro_detectado=rostro_detectado,
            ),
        )

    except ValueError:
        if os.path.exists(ruta_temp):
            os.remove(ruta_temp)
        logger.warning("No se detectó rostro en la imagen")
        return ErrorResponse(
            exito=False,
            mensaje="No se detectó un rostro válido en la imagen proporcionada.",
        )

    except Exception as e:
        if os.path.exists(ruta_temp):
            os.remove(ruta_temp)
        logger.error("Error interno", extra={"error": str(e)})
        return ErrorResponse(
            exito=False,
            mensaje=f"Error interno del motor de IA: {str(e)}",
        )


# -----------------------------------------------------------------------------
# Endpoint: Comparar Huellas (SourceAFIS - ISO 19794-2)
# -----------------------------------------------------------------------------
class CompararHuellaRequest(BaseModel):
    template_hex_1: str = Field(..., min_length=10)
    template_hex_2: str = Field(..., min_length=10)


@app.post("/comparar_huella")
def comparar_huella(request: Request, datos: CompararHuellaRequest):
    if API_KEY and API_KEY != "cambiar-api-key-segura":
        verificar_api_key(request)

    try:
        from huella_sdk import sdk as huella_sdk

        resultado = huella_sdk.verificar(datos.template_hex_1, datos.template_hex_2)

        return {
            "exito": True,
            "coincide": resultado.coincide,
            "score": resultado.score,
            "score_normalizado": resultado.score_normalizado,
            "umbral_aplicado": resultado.umbral_aplicado,
        }

    except ImportError:
        logger.error("huella_sdk no disponible - instalar sourceafis")
        return {
            "exito": False,
            "mensaje": "SDK de huella (sourceafis) no instalado. Ejecute: pip install sourceafis",
        }

    except Exception as e:
        logger.error("Error en comparación de huella", extra={"error": str(e)})
        return {
            "exito": False,
            "mensaje": f"Error en matching dactilar: {str(e)}",
        }


# -----------------------------------------------------------------------------
# Endpoint: Extraer template de huella desde imagen
# -----------------------------------------------------------------------------
class ExtraerTemplateHuellaRequest(BaseModel):
    imagen_base64: str = Field(..., min_length=100)


@app.post("/extraer_template_huella")
def extraer_template_huella(request: Request, datos: ExtraerTemplateHuellaRequest):
    if API_KEY and API_KEY != "cambiar-api-key-segura":
        verificar_api_key(request)

    try:
        from huella_sdk import sdk as huella_sdk

        resultado = huella_sdk.extraer_template_desde_base64(datos.imagen_base64)

        if not resultado["exito"]:
            return {"exito": False, "mensaje": resultado.get("mensaje", "Error al extraer template")}

        return {
            "exito": True,
            "template_hex": resultado["template_hex"],
            "calidad": resultado["calidad"],
        }

    except ImportError:
        return {"exito": False, "mensaje": "SDK sourceafis no instalado."}

    except Exception as e:
        logger.error("Error extrayendo template de huella", extra={"error": str(e)})
        return {"exito": False, "mensaje": str(e)}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=HOST, port=PORT, log_level=LOG_LEVEL.lower())
