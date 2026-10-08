"""
Parseo de captura teclado (pistola barras / QR / PDF417 cédula CO).

Alineado con ``backend/services/porteria/parse_captura_service.php``:
PDF417 (@ + largo) → barras (3); QR largo/URL/separadores → 2;
solo dígitos → barras (3).

Solo expone documento + nombres + apellidos. Omite sexo, RH, fecha, etc.
Documento válido: 8–10 dígitos (no fecha DDMMYYYY).

QR: prioriza corrida NUIP; si no hay, fallback legacy (todos los dígitos
del payload → primeros 10), que es lo que la pistola ya entregaba bien.
PDF417 (@): extractor estricto (no concatena basura / fechas).
PDF417 sin separadores (ancla ``PubDSK_``): solo el NUIP. Nombres
y apellidos quedan vacíos para que el operario los complete.
"""
from __future__ import annotations

import re
from dataclasses import dataclass

from ui.field_validators import (
    DOC_MAX_LEN,
    DOC_MIN_LEN,
    es_token_basura_pdf417,
    sanear_documento,
    sanear_nombre,
)

PDF417_MIN_LEN = 40
METODO_QR = 2
METODO_BARRAS = 3

# Corridas de dígitos (NUIP / fecha) en payloads concatenados.
_RE_DIGIT_RUN = re.compile(rf"\d{{{DOC_MIN_LEN},{DOC_MAX_LEN}}}")


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
    """Extrae documento (+ nombres si PDF417) y clasifica metodo_aut 2|3.

    - PDF417 (@ / Tab) → barras (3)
    - QR solo si URL o separadores | ; → QR (2)
    - PDF417 ``PubDSK_`` sin separadores → barras (3), solo NUIP
    - Payload largo sin URL (cédula/PDF417 concatenado) → barras (3)
    - Solo dígitos → barras (3)
    """
    # Algunas pistolas envían Tab entre campos: normalizar a @ (dato, no UI).
    trimmed = (raw or "").replace("\t", "@").strip()
    if not trimmed:
        return CapturaEscaneo("", "", "", "CC", METODO_BARRAS, "", "vacio")

    # PDF417 estructurado: '@' (o Tab ya normalizado).
    if "@" in trimmed and (
        len(trimmed) >= PDF417_MIN_LEN or trimmed.count("@") >= 2
    ):
        return _parse_pdf417(trimmed)

    # QR explícito (URL / separadores). NO usar “largo sin @” → eso
    # marcaba PDF417/cédula de pistola como metodo_aut=2 por error.
    if _parece_qr(trimmed):
        return CapturaEscaneo(
            documento=_documento_desde_qr(trimmed),
            nombres="",
            apellidos="",
            tipo_doc="CC",
            metodo_aut=METODO_QR,
            captura_raw=trimmed,
            origen="qr",
        )

    # Cédula CO (lector 2D): PubDSK_ + serie + NUIP + nombres pegados.
    # El lector no inserta separadores entre campos.
    pubdsk = _documento_desde_pubdsk(trimmed)
    if pubdsk is not None:
        return CapturaEscaneo(
            documento=pubdsk,
            nombres="",
            apellidos="",
            tipo_doc="CC",
            metodo_aut=METODO_BARRAS,
            captura_raw=trimmed,
            origen="pdf417",
        )

    if _parece_pdf417_concatenado(trimmed):
        return _parse_pdf417_concatenado(trimmed)

    # Barras 1D / payload de pistola sin firma QR.
    doc = _mejor_documento_digitos(trimmed, permitir_fallback_pegado=True)
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
    """Solo firmas claras de QR — no payloads largos de cédula/PDF417."""
    lower = raw.casefold()
    if "http://" in lower or "https://" in lower:
        return True
    if "|" in raw or ";" in raw:
        return True
    return False


def _parece_pdf417_concatenado(raw: str) -> bool:
    """PDF417 sin '@': letras + corrida de dígitos (no URLs QR)."""
    if len(raw) < 25 or "@" in raw:
        return False
    # No clasificar URLs / separadores típicos de QR.
    lower = raw.casefold()
    if "http://" in lower or "https://" in lower or "|" in raw or ";" in raw:
        return False
    if not re.search(r"[A-Za-zÁÉÍÓÚÑáéíóúñ]{3,}", raw):
        return False
    return bool(_RE_DIGIT_RUN.search(raw))


# Dígitos de PubDSK_ hasta la primera letra (serie + NUIP pegados).
_RE_PUBDSK_DIGITOS = re.compile(
    r"PubDSK_(\d+)(?=[A-Za-zÁÉÍÓÚÑáéíóúñ])"
)


def _parece_fecha_yyyymmdd(digits: str) -> bool:
    """Evita tomar AAAAMMDD (fecha de la cédula) como documento."""
    if len(digits) != 8 or not digits.isdigit():
        return False
    anio = int(digits[0:4])
    mes = int(digits[4:6])
    dia = int(digits[6:8])
    return 1900 <= anio <= 2100 and 1 <= mes <= 12 and 1 <= dia <= 31


