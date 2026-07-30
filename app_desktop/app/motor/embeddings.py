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

from app_paths import resource_root

_MODELS_DIR = os.path.join(str(resource_root()), "motor", "models")
if not os.path.isdir(_MODELS_DIR):
    # Desarrollo / layout clásico junto a este módulo.
    _MODELS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "models")
_DETECTOR_NAME = "face_detection_yunet_2023mar.onnx"
_RECOGNIZER_NAME = "face_recognition_sface_2021dec.onnx"
_DETECTOR_PATH = os.path.join(_MODELS_DIR, _DETECTOR_NAME)
_RECOGNIZER_PATH = os.path.join(_MODELS_DIR, _RECOGNIZER_NAME)

EMBEDDING_DIMENSION = 128

# YuNet trae score_threshold=0.9 por defecto — demasiado estricto para
# webcams de portería. En pruebas reales (2026-07-16, cámara índice 0)
# los rostros válidos llegaban ~0.20–0.28; con 0.45 no se detectaba nada.
YUNET_SCORE_THRESHOLD = 0.22
YUNET_NMS_THRESHOLD = 0.3
DETECCION_MAX_LADO_PX = 640


def _ruta_onnx_para_opencv(nombre_archivo: str) -> str:
    """Ruta absoluta al ONNX que OpenCV pueda abrir en este equipo.

    En Windows, el lector ONNX de OpenCV falla con rutas que contienen
    caracteres no ASCII (p. ej. ``Jose Álvarez`` en el perfil de usuario).
    Copiamos los modelos vendorizados a ``%ProgramData%\\SmartCSET\\models``
    (ruta solo ASCII) y cargamos desde ahí.
    """
    origen = os.path.join(_MODELS_DIR, nombre_archivo)
    if not os.path.isfile(origen):
        raise FileNotFoundError(
            "Modelos del motor biométrico no encontrados en "
            f"{_MODELS_DIR} — ver motor/models/README (deben vendorizarse, "
            "no se descargan en tiempo de ejecución)."
        )

    if os.name != "nt":
        return origen

    cache_dir = os.path.join(
        os.environ.get("PROGRAMDATA", r"C:\ProgramData"),
        "SmartCSET",
        "models",
    )
    os.makedirs(cache_dir, exist_ok=True)
    destino = os.path.join(cache_dir, nombre_archivo)

    try:
        if (
            not os.path.isfile(destino)
            or os.path.getmtime(destino) < os.path.getmtime(origen)
        ):
            import shutil

            shutil.copy2(origen, destino)
    except OSError as exc:
        raise FileNotFoundError(
            f"No se pudo preparar el modelo biométrico en {cache_dir}: {exc}"
        ) from exc

    return destino


class FaceEmbedder:
    """Envuelve YuNet (detección) + SFace (embedding). Una instancia por
    proceso — los modelos se cargan una sola vez (son livianos: ~39MB)."""

    def __init__(self) -> None:
        detector_path = _ruta_onnx_para_opencv(_DETECTOR_NAME)
        recognizer_path = _ruta_onnx_para_opencv(_RECOGNIZER_NAME)
        self._detector = cv2.FaceDetectorYN_create(
            detector_path, "", (320, 320)
        )
        self._detector.setScoreThreshold(YUNET_SCORE_THRESHOLD)
        self._detector.setNMSThreshold(YUNET_NMS_THRESHOLD)
        self._recognizer = cv2.FaceRecognizerSF_create(recognizer_path, "")

    def _frame_para_deteccion(self, frame_bgr: np.ndarray) -> np.ndarray:
        """Escala el frame si es muy grande — más rápido y estable en vivo."""
        alto, ancho = frame_bgr.shape[:2]
        max_lado = max(alto, ancho)
        if max_lado <= DETECCION_MAX_LADO_PX:
            return frame_bgr
        escala = DETECCION_MAX_LADO_PX / max_lado
        nuevo_ancho = int(ancho * escala)
        nuevo_alto = int(alto * escala)
        return cv2.resize(
            frame_bgr, (nuevo_ancho, nuevo_alto), interpolation=cv2.INTER_AREA
        )

    def _detectar_caras(self, frame_bgr: np.ndarray):
        preparado = self._frame_para_deteccion(frame_bgr)
        alto, ancho = preparado.shape[:2]
        self._detector.setInputSize((ancho, alto))
        ok, caras = self._detector.detect(preparado)
        if not ok or caras is None or len(caras) == 0:
            return ok, caras

        if preparado.shape[:2] != frame_bgr.shape[:2]:
            escala_x = frame_bgr.shape[1] / ancho
            escala_y = frame_bgr.shape[0] / alto
            caras = np.array(caras, copy=True)
            caras[:, 0] *= escala_x
            caras[:, 1] *= escala_y
            caras[:, 2] *= escala_x
            caras[:, 3] *= escala_y
            for idx in range(4, 14):
                factor = escala_x if idx % 2 == 0 else escala_y
                caras[:, idx] *= factor
        return ok, caras

    def detectar_confianza(self, frame_bgr: np.ndarray) -> float | None:
        """Solo detección YuNet — más liviano que `extraer()` para el loop
        de cámara en vivo (no calcula embedding)."""
        ok, caras = self._detectar_caras(frame_bgr)
        if not ok or caras is None or len(caras) == 0:
            return None
        return float(caras[0][14])

    def extraer(self, frame_bgr: np.ndarray) -> tuple[list[float], float] | None:
        """Detecta el rostro más confiable del frame y devuelve
        `(embedding_128d, calidad_0_a_100)`, o `None` si no hay rostro."""
        resultado = self.extraer_con_recorte(frame_bgr)
        if resultado is None:
            return None
        embedding, calidad, _recorte = resultado
        return embedding, calidad

    def extraer_con_recorte(
        self, frame_bgr: np.ndarray
    ) -> tuple[list[float], float, np.ndarray] | None:
        """Igual que `extraer`, más el recorte alineado (BGR) del rostro.

        El recorte es la imagen que debe enrolarse en
        ``tab_personas.ruta_foto_facial`` — la misma que usó SFace.
        """
        ok, caras = self._detectar_caras(frame_bgr)
        if not ok or caras is None or len(caras) == 0:
            return None

        mejor = caras[0]
        confianza = float(mejor[14])

        alineada = self._recognizer.alignCrop(frame_bgr, mejor)
        vector = self._recognizer.feature(alineada)

        embedding = [float(v) for v in vector.flatten()]
        calidad = round(min(confianza, 1.0) * 100, 2)

        return embedding, calidad, alineada
