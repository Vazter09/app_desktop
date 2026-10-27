"""
Parseo de captura teclado (pistola barras / QR / PDF417 cédula CO).

Alineado con ``backend/services/porteria/parse_captura_service.php``:
PDF417 (@ + largo) → barras (3); QR largo/URL/separadores → 2;
solo dígitos → barras (3).

Solo expone documento + nombres + apellidos. Omite sexo, RH, fecha, etc.
Documento válido: 8–10 dígitos (no fecha DDMMYYYY), salvo que la
trama completa sea solo el documento (carnet SENA, barras limpias).

QR: prioriza corrida NUIP; si no hay, fallback legacy (todos los dígitos
del payload → primeros 10), que es lo que la pistola ya entregaba bien.
PDF417 (@): extractor estricto (no concatena basura / fechas).
PDF417 sin separadores (ancla ``PubDSK_``): solo el NUIP. Nombres
y apellidos quedan vacíos para que el operario los complete.

Cédula CO por estructura (2026-10-15): hay lectores/cédulas cuya trama
NO trae ``PubDSK_``. El NUIP es el campo de 10 dígitos rellenado con
ceros (p. ej. ``0012345678``) pegado al primer apellido en mayúsculas;
se reconoce por esa forma y se le quitan los ceros. Va ANTES de las
reglas de QR: el binario de la huella trae '|' / ';' y antes la
clasificaba como QR, tomando el número de tarjeta del inicio.

Cédula digital CO (2026-10-27): el lector, con OCR ID/pasaporte activo,
entrega el MRZ TD1 (``ICCOL…``, 3 líneas de 30 pegadas). Se toma solo el
NUIP de la línea 2 y se validan los dígitos de verificación. Va antes que
todo lo demás y solo reconoce esa firma: no cambia PDF417/carnet/barras.
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
# Trama que es solo el documento (carnet SENA, barras 1D limpias).
_RE_DOC_LIMPIO = re.compile(rf"\d{{{DOC_MIN_LEN},{DOC_MAX_LEN}}}")

# Cédula CO: campo NUIP (≥10 dígitos, relleno con ceros) pegado al primer
# apellido. El número de tarjeta del inicio va seguido de una sola letra
# ("…18B") y no coincide.
_RE_CEDULA_NUIP_APELLIDO = re.compile(
    rf"(\d{{{DOC_MAX_LEN},}})(?=[A-ZÁÉÍÓÚÑ]{{2}})"
)
# Campos de nombre de ancho fijo (relleno con espacios): firma de cédula.
_RE_CAMPOS_RELLENOS = re.compile(r"[A-ZÁÉÍÓÚÑ]{2,} {2,}[A-ZÁÉÍÓÚÑ]{2,}")
# Trama larga con esa firma: si no hay NUIP, no inventar con otras reglas.
CEDULA_FIRMA_MIN_LEN = 100

# Cédula digital CO: MRZ TD1 (OCR del lector). Líneas 1 y 2 = 60 chars;
# la línea 3 (nombres) puede venir cortada o no venir.
MRZ_TD1_MIN_LEN = 60
_RE_MRZ_CEDULA_CO = re.compile(r"I[A-Z<]COL[0-9A-Z<]{55}")


@dataclass(frozen=True)
class CapturaEscaneo:
    documento: str
    nombres: str
    apellidos: str
    tipo_doc: str
    metodo_aut: int
    captura_raw: str
    origen: str


def documento_desde_entrada_campo(raw: str) -> str:
    """Documento para coerce del Entry: trama PubDSK_/larga → NUIP real.

    Evita que ``sanear_documento`` se quede con los primeros 10 dígitos
    del prefijo anterior a ``PubDSK_`` cuando pegan o llega la trama entera.
    """
    trimmed = (raw or "").strip()
    if not trimmed:
        return ""
    if "PubDSK_" in trimmed or len(trimmed) > DOC_MAX_LEN:
        cap = parse_captura_escaneo(trimmed)
        if cap.documento:
            return cap.documento
    return sanear_documento(trimmed)


def parse_captura_escaneo(raw: str) -> CapturaEscaneo:
    """Extrae documento (+ nombres si PDF417) y clasifica metodo_aut 2|3.

    - Cédula digital MRZ (``ICCOL…``) → barras (3), solo NUIP
    - PDF417 (@ / Tab) → barras (3)
    - PDF417 ``PubDSK_`` sin separadores → barras (3), solo NUIP
      (antes del QR: basura binaria con ';' no debe robar el NUIP)
    - QR solo si URL o separadores | ; → QR (2)
    - Payload largo sin URL (cédula/PDF417 concatenado) → barras (3)
    - Solo dígitos → barras (3)
    """
    # Algunas pistolas envían Tab entre campos: normalizar a @ (dato, no UI).
    trimmed = (raw or "").replace("\t", "@").strip()
    if not trimmed:
        return CapturaEscaneo("", "", "", "CC", METODO_BARRAS, "", "vacio")

    # Cédula digital (MRZ por OCR del lector): firma propia, va primero y
    # devuelve None para cualquier otra trama, así no altera las reglas de
    # abajo (PDF417, carnet SENA, barras, QR).
    mrz = _captura_cedula_mrz(trimmed)
    if mrz is not None:
        return mrz

    # Cédula CO por estructura (con o sin PubDSK_): antes que '@' y QR.
    cedula = _captura_cedula_co(trimmed)
    if cedula is not None:
        return cedula

    # PDF417 estructurado: '@' (o Tab ya normalizado).
    if "@" in trimmed and (
        len(trimmed) >= PDF417_MIN_LEN or trimmed.count("@") >= 2
    ):
        return _parse_pdf417(trimmed)

    # Cédula CO (lector 2D): PubDSK_ + serie + NUIP + nombres pegados.
    # Antes del QR: la basura binaria del PDF417 a veces trae ';' y
    # clasificaba como QR, tomando el prefijo anterior a PubDSK_.
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

    if _parece_pdf417_concatenado(trimmed):
        return _parse_pdf417_concatenado(trimmed)

    # Carnet SENA / barras limpias: la trama ES el documento. Sin filtro
    # de fecha (es para la basura del PDF417): 10121990 es cédula válida.
    if _RE_DOC_LIMPIO.fullmatch(trimmed):
        return CapturaEscaneo(
            documento=trimmed,
            nombres="",
            apellidos="",
            tipo_doc="CC",
            metodo_aut=METODO_BARRAS,
            captura_raw=trimmed,
            origen="barras",
        )

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


def _mrz_digito_control(campo: str) -> int:
    """Dígito de verificación ICAO 9303 (pesos 7-3-1; '<'=0, A=10…Z=35)."""
    pesos = (7, 3, 1)
    total = 0
    for i, ch in enumerate(campo):
        if ch.isdigit():
            valor = int(ch)
        elif "A" <= ch <= "Z":
            valor = ord(ch) - 55
        else:
            valor = 0
        total += valor * pesos[i % 3]
    return total % 10


def _mrz_campo_ok(campo: str, digito: str) -> bool:
    return digito.isdigit() and _mrz_digito_control(campo) == int(digito)


def _captura_cedula_mrz(raw: str) -> CapturaEscaneo | None:
    """Cédula digital CO: MRZ TD1 leído por OCR → solo el NUIP.

    El lector entrega las 3 líneas de 30 caracteres pegadas
    (``ICCOL…``). El NUIP no es el "número de documento" de la línea 1
    (serie de la tarjeta) sino el campo opcional de la línea 2,
    posiciones 19–29: ``…COL1234567890<6…`` → ``1234567890``.

    ``None`` si la trama no es MRZ (no afecta las demás reglas). Si es
    MRZ pero falla un dígito de verificación (OCR mal leído) devuelve
    documento vacío: mejor pedir otro escaneo que registrar un número
    equivocado. La línea 3 (nombres) se ignora.
    """
    if len(raw) < MRZ_TD1_MIN_LEN or not _RE_MRZ_CEDULA_CO.match(raw):
        return None

    linea1 = raw[:30]
    linea2 = raw[30:60]
    nuip = linea2[18:29].replace("<", "")
    valido = (
        _mrz_campo_ok(linea2[0:6], linea2[6])
        and _mrz_campo_ok(linea2[8:14], linea2[14])
        and _mrz_campo_ok(
            linea1[5:30] + linea2[0:7] + linea2[8:15] + linea2[18:29],
            linea2[29],
        )
        and nuip.isdigit()
        and DOC_MIN_LEN <= len(nuip) <= DOC_MAX_LEN
    )
    return CapturaEscaneo(
        documento=nuip if valido else "",
        nombres="",
        apellidos="",
        tipo_doc="CC",
        metodo_aut=METODO_BARRAS,
        captura_raw=raw,
        origen="mrz",
    )


def _es_url(raw: str) -> bool:
    lower = raw.casefold()
    return "http://" in lower or "https://" in lower


def _nuip_desde_campo(digits: str) -> str:
    """Últimos 10 dígitos del campo, sin ceros de relleno; '' si inválido.

    La posición (pegado al apellido / tras PubDSK_) ya garantiza que es
    el campo documento: no se aplica el filtro de "parece fecha", que
    rechazaría cédulas reales de 8 dígitos como 10121990.
    """
    nuip = digits[-DOC_MAX_LEN:].lstrip("0")
    if DOC_MIN_LEN <= len(nuip) <= DOC_MAX_LEN:
        return nuip
    return ""


def _captura_cedula_co(raw: str) -> CapturaEscaneo | None:
    """Cédula CO por estructura; None si la trama no tiene esa forma."""
    if _es_url(raw):
        return None
    match = _RE_CEDULA_NUIP_APELLIDO.search(raw)
    if match is not None:
        documento = _nuip_desde_campo(match.group(1))
    elif len(raw) >= CEDULA_FIRMA_MIN_LEN and _RE_CAMPOS_RELLENOS.search(raw):
        # Parece cédula pero sin NUIP legible: "reintente", nunca el
        # número de tarjeta u otra corrida de dígitos.
        documento = ""
    else:
        return None
    return CapturaEscaneo(
        documento=documento,
        nombres="",
        apellidos="",
        tipo_doc="CC",
        metodo_aut=METODO_BARRAS,
        captura_raw=raw,
        origen="pdf417",
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


def trama_pubdsk_lista(raw: str) -> bool:
    """True si PubDSK_ ya tiene dígitos seguidos de letras (NUIP delimitado)."""
    return bool(raw) and _RE_PUBDSK_DIGITOS.search(raw) is not None


def trama_pubdsk_incompleta(raw: str) -> bool:
    """PubDSK_ empezó pero aún no hay letras: no parsear (evitar serie)."""
    return "PubDSK_" in (raw or "") and not trama_pubdsk_lista(raw)


def _documento_desde_pubdsk(raw: str) -> str | None:
    """NUIP de trama ``PubDSK_`` sin separadores.

    None si no hay ancla. Si la hay, los últimos 10 dígitos
    inmediatamente anteriores al bloque de letras, sin ceros de
    relleno. Ignora el prefijo anterior a ``PubDSK_``.
    """
    if "PubDSK_" not in raw:
        return None
    match = _RE_PUBDSK_DIGITOS.search(raw)
    if not match:
        return ""
    # Sin ceros de relleno: cédulas de 8–9 dígitos fallaban en la BD.
    return _nuip_desde_campo(match.group(1))


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