def _documento_desde_pubdsk(raw: str) -> str | None:
    """NUIP de trama ``PubDSK_`` sin separadores.

    None si no hay ancla. Si la hay, los últimos 8–10 dígitos
    inmediatamente anteriores al bloque de letras. Ignora el
    prefijo anterior a ``PubDSK_`` y la fecha AAAAMMDD.
    """
    if "PubDSK_" not in raw:
        return None
    match = _RE_PUBDSK_DIGITOS.search(raw)
    if not match:
        return ""
    digits = match.group(1)
    if len(digits) > DOC_MAX_LEN:
        candidato = digits[-DOC_MAX_LEN:]
    elif len(digits) >= DOC_MIN_LEN:
        candidato = digits
    else:
        return ""
    if (
        _parece_fecha_ddmmyyyy(candidato)
        or _parece_fecha_yyyymmdd(candidato)
    ):
        return ""
    return candidato


def _parece_fecha_ddmmyyyy(digits: str) -> bool:
    """Evita tomar fecha de nacimiento (8 dígitos) como cédula."""
    if len(digits) != 8 or not digits.isdigit():
        return False
    dia = int(digits[0:2])
    mes = int(digits[2:4])
    anio = int(digits[4:8])
    return 1 <= dia <= 31 and 1 <= mes <= 12 and 1900 <= anio <= 2100


def _solo_digitos_doc(raw: str) -> str:
    """Legacy pistola QR: todos los dígitos del payload, máx. 10."""
    return re.sub(r"\D", "", raw or "")[:DOC_MAX_LEN]


def _documento_valido_nuip(digits: str) -> str:
    """Acepta solo NUIP 8–10 que no parezca fecha DDMMYYYY."""
    if not digits:
        return ""
    if not (DOC_MIN_LEN <= len(digits) <= DOC_MAX_LEN):
        return ""
    if _parece_fecha_ddmmyyyy(digits):
        return ""
    return digits


def _documento_desde_qr(raw: str) -> str:
    """Documento desde QR: corrida clara, si no fallback legacy.

    El fallback (concatenar dígitos del URL/payload) es lo que la pistola
    ya hacía bien; no se usa en PDF417 con '@' para no mezclar fecha+NUIP.
    """
    doc = _mejor_documento_digitos(raw, permitir_fallback_pegado=False)
    if doc:
        return doc
    return _documento_valido_nuip(_solo_digitos_doc(raw))


def _mejor_documento_digitos(
    raw: str, *, permitir_fallback_pegado: bool = False
) -> str:
    """Elige el mejor NUIP: 8–10 dígitos, no fecha; prefiere el más largo.

    Sin candidatos claros no pega prefijo+fecha (p. ej. 27+06041998 →
    2706041998). El fallback de dígitos pegados solo aplica a barras
    numéricas (pocas letras), no a PDF417 estructurado.
    """
    candidatos: list[str] = []
    for m in _RE_DIGIT_RUN.finditer(raw or ""):
        digits = m.group(0)
        valid = _documento_valido_nuip(digits[:DOC_MAX_LEN])
        if valid:
            candidatos.append(valid)
    if candidatos:
        return max(candidatos, key=len)

    letters = len(re.findall(r"[A-Za-zÁÉÍÓÚÑáéíóúñ]", raw or ""))
    if letters >= 3 or not permitir_fallback_pegado:
        return ""

    return _documento_valido_nuip(sanear_documento(raw))


def _parse_pdf417(raw: str) -> CapturaEscaneo:
    """Convención: [0]=NUIP, [1]=ape1, [2]=ape2, [3]=nom1, [4]=nom2."""
    parts = [p.strip() for p in raw.split("@")]
    documento = _mejor_documento_digitos(raw, permitir_fallback_pegado=False)
    if not documento and parts:
        digits0 = sanear_documento(parts[0])
        documento = _documento_valido_nuip(digits0)

    apellidos = _join_name(
        parts[1] if len(parts) > 1 else "",
        parts[2] if len(parts) > 2 else "",
    )
    nombres = _join_name(
        parts[3] if len(parts) > 3 else "",
        parts[4] if len(parts) > 4 else "",
    )

    return CapturaEscaneo(
        documento=documento,
        nombres=nombres,
        apellidos=apellidos,
        tipo_doc="CC",
        metodo_aut=METODO_BARRAS,
        captura_raw=raw,
        origen="pdf417",
    )


def _parse_pdf417_concatenado(raw: str) -> CapturaEscaneo:
    """Misma extracción de documento; nombres no fiables sin separadores."""
    documento = _mejor_documento_digitos(raw, permitir_fallback_pegado=False)
    return CapturaEscaneo(
        documento=documento,
        nombres="",
        apellidos="",
        tipo_doc="CC",
        metodo_aut=METODO_BARRAS,
        captura_raw=raw,
        origen="pdf417",
    )


def _join_name(*segments: str) -> str:
    out: list[str] = []
    for s in segments:
        s = (s or "").strip()
        if not s or es_token_basura_pdf417(s):
            continue
        cleaned = sanear_nombre(s)
        if cleaned:
            out.append(cleaned)
    return " ".join(out).strip()
