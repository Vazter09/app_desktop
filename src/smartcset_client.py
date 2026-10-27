"""
Cliente HTTP contra el backend real de SmartCSET — 100% librería estándar
de Python (urllib + http.cookiejar + json), sin `requests` ni ninguna
dependencia de terceros (ver REGLAS_APP_ESCRITORIO_SGI.md, sección 4).

Reutiliza el login real de SmartCSET (usuario/contraseña, sesión PHP +
cookie) — el mismo mecanismo que usa la web, con rate limiting E3 y
auditoría ya incluidos del lado del servidor. No hay token de dispositivo.

TLS: el certificado del servidor institucional real es válido (no
autofirmado); en este entorno de desarrollo local/laboratorio el
certificado es autofirmado, por lo que se permite desactivar la
verificación SOLO cuando `verify_tls=False` se pasa explícitamente al
construir el cliente (nunca por defecto en el código).
"""
from __future__ import annotations

import http.cookiejar
import json
import ssl
import threading
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Callable
from typing import Any
from urllib.parse import urlsplit

from app_log import flush_handlers, get_logger

log = get_logger("smartcset_client")


class SmartcsetApiError(Exception):
    """Error de negocio devuelto por el backend (RouterResponse::fail)."""


class SmartcsetSessionExpired(SmartcsetApiError):
    """La sesión PHP ya no es válida (401 o redirect al login).

    Pasa cuando el mismo usuario inicia sesión en otro equipo o el
    servidor cierra la sesión. El detalle técnico va solo al log; el
    operario ve un mensaje simple y la app vuelve al login.
    """


class SmartcsetConnectionError(Exception):
    """No se pudo alcanzar el servidor (red caída, TLS inválido, etc.)."""


MSG_SESION_EXPIRADA = "Su sesión se cerró. Ingrese de nuevo."
MSG_SERVIDOR_NO_RESPONDE = (
    "El servidor no respondió como se esperaba. Intente de nuevo."
)
MSG_SIN_CONEXION = "No hay conexión con el servidor. Intente de nuevo."


def _path_for_log(path: str) -> str:
    """Path sin query string (evita documento u otros params en el log)."""
    return urlsplit(path).path or path


def _body_preview(body: str, limit: int = 180) -> str:
    text = " ".join((body or "").split())
    if len(text) <= limit:
        return text
    return text[:limit] + "…"


