# Modelos vendorizados — motor biométrico

Vendorizados aquí (no se descargan en tiempo de ejecución — misma razón
que Chart.js se vendorizó en el SIEM web: la intranet SENA no garantiza
internet), del repositorio oficial [`opencv_zoo`](https://github.com/opencv/opencv_zoo)
(Apache 2.0):

| Archivo | Modelo | Uso |
|---|---|---|
| `face_detection_yunet_2023mar.onnx` | YuNet | Detecta la ubicación del rostro en el frame |
| `face_recognition_sface_2021dec.onnx` | SFace | Calcula el vector de 128 dimensiones (embedding) del rostro alineado |

Cargados vía `cv2.FaceDetectorYN_create()` / `cv2.FaceRecognizerSF_create()`
— parte del propio paquete `opencv-python-headless` ya instalado para la
cámara (`ui/camera.py`), no una dependencia nueva.

Si se necesita regenerar estos archivos:
```bash
curl -sL -o face_detection_yunet_2023mar.onnx \
  "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx"
curl -sL -o face_recognition_sface_2021dec.onnx \
  "https://github.com/opencv/opencv_zoo/raw/main/models/face_recognition_sface/face_recognition_sface_2021dec.onnx"
```
