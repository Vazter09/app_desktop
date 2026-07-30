"""
Formato de fechas — réplica exacta de `smartcsetFormatDbTimestamp()`
(`backend/core/helpers.php`): los timestamps que devuelven los endpoints
JSON vienen en la zona de la conexión de BD (`DB_TIMEZONE=UTC`, ver
`.env`), sin convertir — igual que la web, que NUNCA muestra la hora
cruda de BD, siempre la convierte a `APP_TIMEZONE` (America/Bogota)
antes de mostrarla.

Usa `zoneinfo` (librería estándar desde Python 3.9, cero dependencias de
terceros — ver REGLAS_APP_ESCRITORIO_SGI.md, sección 4).
"""
from __future__ import annotations

from datetime import datetime
from zoneinfo import ZoneInfo

DB_TIMEZONE = ZoneInfo("UTC")
APP_TIMEZONE = ZoneInfo("America/Bogota")

# Mismo formato por defecto que smartcsetFormatDbTimestamp() en PHP.
DEFAULT_FORMAT = "%d/%m/%Y %H:%M"

# Con segundos — para listados de ingreso/salida, donde dos eventos
# pueden caer en el mismo minuto (típico al probar identificación
# facial en sucesión rápida) y sin segundos se ven idénticos aunque el
# dato real en BD sí sea distinto.
WITH_SECONDS_FORMAT = "%d/%m/%Y %H:%M:%S"

_INPUT_FORMATS = (
    "%Y-%m-%d %H:%M:%S.%f",
    "%Y-%m-%d %H:%M:%S",
    "%Y-%m-%dT%H:%M:%S.%f",
    "%Y-%m-%dT%H:%M:%S",
)


# Catálogo alineado con registro web (aprendiz.php) + schema V.1.10.1.
ESTADO_FORMACION_LABELS: dict[int, str] = {
    1: "En formación",
    2: "Aplazado",
    3: "Retiro voluntario",
    4: "Cancelado",
    5: "Condicionado",
    6: "Suspendido",
    7: "Desertado",
    8: "Trasladado",
    9: "Sin información",
}

# tab_instructores.ind_estado (schema V.1.10.1).
ESTADO_INSTRUCTOR_LABELS: dict[int, str] = {
    0: "Activo",
    2: "Suspendido",
    3: "Bloqueado",
    9: "Inactivo",
}

TIPO_PERSONA_INSTRUCTOR = 3


def label_estado_formacion(codigo: int | str | None) -> str:
    """Traduce ind_etdo_formacion / estado_formacion a texto legible."""
    if codigo is None or codigo == "":
        return "—"
    try:
        key = int(codigo)
    except (TypeError, ValueError):
        return "—"
    return ESTADO_FORMACION_LABELS.get(key, "—")


def label_estado_instructor(codigo: int | str | None) -> str:
    """Traduce tab_instructores.ind_estado a texto legible."""
    if codigo is None or codigo == "":
        return "—"
    try:
        key = int(codigo)
    except (TypeError, ValueError):
        return "—"
    return ESTADO_INSTRUCTOR_LABELS.get(key, "—")


def label_tipo_contrato_instructor(valor: bool | str | int | None) -> str:
    """TRUE=Planta / FALSE=Contratista (tab_instructores.ind_tipo_contrato)."""
    if valor is None or valor == "":
        return "—"
    if isinstance(valor, bool):
        return "Planta" if valor else "Contratista"
    s = str(valor).strip().lower()
    if s in ("t", "true", "1", "yes"):
        return "Planta"
    if s in ("f", "false", "0", "no"):
        return "Contratista"
    return "—"


def es_tipo_instructor(tipo_persona: int | str | None) -> bool:
    try:
        return int(tipo_persona or 0) == TIPO_PERSONA_INSTRUCTOR
    except (TypeError, ValueError):
        return False


def format_db_timestamp(value: str | None, fmt: str = DEFAULT_FORMAT) -> str:
    """Convierte un timestamp crudo de BD (UTC, sin zona) a hora local
    legible — mismo comportamiento que `smartcsetFormatDbTimestamp()`."""
    raw = (value or "").strip()
    if not raw:
        return "—"

    parsed: datetime | None = None
    for input_fmt in _INPUT_FORMATS:
        try:
            parsed = datetime.strptime(raw, input_fmt)
            break
        except ValueError:
            continue

    if parsed is None:
        return "—"

    parsed = parsed.replace(tzinfo=DB_TIMEZONE)
    return parsed.astimezone(APP_TIMEZONE).strftime(fmt)