class _NoFollowRedirectHandler(urllib.request.HTTPRedirectHandler):
    """No seguir 3xx: un redirect a login HTML se parseaba como
    «Respuesta inválida» y enmascaraba pérdida de sesión / URL mala."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):  # noqa: ANN001
        return None


class SmartcsetClient:
    def __init__(self, base_url: str, verify_tls: bool = True) -> None:
        self.base_url = base_url.rstrip("/")
        self._cookie_jar = http.cookiejar.CookieJar()
        self._lock = threading.RLock()
        # La UI lo asigna para volver al login cuando la sesión caduca.
        self.on_session_expired: Callable[[], None] | None = None

        # Laboratorio con cert autofirmado: usar contexto no verificado
        # (create_default_context + CERT_NONE a veces no basta en Windows).
        if verify_tls:
            ssl_context = ssl.create_default_context()
        else:
            ssl_context = ssl._create_unverified_context()

        self._opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(self._cookie_jar),
            _NoFollowRedirectHandler(),
            urllib.request.HTTPSHandler(context=ssl_context),
        )

    def clear_cookies(self) -> None:
        """Borra cookies locales sin llamar al servidor."""
        with self._lock:
            self._cookie_jar.clear()

    def has_session_cookie(self) -> bool:
        with self._lock:
            return any(c.name == "PHPSESSID" and c.value for c in self._cookie_jar)

    def _notify_session_expired(self) -> None:
        """Cookie muerta: limpiarla y avisar a la UI (si se registró)."""
        self._cookie_jar.clear()
        callback = self.on_session_expired
        if callback is None:
            return
        try:
            callback()
        except Exception as exc:  # noqa: BLE001 — nunca romper la request
            log.warning("on_session_expired falló: %s", exc)
            flush_handlers()

    # ---- Núcleo HTTP -----------------------------------------------

    def _request(
        self,
        method: str,
        path: str,
        payload: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        url = f"{self.base_url}{path}"
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        safe_path = _path_for_log(path)

        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Content-Type", "application/json")
        req.add_header("Accept", "application/json")

        with self._lock:
            try:
                with self._opener.open(req, timeout=15) as resp:
                    body = resp.read().decode("utf-8", errors="replace")
            except urllib.error.HTTPError as exc:
                body = (
                    exc.read().decode("utf-8", errors="replace") if exc.fp else "{}"
                )
                try:
                    parsed = json.loads(body)
                except json.JSONDecodeError:
                    parsed = {}
                location = exc.headers.get("Location") or ""
                if exc.code in (301, 302, 303, 307, 308):
                    detalle = (
                        f"El servidor redirigió ({exc.code}) en lugar de JSON. "
                        f"Location={location[:120]}"
                    )
                elif exc.code == 408:
                    detalle = "¡Falla de conexión!"
                else:
                    detalle = parsed.get("error") or f"Error HTTP {exc.code}"
                    if not parsed and body.strip():
                        detalle = (
                            f"{detalle} (respuesta no JSON: {_body_preview(body)})"
                        )
                log.error(
                    "API HTTP %s %s → %s: %s",
                    method,
                    safe_path,
                    exc.code,
                    detalle,
                )
                flush_handlers()
                if exc.code == 401 or (
                    exc.code in (301, 302, 303, 307, 308)
                    and "login" in location.lower()
                ):
                    self._notify_session_expired()
                    raise SmartcsetSessionExpired(MSG_SESION_EXPIRADA) from exc
                if exc.code in (301, 302, 303, 307, 308) or (
                    not parsed and body.strip()
                ):
                    raise SmartcsetApiError(MSG_SERVIDOR_NO_RESPONDE) from exc
                raise SmartcsetApiError(detalle) from exc
            except (urllib.error.URLError, TimeoutError) as exc:
                log.error(
                    "Conexión %s %s (%s): %s",
                    method,
                    safe_path,
                    self.base_url,
                    exc,
                )
                flush_handlers()
                raise SmartcsetConnectionError(MSG_SIN_CONEXION) from exc

            try:
                parsed = json.loads(body)
            except json.JSONDecodeError as exc:
                log.error(
                    "JSON inválido %s %s preview=%s",
                    method,
                    safe_path,
                    _body_preview(body),
                )
                flush_handlers()
                raise SmartcsetConnectionError(MSG_SERVIDOR_NO_RESPONDE) from exc

            if not parsed.get("ok"):
                message = parsed.get("error") or "Error desconocido."
                log.error("API fail %s %s: %s", method, safe_path, message)
                flush_handlers()
                raise SmartcsetApiError(message)

            return parsed.get("data") or {}

    # ---- Endpoints reales reutilizados ------------------------------

    def login(self, usuario: str, clave: str) -> dict[str, Any]:
        """POST /routers/auth/v1/login.php — mismo login que la web."""
        data = self._request(
            "POST",
            "/routers/auth/v1/login.php",
            {"usuario": usuario, "clave": clave, "origen": "desktop"},
        )
        if not self.has_session_cookie():
            raise SmartcsetConnectionError(
                "Login OK pero no se recibió cookie PHPSESSID. "
                f"Revise URL ({self.base_url}) y path de sesión en el servidor."
            )
        return data

    def logout(self) -> None:
        """GET /routers/auth/v1/logout.php — cierra la sesión en tab_sesiones."""
        url = f"{self.base_url}/routers/auth/v1/logout.php"
        req = urllib.request.Request(url, method="GET")
        with self._lock:
            try:
                # Suele responder 302; con NoFollowRedirect es HTTPError — OK.
                self._opener.open(req, timeout=15)
            except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError):
                pass
            self._cookie_jar.clear()

    def salidas_hoy(self) -> list[dict[str, Any]]:
        """GET /routers/porteria/v1/salida/hoy.php (sesión real)."""
        data = self._request("GET", "/routers/porteria/v1/salida/hoy.php")
        return list(data.get("items", []))

    def catalogos(self) -> dict[str, Any]:
        """GET /routers/porteria/v1/catalogos.php — tipos_doc, tipos_persona, entradas."""
        return self._request("GET", "/routers/porteria/v1/catalogos.php")

    def ingreso_consultar(self, documento: str, tipo_doc: str = "CC") -> dict[str, Any]:
        """GET /routers/porteria/v1/ingreso/consultar.php (incluye foto enrolada)."""
        qs = urllib.parse.urlencode(
            {"documento": documento, "tipo_doc": tipo_doc, "incluir_foto": "1"}
        )
        return self._request("GET", f"/routers/porteria/v1/ingreso/consultar.php?{qs}")

    def ingreso_registrar(self, payload: dict[str, Any]) -> dict[str, Any]:
        """POST /routers/porteria/v1/ingreso/registrar.php."""
        return self._request("POST", "/routers/porteria/v1/ingreso/registrar.php", payload)

    def ingreso_actualizar_captura(self, payload: dict[str, Any]) -> dict[str, Any]:
        """POST /routers/porteria/v1/ingreso/actualizar_captura.php — re-captura sin nuevo ingreso."""
        return self._request(
            "POST", "/routers/porteria/v1/ingreso/actualizar_captura.php", payload
        )

    def salida_consultar(self, documento: str, tipo_doc: str = "CC") -> dict[str, Any]:
        """GET /routers/porteria/v1/salida/consultar.php."""
        qs = urllib.parse.urlencode({"documento": documento, "tipo_doc": tipo_doc})
        return self._request("GET", f"/routers/porteria/v1/salida/consultar.php?{qs}")

    def salida_registrar(self, payload: dict[str, Any]) -> dict[str, Any]:
        """POST /routers/porteria/v1/salida/registrar.php."""
        return self._request("POST", "/routers/porteria/v1/salida/registrar.php", payload)

    def biometria_enrolar(
        self,
        documento: str,
        embedding: list[float],
        calidad_facial: float | None = None,
        foto_base64: str | None = None,
        tipo_doc: str = "CC",
        *,
        forzar: bool = False,
    ) -> dict[str, Any]:
        """POST /routers/porteria/v1/biometria/enrolar.php (2026-07-09: con foto).

        ``forzar=True`` solo desde «Capturar Rostro» (reemplaza referencia).
        Sin forzar, si ya hay vector el servidor no lo pisa.
        """
        payload: dict[str, Any] = {
            "documento": documento,
            "embedding": embedding,
            "tipo_doc": (tipo_doc or "CC").strip() or "CC",
            "forzar": bool(forzar),
        }
        if calidad_facial is not None:
            payload["calidad_facial"] = calidad_facial
        if foto_base64 is not None:
            payload["foto_base64"] = foto_base64
        return self._request("POST", "/routers/porteria/v1/biometria/enrolar.php", payload)

    def biometria_identificar(
        self, embedding: list[float], umbral_distancia: float | None = None
    ) -> dict[str, Any]:
        """POST /routers/porteria/v1/biometria/identificar.php (con foto enrolada)."""
        payload: dict[str, Any] = {"embedding": embedding}
        if umbral_distancia is not None:
            payload["umbral_distancia"] = umbral_distancia

        return self._request("POST", "/routers/porteria/v1/biometria/identificar.php", payload)

    def biometria_huella_enrolar(
        self,
        documento: str,
        huella_template_b64: str,
        calidad_huella: float | None = None,
    ) -> dict[str, Any]:
        """POST /routers/porteria/v1/biometria/huella_enrolar.php."""
        payload: dict[str, Any] = {
            "documento": documento,
            "huella_template_b64": huella_template_b64,
        }
        if calidad_huella is not None:
            payload["calidad_huella"] = calidad_huella
        return self._request(
            "POST", "/routers/porteria/v1/biometria/huella_enrolar.php", payload
        )

    def biometria_huella_identificar(self, huella_template_b64: str) -> dict[str, Any]:
        """POST /routers/porteria/v1/biometria/huella_identificar.php."""
        return self._request(
            "POST",
            "/routers/porteria/v1/biometria/huella_identificar.php",
            {"huella_template_b64": huella_template_b64},
        )
