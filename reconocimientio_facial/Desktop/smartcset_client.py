"""
Cliente HTTP contra el backend real de SmartCSET (auth por token de dispositivo,
igual patrón que la app móvil de portería — mobile/porteria-app/).
No reinventa nada del lado del servidor: reusa /device/validate.php,
/biometria/{enrolar,identificar}.php y /ingreso|salida/{consultar,registrar}.php.
"""
import json
import os
import ssl
import urllib.request
import urllib.error


class SmartcsetApiError(Exception):
    def __init__(self, mensaje, http_code=None):
        super().__init__(mensaje)
        self.mensaje = mensaje
        self.http_code = http_code


def _ssl_context(verify_tls):
    """Certificado autofirmado en desarrollo local (ver HANDOFF.md) — permitir
    desactivar la verificación explícitamente vía variable de entorno, nunca
    por defecto. En producción (certificado real / CA válida) debe ir en True."""
    if verify_tls:
        return None  # usa el contexto por defecto de urllib (verifica)
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


class SmartcsetClient:
    def __init__(self, base_url, device_token, timeout=15, verify_tls=None):
        self.base_url = base_url.rstrip("/")
        self.device_token = device_token
        self.timeout = timeout
        if verify_tls is None:
            verify_tls = os.getenv("SMARTCSET_TLS_INSECURE", "0") != "1"
        self._ssl_context = _ssl_context(verify_tls)

    def _post(self, path, payload):
        return self._request(path, method="POST", payload=payload)

    def _get(self, path, params=None):
        if params:
            qs = "&".join(f"{k}={urllib.request.quote(str(v))}" for k, v in params.items())
            path = f"{path}?{qs}"
        return self._request(path, method="GET")

    def _request(self, path, method, payload=None):
        url = f"{self.base_url}{path}"
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Content-Type", "application/json")
        req.add_header("Authorization", f"Bearer {self.device_token}")

        try:
            with urllib.request.urlopen(req, timeout=self.timeout, context=self._ssl_context) as resp:
                body = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            try:
                body = json.loads(e.read().decode("utf-8"))
                mensaje = body.get("error") or body.get("mensaje") or str(e)
            except Exception:
                mensaje = str(e)
            raise SmartcsetApiError(mensaje, http_code=e.code) from e
        except urllib.error.URLError as e:
            raise SmartcsetApiError(f"No se pudo conectar al servidor SmartCSET: {e}") from e

        if not body.get("ok", False):
            raise SmartcsetApiError(body.get("error") or "Error desconocido del servidor.")

        return body.get("data", {})

    # --- "Login" del dispositivo (mismo endpoint que usa la app móvil) ---
    def validar_dispositivo(self):
        return self._post("/routers/porteria/v1/device/validate.php", {})

    # --- Biometría ---
    def enrolar(self, documento, vector_facial, foto_base64=None, calidad_facial=0.0):
        payload = {
            "documento": str(documento),
            "vector_facial": vector_facial,
            "calidad_facial": calidad_facial,
        }
        if foto_base64:
            payload["foto_base64"] = foto_base64
        return self._post("/routers/porteria/v1/biometria/enrolar.php", payload)

    def identificar(self, vector_facial):
        return self._post(
            "/routers/porteria/v1/biometria/identificar.php",
            {"vector_facial": vector_facial},
        )

    # --- Consulta de estado de acceso (reusa el mismo endpoint que ingreso manual) ---
    def consultar_acceso(self, documento, tipo_doc="CC"):
        return self._get(
            "/routers/porteria/v1/ingreso/consultar.php",
            {"documento": documento, "tipo_doc": tipo_doc},
        )

    # --- Ingreso / salida reales (mismos endpoints que usa toda la portería) ---
    METODO_AUT_BIOMETRICO = 4

    def registrar_ingreso(self, documento, tipo_doc, tipo_persona, nombres, apellidos,
                           foto_base64=None, observaciones=""):
        payload = {
            "documento": str(documento),
            "tipo_doc": tipo_doc,
            "tipo_persona": tipo_persona,
            "nombres": nombres,
            "apellidos": apellidos,
            "observaciones": observaciones,
            "metodo_aut": self.METODO_AUT_BIOMETRICO,
        }
        if foto_base64:
            payload["foto_base64"] = foto_base64
        return self._post("/routers/porteria/v1/ingreso/registrar.php", payload)

    def registrar_salida(self, documento, tipo_doc="CC", foto_base64=None, observaciones=""):
        payload = {
            "documento": str(documento),
            "tipo_doc": tipo_doc,
            "observaciones": observaciones,
            "metodo_aut": self.METODO_AUT_BIOMETRICO,
        }
        if foto_base64:
            payload["foto_base64"] = foto_base64
        return self._post("/routers/porteria/v1/salida/registrar.php", payload)


def extraer_vector_local(imagen_base64, motor_url="http://127.0.0.1:5000", api_key=None, timeout=30):
    """Llama al motor Facenet512 LOCAL (mismo PC de portería) para extraer el vector.
    No pasa por el backend central: el cómputo pesado de IA se queda en el equipo."""
    payload = json.dumps({"imagen_base64": imagen_base64}).encode("utf-8")
    req = urllib.request.Request(f"{motor_url}/extraer_vector", data=payload, method="POST")
    req.add_header("Content-Type", "application/json")
    if api_key:
        req.add_header("X-API-Key", api_key)

    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        try:
            body = json.loads(e.read().decode("utf-8"))
            mensaje = body.get("mensaje", str(e))
        except Exception:
            mensaje = str(e)
        raise SmartcsetApiError(f"Motor biométrico local: {mensaje}") from e
    except urllib.error.URLError as e:
        raise SmartcsetApiError(f"Motor biométrico local no responde: {e}") from e

    if not body.get("exito", False):
        raise SmartcsetApiError(body.get("mensaje", "Fallo desconocido en el motor biométrico local."))

    return body
