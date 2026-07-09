"""
Motor de extracción de vector facial — la única pieza de la app que
calcula el embedding (los 128 floats) a partir de un rostro capturado.

Modelo: SFace (`face_recognition_sface_2021dec.onnx`) + detector YuNet
(`face_detection_yunet_2023mar.onnx`), ambos del repositorio oficial
`opencv_zoo` (Apache 2.0), vendorizados en `motor/models/` — sin
descarga en tiempo de ejecución (misma razón que Chart.js se
vendorizó en el SIEM web: la intranet SENA no garantiza internet).

Dependencia: `opencv-python-headless` (ya instalada para la cámara,
ver `ui/camera.py`) — el módulo de detección/reconocimiento facial
viene incluido en el propio paquete, no es una dependencia nueva.

Nota de arquitectura (pendiente, no bloqueante): REGLAS_APP_ESCRITORIO_SGI.md
sección 5.2 describe este cómputo corriendo en un PROCESO aparte con su
propio servidor HTTPS local. Por ahora corre en el mismo proceso que la
UI porque reutiliza la misma dependencia ya cargada para la cámara (no
hay superficie nueva de terceros que aislar) — separarlo en un proceso
HTTPS propio queda como endurecimiento futuro, no un requisito que esta
fase esté incumpliendo silenciosamente.
"""
from __future__ import annotations

import os

import cv2
import numpy as np

_MODELS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "models")
_DETECTOR_PATH = os.path.join(_MODELS_DIR, "face_detection_yunet_2023mar.onnx")
_RECOGNIZER_PATH = os.path.join(_MODELS_DIR, "face_recognition_sface_2021dec.onnx")

EMBEDDING_DIMENSION = 128


class FaceEmbedder:
    """Envuelve YuNet (detección) + SFace (embedding). Una instancia por
    proceso — los modelos se cargan una sola vez (son livianos: ~39MB)."""

    def __init__(self) -> None:
        if not os.path.isfile(_DETECTOR_PATH) or not os.path.isfile(_RECOGNIZER_PATH):
            raise FileNotFoundError(
                "Modelos del motor biométrico no encontrados en "
                f"{_MODELS_DIR} — ver motor/models/README (deben vendorizarse, "
                "no se descargan en tiempo de ejecución)."
            )
        self._detector = cv2.FaceDetectorYN_create(_DETECTOR_PATH, "", (320, 320))
        self._recognizer = cv2.FaceRecognizerSF_create(_RECOGNIZER_PATH, "")

    def extraer(self, frame_bgr: np.ndarray) -> tuple[list[float], float] | None:
        """Detecta el rostro más confiable del frame y devuelve
        `(embedding_128d, calidad_0_a_100)`, o `None` si no hay rostro."""
        alto, ancho = frame_bgr.shape[:2]
        self._detector.setInputSize((ancho, alto))
        ok, caras = self._detector.detect(frame_bgr)

        if not ok or caras is None or len(caras) == 0:
            return None

        # YuNet devuelve las caras ordenadas por confianza (columna 14).
        mejor = caras[0]
        confianza = float(mejor[14])

        alineada = self._recognizer.alignCrop(frame_bgr, mejor)
        vector = self._recognizer.feature(alineada)

        embedding = [float(v) for v in vector.flatten()]
        calidad = round(min(confianza, 1.0) * 100, 2)

        return embedding, calidad
