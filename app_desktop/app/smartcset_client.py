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
import os
import ssl
import urllib.error
import urllib.parse
import urllib.request
from typing import Any


class SmartcsetApiError(Exception):
    """Error de negocio devuelto por el backend (RouterResponse::fail)."""


class SmartcsetConnectionError(Exception):
    """No se pudo alcanzar el servidor (red caída, TLS inválido, etc.)."""


class SmartcsetClient:
    def __init__(self, base_url: str, verify_tls: bool = True) -> None:
        self.base_url = base_url.rstrip("/")
        self._cookie_jar = http.cookiejar.CookieJar()

        # Laboratorio con cert autofirmado: usar contexto no verificado
        # (create_default_context + CERT_NONE a veces no basta en Windows).
        if verify_tls:
            ssl_context = ssl.create_default_context()
        else:
            ssl_context = ssl._create_unverified_context()

        self._opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(self._cookie_jar),
            urllib.request.HTTPSHandler(context=ssl_context),
        )

    # ---- Núcleo HTTP -----------------------------------------------

    def _request(
        self,
        method: str,
        path: str,
        payload: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        url = f"{self.base_url}{path}"
        data = json.dumps(payload).encode("utf-8") if payload is not None else None

        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Content-Type", "application/json")
        req.add_header("Accept", "application/json")

        try:
            with self._opener.open(req, timeout=15) as resp:
                body = resp.read().decode("utf-8")
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8") if exc.fp else "{}"
            try:
                parsed = json.loads(body)
            except json.JSONDecodeError:
                parsed = {}
            if exc.code == 408:
                message = "¡Falla de conexión!"
            else:
                message = parsed.get("error") or f"Error HTTP {exc.code}"
            raise SmartcsetApiError(message) from exc
        except (urllib.error.URLError, TimeoutError) as exc:
            raise SmartcsetConnectionError(
                f"No se pudo conectar con {self.base_url}: {exc}"
            ) from exc

        try:
            parsed = json.loads(body)
        except json.JSONDecodeError as exc:
            raise SmartcsetConnectionError(
                "Respuesta inválida del servidor (¿URL correcta?)."
            ) from exc

        if not parsed.get("ok"):
            raise SmartcsetApiError(parsed.get("error") or "Error desconocido.")

        return parsed.get("data") or {}

    # ---- Endpoints reales reutilizados ------------------------------

    def login(self, usuario: str, clave: str) -> dict[str, Any]:
        """POST /routers/auth/v1/login.php — mismo login que la web."""
        return self._request(
            "POST",
            "/routers/auth/v1/login.php",
            {"usuario": usuario, "clave": clave, "origen": "desktop"},
        )

    def logout(self) -> None:
        """GET /routers/auth/v1/logout.php — cierra la sesión en tab_sesiones."""
        url = f"{self.base_url}/routers/auth/v1/logout.php"
        req = urllib.request.Request(url, method="GET")
        try:
            # El endpoint web responde 302 + HTML; basta con que el servidor
            # ejecute fun_salida_sesion antes del redirect.
            self._opener.open(req, timeout=15)
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError):
            pass
        self._cookie_jar.clear()

    def ingresos_hoy(self) -> list[dict[str, Any]]:
        """GET /routers/porteria/v1/ingreso/hoy.php (sesión real)."""
        data = self._request("GET", "/routers/porteria/v1/ingreso/hoy.php")
        return list(data.get("items", []))

    def salidas_hoy(self) -> list[dict[str, Any]]:
        """GET /routers/porteria/v1/salida/hoy.php (sesión real)."""
        data = self._request("GET", "/routers/porteria/v1/salida/hoy.php")
        return list(data.get("items", []))

    def catalogos(self) -> dict[str, Any]:
        """GET /routers/porteria/v1/catalogos.php — tipos_doc, tipos_persona, entradas."""
        return self._request("GET", "/routers/porteria/v1/catalogos.php")

    def ingreso_consultar(
        self,
        documento: str,
        tipo_doc: str = "CC",
        *,
        incluir_foto: bool = False,
    ) -> dict[str, Any]:
        """GET /routers/porteria/v1/ingreso/consultar.php."""
        params: dict[str, str] = {"documento": documento, "tipo_doc": tipo_doc}
        if incluir_foto:
            params["incluir_foto"] = "1"
        qs = urllib.parse.urlencode(params)
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

    def entrada_guardar(self, payload: dict[str, Any]) -> dict[str, Any]:
        """POST /routers/entradas/v1/guardar.php (requiere admin en el servidor)."""
        return self._request("POST", "/routers/entradas/v1/guardar.php", payload)

    def entrada_eliminar(self, id_entrada: int) -> dict[str, Any]:
        """POST /routers/entradas/v1/eliminar.php (requiere admin en el servidor)."""
        return self._request(
            "POST", "/routers/entradas/v1/eliminar.php", {"id_entrada": id_entrada}
        )

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
