"""
Parseo de captura teclado (pistola barras / QR / PDF417 cédula CO).

Alineado con ``backend/services/porteria/parse_captura_service.php``:
PDF417 (@ + largo) → barras (3); QR largo/URL/separadores → 2;
solo dígitos → barras (3).
"""
from __future__ import annotations

import re
from dataclasses import dataclass

PDF417_MIN_LEN = 40
METODO_QR = 2
METODO_BARRAS = 3


@dataclass(frozen=True)
class CapturaEscaneo:
    documento: str
    nombres: str
    apellidos: str
    tipo_doc: str
    metodo_aut: int
    captura_raw: str
    origen: str


def parse_captura_escaneo(raw: str) -> CapturaEscaneo:
    """Extrae documento (+ nombres si PDF417) y clasifica metodo_aut 2|3."""
    trimmed = (raw or "").strip()
    if not trimmed:
        return CapturaEscaneo("", "", "", "CC", METODO_BARRAS, "", "vacio")

    if "@" in trimmed and len(trimmed) >= PDF417_MIN_LEN:
        return _parse_pdf417(trimmed)

    if _parece_qr(trimmed):
        doc = _solo_digitos_doc(trimmed)
        return CapturaEscaneo(
            documento=doc,
            nombres="",
            apellidos="",
            tipo_doc="CC",
            metodo_aut=METODO_QR,
            captura_raw=trimmed,
            origen="qr",
        )

    doc = _solo_digitos_doc(trimmed)
    return CapturaEscaneo(
        documento=doc,
        nombres="",
        apellidos="",
        tipo_doc="CC",
        metodo_aut=METODO_BARRAS,
        captura_raw=trimmed,
        origen="barras",
    )


def _parece_qr(raw: str) -> bool:
    lower = raw.casefold()
    if "http://" in lower or "https://" in lower:
        return True
    if "|" in raw or ";" in raw:
        return True
    # Payload largo sin ser PDF417 → suele ser QR de ficha/carnet.
    if len(raw) > 30 and "@" not in raw:
        return True
    return False


def _solo_digitos_doc(raw: str) -> str:
    digits = re.sub(r"\D", "", raw)
    return digits[:10]


def _parse_pdf417(raw: str) -> CapturaEscaneo:
    parts = [p.strip() for p in raw.split("@")]
    documento = ""
    for part in parts:
        digits = re.sub(r"\D", "", part)
        if 6 <= len(digits) <= 10:
            documento = digits
            break
    if not documento and parts:
        documento = re.sub(r"\D", "", parts[0])[:10]

    apellidos = _join_name(parts[1] if len(parts) > 1 else "",
                           parts[2] if len(parts) > 2 else "")
    nombres = _join_name(parts[3] if len(parts) > 3 else "",
                         parts[4] if len(parts) > 4 else "")

    return CapturaEscaneo(
        documento=documento,
        nombres=nombres,
        apellidos=apellidos,
        tipo_doc="CC",
        metodo_aut=METODO_BARRAS,
        captura_raw=raw,
        origen="pdf417",
    )


def _join_name(*segments: str) -> str:
    out: list[str] = []
    for s in segments:
        s = (s or "").strip()
        if not s or re.fullmatch(r"\d+", s):
            continue
        out.append(s)
    return " ".join(out).strip()
