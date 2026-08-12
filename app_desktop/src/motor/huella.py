"""
Captura de plantilla de huella.

Sin SDK de lector físico en esta fase: `capturar_template_prueba`
genera un BYTEA determinístico (SHA-256 del documento) para pruebas
end-to-end. Cuando se integre el vendor (DigitalPersona, etc.),
reemplazar `capturar_desde_lector` sin cambiar el contrato de
`template_a_base64` / endpoints PHP.
"""
from __future__ import annotations

import base64
import hashlib


def capturar_template_prueba(documento: str) -> bytes:
    """Plantilla sintética reproducible por documento (mín. 32 bytes)."""
    doc = (documento or "").strip()
    if not doc:
        raise ValueError("Indique un número de documento para simular la huella.")
    digest = hashlib.sha256(f"smartcset-huella-v1:{doc}".encode("utf-8")).digest()
    # Duplicar a 64 bytes (margen que el mínimo del backend).
    return digest + digest


def capturar_desde_lector() -> bytes:
    """Hook SDK real — aún no implementado."""
    raise NotImplementedError(
        "Lector de huella no configurado. Use la captura de prueba "
        "(documento + Simular huella) o integre el SDK del fabricante."
    )


def template_a_base64(template: bytes) -> str:
    if len(template) < 16:
        raise ValueError("Plantilla de huella demasiado corta.")
    return base64.b64encode(template).decode("ascii")
