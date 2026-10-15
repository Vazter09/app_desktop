"""
Validación de campos del formulario de ingreso (manual + pistola).

Documento: solo dígitos, 8–10.
Nombres/apellidos: solo letras (tildes, ñ, espacios, guion, apóstrofe).
Observación: alfanumérico + puntuación básica (fichas, placas, etc.).
"""
from __future__ import annotations

import re

DOC_MIN_LEN = 8
DOC_MAX_LEN = 10

# Sexo / RH del PDF417 — no deben pegarse en nombres ni confundirse con doc.
_RE_RH = re.compile(r"^(?:RH\s*)?[ABO]\s*[+-]?$", re.IGNORECASE)
_RE_SEXO = re.compile(r"^[MF]$", re.IGNORECASE)

_RE_NOMBRE_OK = re.compile(
    r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:[ '\-][A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*$"
)
_RE_NOMBRE_CHAR = re.compile(r"[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ '\-]")
_RE_OBS_CHAR = re.compile(
    r"[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9\s.,;:¡!¿?\-_\'\"#@/()°]"
)
# Serial de equipo: alfanumérico + guion/underscore (máx. 50 en BD).
EQUIPO_SERIAL_MAX_LEN = 50
_RE_EQUIPO_CHAR = re.compile(r"[^A-Za-z0-9\-_]")


def sanear_documento(raw: str) -> str:
    """Solo dígitos, máximo DOC_MAX_LEN (sin imponer mínimo)."""
    digits = re.sub(r"\D", "", raw or "")
    return digits[:DOC_MAX_LEN]


def es_documento_valido(raw: str) -> bool:
    digits = sanear_documento(raw)
    return DOC_MIN_LEN <= len(digits) <= DOC_MAX_LEN


def es_token_basura_pdf417(token: str) -> bool:
    """True si el segmento es sexo, RH (O+/A-…) o solo dígitos."""
    s = (token or "").strip()
    if not s:
        return True
    if re.fullmatch(r"\d+", s):
        return True
    if _RE_SEXO.fullmatch(s) or _RE_RH.fullmatch(s):
        return True
    return False


def filtrar_chars_nombre(raw: str) -> str:
    """Filtro en vivo: solo quita chars ilegales; conserva espacios al teclear."""
    return _RE_NOMBRE_CHAR.sub("", raw or "")


def sanear_nombre(raw: str) -> str:
    """Quita basura PDF417 (RH O+, sexo) y caracteres no permitidos."""
    parts: list[str] = []
    for token in re.split(r"\s+", (raw or "").strip()):
        if not token or es_token_basura_pdf417(token):
            continue
        cleaned = _RE_NOMBRE_CHAR.sub("", token).strip(" '-")
        if cleaned and not es_token_basura_pdf417(cleaned):
            parts.append(cleaned)
    return " ".join(parts).strip()


def es_nombre_valido(raw: str) -> bool:
    s = (raw or "").strip()
    if not s or len(s) > 80:
        return False
    return bool(_RE_NOMBRE_OK.fullmatch(s))


def filtrar_chars_observacion(raw: str) -> str:
    """Filtro en vivo: charset permitido sin strip (no corta al teclear)."""
    return _RE_OBS_CHAR.sub("", raw or "")


def sanear_observacion(raw: str) -> str:
    return filtrar_chars_observacion(raw).strip()


def es_observacion_valida(raw: str) -> bool:
    """Vacío permitido; si hay texto, solo charset permitido y ≤200."""
    s = (raw or "").strip()
    if not s:
        return True
    if len(s) > 200:
        return False
    return _RE_OBS_CHAR.search(s) is None


def mensaje_documento_invalido() -> str:
    return (
        f"Documento inválido: solo dígitos, "
        f"entre {DOC_MIN_LEN} y {DOC_MAX_LEN}."
    )


def mensaje_nombre_invalido(campo: str = "Nombres") -> str:
    return f"{campo}: solo letras (sin números ni símbolos)."


def filtrar_chars_equipo_serial(raw: str) -> str:
    """Filtro en vivo: serial alfanumérico, máx. EQUIPO_SERIAL_MAX_LEN."""
    cleaned = _RE_EQUIPO_CHAR.sub("", raw or "")
    return cleaned[:EQUIPO_SERIAL_MAX_LEN].upper()


def sanear_equipo_serial(raw: str) -> str:
    return filtrar_chars_equipo_serial(raw).strip()


EQUIPO_PLACEHOLDER = "111111"


def serial_equipo_efectivo(raw: object) -> str:
    """Serial usable: vacío si falta o es el placeholder 111111."""
    s = sanear_equipo_serial(str(raw or ""))
    if not s or s == EQUIPO_PLACEHOLDER:
        return ""
    if "," in s:
        return serial_equipo_efectivo(s.split(",", 1)[0])
    return s


def serial_equipo_desde_payload(data: dict | None) -> str:
    """Serial desde persona, lista equipos o consultar."""
    if not isinstance(data, dict):
        return ""
    serial = serial_equipo_efectivo(data.get("id_equipo"))
    if serial:
        return serial
    equipos = data.get("equipos")
    if isinstance(equipos, list):
        for row in equipos:
            if isinstance(row, dict):
                serial = serial_equipo_efectivo(row.get("id_equipo"))
            else:
                serial = serial_equipo_efectivo(row)
            if serial:
                return serial
    persona = data.get("persona")
    if isinstance(persona, dict):
        return serial_equipo_desde_payload(persona)
    return ""


def es_equipo_serial_valido(raw: str) -> bool:
    """Vacío = sin equipo; si hay texto, 3–50 chars del charset permitido."""
    s = sanear_equipo_serial(raw)
    if not s:
        return True
    if s == EQUIPO_PLACEHOLDER:
        return False
    return 3 <= len(s) <= EQUIPO_SERIAL_MAX_LEN


def agregar_equipo_al_payload(payload: dict, serial: str) -> None:
    """Adjunta el equipo al payload de ingreso/salida (no hace nada si vacío)."""
    if not serial:
        return
    payload["id_equipo"] = serial
    payload["ind_equipo"] = True
    payload["descripcion_equipo"] = "Pendiente"
