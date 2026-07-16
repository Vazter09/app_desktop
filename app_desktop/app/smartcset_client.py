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

2026-07-09: Caché local de fotos biométricas en app_desktop/app/images/
"""
from __future__ import annotations

import base64
import http.cookiejar
import json
import os
import pathlib
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

    def ingreso_consultar(self, documento: str, tipo_doc: str = "CC") -> dict[str, Any]:
        """GET /routers/porteria/v1/ingreso/consultar.php."""
        qs = urllib.parse.urlencode({"documento": documento, "tipo_doc": tipo_doc})
        return self._request("GET", f"/routers/porteria/v1/ingreso/consultar.php?{qs}")

    def ingreso_registrar(self, payload: dict[str, Any]) -> dict[str, Any]:
        """POST /routers/porteria/v1/ingreso/registrar.php."""
        return self._request("POST", "/routers/porteria/v1/ingreso/registrar.php", payload)

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
    ) -> dict[str, Any]:
        """POST /routers/porteria/v1/biometria/enrolar.php (2026-07-09: con foto)."""
        payload: dict[str, Any] = {"documento": documento, "embedding": embedding}
        if calidad_facial is not None:
            payload["calidad_facial"] = calidad_facial
        if foto_base64 is not None:
            payload["foto_base64"] = foto_base64
        return self._request("POST", "/routers/porteria/v1/biometria/enrolar.php", payload)

    def biometria_identificar(
        self, embedding: list[float], umbral_distancia: float | None = None
    ) -> dict[str, Any]:
        """POST /routers/porteria/v1/biometria/identificar.php (2026-07-09: con foto descargada)."""
        payload: dict[str, Any] = {"embedding": embedding}
        if umbral_distancia is not None:
            payload["umbral_distancia"] = umbral_distancia

        resultado = self._request("POST", "/routers/porteria/v1/biometria/identificar.php", payload)

        # 2026-07-09: Cachear foto localmente si viene en la respuesta
        if resultado.get("foto_base64"):
            persona = resultado.get("persona", {})
            id_persona = persona.get("id_persona")
            nombre = persona.get("nombres", "persona").split()[0].lower()

            if id_persona:
                self._cachear_foto_biometrica(id_persona, nombre, resultado["foto_base64"])

        return resultado

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
        resultado = self._request(
            "POST",
            "/routers/porteria/v1/biometria/huella_identificar.php",
            {"huella_template_b64": huella_template_b64},
        )
        if resultado.get("foto_base64"):
            persona = resultado.get("persona") or {}
            id_persona = persona.get("id_persona")
            nombre = str(persona.get("nombres", "persona")).split()[0].lower()
            if id_persona:
                self._cachear_foto_biometrica(id_persona, nombre, resultado["foto_base64"])
        return resultado

    def _cachear_foto_biometrica(self, id_persona: int, nombre: str, foto_base64: str) -> str | None:
        """Cachea foto en app_desktop/app/images/{id_persona}_{nombre}.jpg
        Retorna ruta local o None si falla."""
        try:
            # Carpeta de caché local
            app_dir = pathlib.Path(__file__).parent
            img_dir = app_dir / "images"
            img_dir.mkdir(exist_ok=True)

            # Nombre del archivo: {id}_{nombre}.jpg
            nombre_limpio = "".join(c for c in nombre if c.isalnum()).lower()
            if not nombre_limpio:
                nombre_limpio = "persona"
            nombre_archivo = f"{id_persona}_{nombre_limpio}.jpg"
            ruta_local = img_dir / nombre_archivo

            # Decodificar y guardar
            foto_binaria = base64.b64decode(foto_base64)
            with open(ruta_local, "wb") as f:
                f.write(foto_binaria)

            return str(ruta_local)
        except Exception:
            # Si falla el caché, no bloquea — se sigue usando base64 en memoria
            return None
